import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:esc_pos_utils_updated/esc_pos_utils_updated.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_printer_service.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class BluetoothPrinterSettings extends StatelessWidget {
  const BluetoothPrinterSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BluetoothPrinterService()..init(),
      child: const _BluetoothPrinterContent(),
    );
  }
}

class _BluetoothPrinterContent extends StatelessWidget {
  const _BluetoothPrinterContent();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final btService = Provider.of<BluetoothPrinterService>(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bluetooth,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.tr('bluetooth_printer'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        settings.tr('connect_thermal_printer'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Connected Printer Status
          if (btService.connectedDeviceName != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (kIsWeb || btService.connectedDeviceId == null)
                      ? null
                      : () async {
                          final profile = await CapabilityProfile.load();
                          final generator = Generator(PaperSize.mm58, profile);
                          final bytes = <int>[];

                          bytes.addAll(
                            generator.text(
                              'POS System',
                              styles: PosStyles(
                                align: PosAlign.center,
                                bold: true,
                                height: PosTextSize.size2,
                                width: PosTextSize.size2,
                              ),
                            ),
                          );
                          bytes.addAll(
                            generator.text(
                              'TEST PRINT',
                              styles: PosStyles(
                                align: PosAlign.center,
                                bold: true,
                              ),
                            ),
                          );
                          bytes.addAll(generator.hr());
                          bytes.addAll(
                            generator.text(
                              DateTime.now().toString(),
                              styles: PosStyles(align: PosAlign.center),
                            ),
                          );
                          bytes.addAll(generator.feed(2));
                          bytes.addAll(generator.cut());

                          final ok = await btService.printReceipt(bytes);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? settings.tr('success')
                                    : (btService.errorMessage ??
                                        settings.tr('error')),
                              ),
                              backgroundColor:
                                  ok ? AppColors.success : AppColors.error,
                            ),
                          );
                        },
                  icon: const Icon(Icons.receipt_long),
                  label: Text(settings.tr('print_receipt')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.print,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              title: Text(
                btService.connectedDeviceName!,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                settings.tr('connected'),
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                ),
              ),
              trailing: TextButton.icon(
                onPressed: () => btService.disconnect(
                  clearSavedPrinter: auth.isAdmin,
                ),
                icon: const Icon(Icons.link_off, size: 18),
                label: Text(settings.tr('disconnect')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ),
            const Divider(height: 1),
          ],

          // Web Platform Warning
          if (kIsWeb) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        settings.tr('bluetooth_not_supported_web'),
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Scan Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: btService.isScanning
                      ? () => btService.stopScan()
                      : () => btService.startScan(),
                  icon: btService.isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    btService.isScanning
                        ? settings.tr('scanning')
                        : settings.tr('scan_devices'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Error Message
            if (btService.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          btService.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Available Devices List
            if (btService.availableDevices.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  settings.tr('available_devices'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: btService.availableDevices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final device = btService.availableDevices[index];
                  final isCurrentDevice =
                      device.id == btService.connectedDeviceId;

                  return ListTile(
                    leading: Icon(
                      Icons.print,
                      color: isCurrentDevice
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    title: Text(device.name),
                    subtitle: Text(
                      device.id,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: isCurrentDevice
                        ? Chip(
                            label: Text(
                              settings.tr('connected'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                              ),
                            ),
                            backgroundColor: AppColors.success.withAlpha(25),
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                          )
                        : btService.isConnecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : TextButton(
                                onPressed: () =>
                                    btService.connectToDevice(
                                  device,
                                  persist: auth.isAdmin,
                                ),
                                child: Text(settings.tr('connect')),
                              ),
                  );
                },
              ),
            ],

            // Empty State
            if (!btService.isScanning && btService.availableDevices.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bluetooth_searching,
                        size: 48,
                        color: AppColors.textHint.withAlpha(100),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        settings.tr('no_devices_found'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.tr('tap_scan_to_search'),
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
