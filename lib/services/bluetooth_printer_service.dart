import 'dart:async';
import 'package:esc_pos_bluetooth_updated/esc_pos_bluetooth_updated.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothDevice {
  final String id;
  final String name;
  final bool isConnected;

  BluetoothDevice({
    required this.id,
    required this.name,
    this.isConnected = false,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory BluetoothDevice.fromJson(Map<String, dynamic> json) {
    return BluetoothDevice(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Device',
    );
  }
}

class BluetoothPrinterService with ChangeNotifier {
  static const String _savedPrinterKey = 'saved_bluetooth_printer';
  static const String _savedPrinterNameKey = 'saved_bluetooth_printer_name';

  final PrinterBluetoothManager _printerManager = PrinterBluetoothManager();
  final Map<String, PrinterBluetooth> _discoveredPrintersById = {};
  PrinterBluetooth? _selectedPrinter;

  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _savedPrinterId;
  String? _savedPrinterName;
  String? _connectedDeviceId;
  String? _connectedDeviceName;
  List<BluetoothDevice> _availableDevices = [];
  String? _errorMessage;
  StreamSubscription<List<PrinterBluetooth>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String? get savedPrinterId => _savedPrinterId;
  String? get savedPrinterName => _savedPrinterName;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get connectedDeviceName => _connectedDeviceName;
  List<BluetoothDevice> get availableDevices => _availableDevices;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _savedPrinterId = prefs.getString(_savedPrinterKey);
    _savedPrinterName = prefs.getString(_savedPrinterNameKey);
    _connectedDeviceId = _savedPrinterId;
    _connectedDeviceName = _savedPrinterName;
    _isConnected = _connectedDeviceId != null;

    _scanResultsSubscription ??= _printerManager.scanResults.listen((printers) {
      final uniqueDevices = <String, BluetoothDevice>{};

      for (final printer in printers) {
        final id = printer.address;
        if (id == null || id.isEmpty) continue;

        final rawName = printer.name;
        final name = (rawName != null && rawName.isNotEmpty)
            ? rawName
            : 'Unknown Device';

        _discoveredPrintersById[id] = printer;
        uniqueDevices[id] = BluetoothDevice(
          id: id,
          name: name,
          isConnected: id == _connectedDeviceId,
        );
      }

      _availableDevices = uniqueDevices.values.toList();
      notifyListeners();
    });

    _isScanningSubscription ??=
        _printerManager.isScanningStream.listen((isScanning) {
      _isScanning = isScanning;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<bool> _ensureBluetoothPermissions() async {
    if (kIsWeb) {
      return false;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final statuses = await <Permission>[
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();

        final locationGranted = statuses[Permission.location]?.isGranted ??
            (await Permission.location.isGranted);
        final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ??
            (await Permission.bluetoothScan.isGranted);
        final connectGranted =
            statuses[Permission.bluetoothConnect]?.isGranted ??
                (await Permission.bluetoothConnect.isGranted);

        final modernBtGranted = scanGranted && connectGranted;
        final granted = modernBtGranted || locationGranted;

        if (!granted) {
          _errorMessage = 'Bluetooth permission is required';
          notifyListeners();
        }

        return granted;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final status = await Permission.bluetooth.request();
        if (!status.isGranted) {
          _errorMessage = 'Bluetooth permission is required';
          notifyListeners();
          return false;
        }
        return true;
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error requesting permissions: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkBluetoothAvailability() async {
    if (kIsWeb) {
      _errorMessage = 'Bluetooth not supported on web';
      notifyListeners();
      return false;
    }

    try {
      final granted = await _ensureBluetoothPermissions();
      if (!granted) return false;

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error checking Bluetooth: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    final isAvailable = await checkBluetoothAvailability();
    if (!isAvailable) return;

    _availableDevices = [];
    _discoveredPrintersById.clear();
    _errorMessage = null;
    _isScanning = true;
    notifyListeners();

    try {
      _printerManager.startScan(const Duration(seconds: 10));
    } catch (e) {
      _isScanning = false;
      _errorMessage = 'Scan failed: $e';
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    try {
      _printerManager.stopScan();
    } catch (_) {}
    _isScanning = false;
    notifyListeners();
  }


  Future<bool> connectToDevice(
    BluetoothDevice device, {
    bool persist = true,
  }) async {
    if (_isConnecting) return false;

    final isAvailable = await checkBluetoothAvailability();
    if (!isAvailable) return false;

    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final printer = _discoveredPrintersById[device.id];
      if (printer == null) {
        _errorMessage = 'Printer not found. Please scan again.';
        _isConnecting = false;
        notifyListeners();
        return false;
      }

      _printerManager.selectPrinter(printer);
      _selectedPrinter = printer;

      if (persist) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_savedPrinterKey, device.id);
        await prefs.setString(_savedPrinterNameKey, device.name);
        _savedPrinterId = device.id;
        _savedPrinterName = device.name;
      }

      _connectedDeviceId = device.id;
      _connectedDeviceName = device.name;
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Connection failed: $e';
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect({bool clearSavedPrinter = true}) async {
    if (clearSavedPrinter) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedPrinterKey);
      await prefs.remove(_savedPrinterNameKey);
      _savedPrinterId = null;
      _savedPrinterName = null;
    }

    _connectedDeviceId = _savedPrinterId;
    _connectedDeviceName = _savedPrinterName;
    _isConnected = _connectedDeviceId != null;
    _selectedPrinter = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<PrinterBluetooth?> _findPrinterById(String id) async {
    final cached = _discoveredPrintersById[id];
    if (cached != null) return cached;

    final completer = Completer<PrinterBluetooth?>();
    StreamSubscription<List<PrinterBluetooth>>? sub;

    sub = _printerManager.scanResults.listen((printers) {
      for (final printer in printers) {
        if (printer.address == id && !completer.isCompleted) {
          completer.complete(printer);
          break;
        }
      }
    });

    try {
      if (!_isScanning) {
        _printerManager.startScan(const Duration(seconds: 2));
      }
      final printer = await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      try {
        _printerManager.stopScan();
      } catch (_) {}
      return printer;
    } finally {
      await sub.cancel();
    }
  }

  Future<bool> printReceipt(List<int> bytes) async {
    if (_connectedDeviceId == null) {
      _errorMessage = 'No printer connected';
      notifyListeners();
      return false;
    }

    try {
      final isAvailable = await checkBluetoothAvailability();
      if (!isAvailable) return false;

      final printerId = _connectedDeviceId!;
      final selected = (_selectedPrinter != null &&
              _selectedPrinter!.address == printerId)
          ? _selectedPrinter
          : await _findPrinterById(printerId);

      if (selected == null) {
        _errorMessage = 'Printer not found. Please scan and connect again.';
        notifyListeners();
        return false;
      }

      _printerManager.selectPrinter(selected);
      _selectedPrinter = selected;

      final res = await _printerManager.printTicket(bytes);
      if (res == PosPrintResult.success) {
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      _errorMessage = res.msg;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Print failed: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    super.dispose();
  }
}
