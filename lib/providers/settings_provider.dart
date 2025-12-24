import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { indonesian, english }

enum AppCurrency { idr, usd, eur }

class SettingsProvider with ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _currencyKey = 'app_currency';
  static const String _taxRateKey = 'tax_rate';
  static const String _companyNameKey = 'company_name';
  static const String _companyAddressKey = 'company_address';
  static const String _companyPhoneKey = 'company_phone';
  static const String _companyLogoKey = 'company_logo';
  static const String _receiptHeaderKey = 'receipt_header';
  static const String _receiptFooterKey = 'receipt_footer';
  static const String _autoPrintKey = 'auto_print';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _autoBackupKey = 'auto_backup';
  static const String _midtransServerKeyKey = 'midtrans_server_key';
  static const String _isMidtransEnabledKey = 'midtrans_enabled';

  SharedPreferences? _prefs;

  // Default values
  AppLanguage _language = AppLanguage.indonesian;
  AppCurrency _currency = AppCurrency.idr;
  double _taxRate = 0.0;
  String _companyName = 'POS System';
  String _companyAddress = 'Jl. Contoh No. 123, Jakarta';
  String _companyPhone = '+62 812 3456 7890';
  String _companyLogo = '';
  String _receiptHeader = 'Terima Kasih Telah Berbelanja';
  String _receiptFooter = 'Barang yang sudah dibeli tidak dapat dikembalikan';
  bool _autoPrint = false;
  bool _notificationsEnabled = true;
  bool _autoBackup = true;
  String _midtransServerKey = '';
  bool _isMidtransEnabled = false;
  bool _isLoading = false;

  // Getters
  AppLanguage get language => _language;
  AppCurrency get currency => _currency;
  double get taxRate => _taxRate;
  String get companyName => _companyName;
  String get companyAddress => _companyAddress;
  String get companyPhone => _companyPhone;
  String get companyLogo => _companyLogo;
  String get receiptHeader => _receiptHeader;
  String get receiptFooter => _receiptFooter;
  bool get autoPrint => _autoPrint;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoBackup => _autoBackup;
  String get midtransServerKey => _midtransServerKey;
  bool get isMidtransEnabled => _isMidtransEnabled;
  bool get isLoading => _isLoading;

  bool get isIndonesian => _language == AppLanguage.indonesian;
  bool get isEnglish => _language == AppLanguage.english;

  String get currencySymbol {
    switch (_currency) {
      case AppCurrency.idr:
        return 'Rp';
      case AppCurrency.usd:
        return '\$';
      case AppCurrency.eur:
        return '€';
    }
  }

  String get currencyCode {
    switch (_currency) {
      case AppCurrency.idr:
        return 'IDR';
      case AppCurrency.usd:
        return 'USD';
      case AppCurrency.eur:
        return 'EUR';
    }
  }

  String get languageName {
    switch (_language) {
      case AppLanguage.indonesian:
        return 'Indonesia';
      case AppLanguage.english:
        return 'English';
    }
  }

  String get currencyDisplayName {
    switch (_currency) {
      case AppCurrency.idr:
        return 'IDR (Rp)';
      case AppCurrency.usd:
        return 'USD (\$)';
      case AppCurrency.eur:
        return 'EUR (€)';
    }
  }

  // Initialize settings from SharedPreferences
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _prefs = await SharedPreferences.getInstance();

    // Load saved settings
    final languageIndex = _prefs?.getInt(_languageKey) ?? 0;
    _language = AppLanguage.values[languageIndex];

    final currencyIndex = _prefs?.getInt(_currencyKey) ?? 0;
    _currency = AppCurrency.values[currencyIndex];

    _taxRate = _prefs?.getDouble(_taxRateKey) ?? 0.0;
    _companyName = _prefs?.getString(_companyNameKey) ?? 'POS System';
    _companyAddress =
        _prefs?.getString(_companyAddressKey) ?? 'Jl. Contoh No. 123, Jakarta';
    _companyPhone = _prefs?.getString(_companyPhoneKey) ?? '+62 812 3456 7890';
    _companyLogo = _prefs?.getString(_companyLogoKey) ?? '';
    _receiptHeader =
        _prefs?.getString(_receiptHeaderKey) ?? 'Terima Kasih Telah Berbelanja';
    _receiptFooter =
        _prefs?.getString(_receiptFooterKey) ??
        'Barang yang sudah dibeli tidak dapat dikembalikan';
    _autoPrint = _prefs?.getBool(_autoPrintKey) ?? false;
    _notificationsEnabled = _prefs?.getBool(_notificationsKey) ?? true;
    _autoBackup = _prefs?.getBool(_autoBackupKey) ?? true;
    _midtransServerKey = _prefs?.getString(_midtransServerKeyKey) ?? '';
    _isMidtransEnabled = _prefs?.getBool(_isMidtransEnabledKey) ?? false;

    _isLoading = false;
    notifyListeners();
  }

  // Setters with persistence
  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    await _prefs?.setInt(_languageKey, language.index);
    notifyListeners();
  }

  Future<void> setCurrency(AppCurrency currency) async {
    _currency = currency;
    await _prefs?.setInt(_currencyKey, currency.index);
    notifyListeners();
  }

  Future<void> setTaxRate(double rate) async {
    _taxRate = rate;
    await _prefs?.setDouble(_taxRateKey, rate);
    notifyListeners();
  }

  Future<void> setCompanyName(String name) async {
    _companyName = name;
    await _prefs?.setString(_companyNameKey, name);
    notifyListeners();
  }

  Future<void> setCompanyAddress(String address) async {
    _companyAddress = address;
    await _prefs?.setString(_companyAddressKey, address);
    notifyListeners();
  }

  Future<void> setCompanyPhone(String phone) async {
    _companyPhone = phone;
    await _prefs?.setString(_companyPhoneKey, phone);
    notifyListeners();
  }

  Future<void> setCompanyLogo(String logoPath) async {
    _companyLogo = logoPath;
    await _prefs?.setString(_companyLogoKey, logoPath);
    notifyListeners();
  }

  Future<void> setReceiptHeader(String header) async {
    _receiptHeader = header;
    await _prefs?.setString(_receiptHeaderKey, header);
    notifyListeners();
  }

  Future<void> setReceiptFooter(String footer) async {
    _receiptFooter = footer;
    await _prefs?.setString(_receiptFooterKey, footer);
    notifyListeners();
  }

  Future<void> setAutoPrint(bool value) async {
    _autoPrint = value;
    await _prefs?.setBool(_autoPrintKey, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs?.setBool(_notificationsKey, value);
    notifyListeners();
  }

  Future<void> setAutoBackup(bool value) async {
    _autoBackup = value;
    await _prefs?.setBool(_autoBackupKey, value);
    await _prefs?.setBool(_autoBackupKey, value);
    notifyListeners();
  }

  Future<void> setMidtransServerKey(String key) async {
    _midtransServerKey = key;
    await _prefs?.setString(_midtransServerKeyKey, key);
    notifyListeners();
  }

  Future<void> setMidtransEnabled(bool value) async {
    _isMidtransEnabled = value;
    await _prefs?.setBool(_isMidtransEnabledKey, value);
    notifyListeners();
  }

  // Format currency based on settings
  String formatCurrency(double amount) {
    switch (_currency) {
      case AppCurrency.idr:
        return 'Rp ${_formatNumber(amount, 0)}';
      case AppCurrency.usd:
        return '\$${_formatNumber(amount, 2)}';
      case AppCurrency.eur:
        return '€${_formatNumber(amount, 2)}';
    }
  }

  String _formatNumber(double number, int decimals) {
    if (decimals == 0) {
      return number.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
    }
    final parts = number.toStringAsFixed(decimals).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }

  // Localized strings
  String tr(String key) {
    final translations = _language == AppLanguage.indonesian
        ? _indonesianStrings
        : _englishStrings;
    return translations[key] ?? key;
  }

  static const Map<String, String> _indonesianStrings = {
    // General
    'app_name': 'Sistem POS',
    'save': 'Simpan',
    'cancel': 'Batal',
    'delete': 'Hapus',
    'edit': 'Edit',
    'add': 'Tambah',
    'search': 'Cari',
    'close': 'Tutup',
    'confirm': 'Konfirmasi',
    'success': 'Berhasil',
    'error': 'Error',
    'field_required': 'Bagian ini wajib diisi',
    'warning': 'Peringatan',
    'loading': 'Memuat...',
    'no_data': 'Tidak ada data',
    'yes': 'Ya',
    'no': 'Tidak',

    // Auth
    'login': 'Masuk',
    'logout': 'Keluar',
    'username': 'Nama Pengguna',
    'password': 'Kata Sandi',
    'remember_me': 'Ingat Saya',
    'forgot_password': 'Lupa Kata Sandi?',
    'sign_in': 'Masuk',
    'sign_in_to_continue': 'Silakan masuk untuk melanjutkan',
    'invalid_credentials': 'Nama pengguna atau kata sandi salah',
    'logout_confirm': 'Apakah Anda yakin ingin keluar?',
    'welcome_back': 'Selamat Datang Kembali',

    // Navigation
    'dashboard': 'Dasbor',
    'products': 'Produk',
    'sales': 'Penjualan',
    'reports': 'Laporan',
    'settings': 'Pengaturan',
    'cashier': 'Kasir',
    'menu': 'Menu',
    'history': 'Riwayat',
    'price': 'Harga',

    // Dashboard
    'total_revenue': 'Total Pendapatan',
    'total_products': 'Total Produk',
    'total_orders': 'Total Pesanan',
    'today_revenue': 'Pendapatan Hari Ini',
    'weekly_sales': 'Penjualan Mingguan',
    'recent_transactions': 'Transaksi Terbaru',
    'view_all': 'Lihat Semua',
    'all_time': 'Semua Waktu',
    'active_products': 'Produk Aktif',
    'completed_orders': 'Pesanan Selesai',

    // Products
    'add_product': 'Tambah Produk',
    'edit_product': 'Edit Produk',
    'delete_product': 'Hapus Produk',
    'product_name': 'Nama Produk',
    'category': 'Kategori',

    'stock': 'Stok',
    'description': 'Deskripsi',
    'image_url': 'URL Gambar',
    'active': 'Aktif',
    'inactive': 'Nonaktif',
    'out_of_stock': 'Stok Habis',
    'low_stock': 'Stok Rendah',
    'in_stock': 'Tersedia',
    'search_products': 'Cari produk...',
    'no_products': 'Tidak ada produk',
    'product_added': 'Produk berhasil ditambahkan',
    'product_updated': 'Produk berhasil diperbarui',
    'product_deleted': 'Produk berhasil dihapus',
    'confirm_delete_product': 'Apakah Anda yakin ingin menghapus produk ini?',
    'all_categories': 'Semua Kategori',

    // Orders
    'current_order': 'Pesanan Saat Ini',
    'order_number': 'No. Pesanan',
    'order_date': 'Tanggal Pesanan',
    'order_status': 'Status Pesanan',
    'order_items': 'Item Pesanan',
    'subtotal': 'Subtotal',
    'tax': 'Pajak',
    'discount': 'Diskon',
    'add_discount': 'Tambah Diskon',
    'discount_amount': 'Jumlah Diskon',
    'remove': 'Hapus',
    'total': 'Total',
    'checkout': 'Checkout',
    'clear': 'Hapus',
    'no_items': 'Tidak ada item',
    'add_items': 'Tap produk untuk menambahkan',
    'item_added': 'ditambahkan ke keranjang',
    'pending': 'Menunggu',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
    'search_orders': 'Cari pesanan...',
    'no_orders': 'Tidak ada pesanan',
    'order_details': 'Detail Pesanan',
    'items': 'item',
    'customer': 'Pelanggan',
    'walk_in': 'Umum',
    'customer_name_label': 'Nama Pelanggan',
    'order_type_label': 'Tipe Pesanan',
    'enter_name_hint': 'Masukkan nama',
    'dine_in': 'Dine In',
    'take_away': 'Takeaway',

    // Payment
    'payment': 'Pembayaran',
    'payment_method': 'Metode Pembayaran',
    'cash': 'Tunai',
    'card': 'Kartu',
    'qris': 'QRIS',
    'amount_paid': 'Jumlah Dibayar',
    'change': 'Kembalian',
    'complete_payment': 'Selesaikan Pembayaran',
    'payment_successful': 'Pembayaran Berhasil',
    'total_amount': 'Total Pembayaran',

    // Receipt
    'digital_receipt': 'Struk Digital',
    'print_receipt': 'Cetak Struk',
    'new_order': 'Pesanan Baru',
    'transaction': 'Transaksi',
    'thank_you': 'Terima kasih atas pembelian Anda!',
    'come_again': 'Silakan datang kembali',
    'receipt_preview': 'Preview Struk',
    'customize_receipt': 'Kustomisasi Struk',

    // Reports
    'reports_analytics': 'Laporan & Analitik',
    'sales_overview': 'Ringkasan Penjualan',
    'top_products': 'Produk Terlaris',
    'order_statistics': 'Statistik Pesanan',
    'today': 'Hari Ini',
    'this_week': 'Minggu Ini',
    'this_month': 'Bulan Ini',
    'this_year': 'Tahun Ini',
    'custom': 'Kustom',
    'export_report': 'Ekspor Laporan',
    'average_order': 'Rata-rata Pesanan',
    'best_selling': 'Terlaris',
    'sold': 'Terjual',
    'order_status_distribution': 'Distribusi Status Pesanan',

    // Settings
    'general_settings': 'Pengaturan Umum',
    'language': 'Bahasa',
    'select_language': 'Pilih bahasa aplikasi',
    'currency': 'Mata Uang',
    'select_currency': 'Pilih mata uang tampilan',
    'tax_rate': 'Tarif Pajak',
    'default_tax_rate': 'Tarif pajak default untuk pesanan',
    'appearance': 'Tampilan',
    'notifications': 'Notifikasi',
    'push_notifications': 'Notifikasi Push',
    'receive_notifications': 'Terima notifikasi untuk pesanan baru',
    'data_backup': 'Data & Cadangan',
    'auto_backup': 'Cadangan Otomatis',
    'auto_backup_desc': 'Cadangkan data secara otomatis setiap hari',
    'export_data': 'Ekspor Data',
    'export_data_desc': 'Ekspor semua data ke CSV',
    'import_data': 'Impor Data',
    'import_data_desc': 'Impor data dari file CSV',
    'clear_data': 'Hapus Semua Data',
    'clear_data_desc': 'Hapus semua pesanan dan reset statistik',
    'clear_data_confirm':
        'Tindakan ini akan menghapus semua data secara permanen. Apakah Anda yakin?',
    'account': 'Akun',
    'change_password': 'Ubah Kata Sandi',
    'update_password': 'Perbarui kata sandi akun Anda',
    'manage_users': 'Kelola Pengguna',
    'manage_users_desc': 'Tambah atau hapus akun pengguna',
    'about': 'Tentang',
    'version': 'Versi',
    'developer': 'Pengembang',
    'privacy_policy': 'Kebijakan Privasi',
    'terms_of_service': 'Ketentuan Layanan',

    // Company Settings
    'company_settings': 'Pengaturan Perusahaan',
    'company_name': 'Nama Perusahaan',
    'company_address': 'Alamat Perusahaan',
    'company_phone': 'Telepon Perusahaan',
    'company_logo': 'Logo Perusahaan',
    'select_logo': 'Pilih Logo',
    'remove_logo': 'Hapus Logo',

    // Receipt Settings
    'receipt_settings': 'Pengaturan Struk',
    'receipt_header': 'Header Struk',
    'receipt_footer': 'Footer Struk',
    'auto_print': 'Cetak Otomatis',
    'auto_print_desc': 'Cetak struk otomatis setelah pembayaran',

    // User Management
    'add_user': 'Tambah Pengguna',
    'edit_user': 'Edit Pengguna',
    'delete_user': 'Hapus Pengguna',
    'user_name': 'Nama',
    'user_role': 'Peran',
    'admin': 'Admin',
    'current_password': 'Kata Sandi Saat Ini',
    'new_password': 'Kata Sandi Baru',
    'confirm_password': 'Konfirmasi Kata Sandi',
    'password_changed': 'Kata sandi berhasil diubah',
    'password_mismatch': 'Kata sandi tidak cocok',
    'wrong_password': 'Kata sandi saat ini salah',
    'user_added': 'Pengguna berhasil ditambahkan',
    'user_updated': 'Pengguna berhasil diperbarui',
    'user_deleted': 'Pengguna berhasil dihapus',
    'confirm_delete_user': 'Apakah Anda yakin ingin menghapus pengguna ini?',
    'you': 'Anda',

    // Date Range
    'select_date_range': 'Pilih Rentang Tanggal',
    'start_date': 'Tanggal Mulai',
    'end_date': 'Tanggal Akhir',
    'apply': 'Terapkan',
    'reset': 'Reset',
    'last_7_days': '7 Hari Terakhir',
    'last_30_days': '30 Hari Terakhir',
    'last_90_days': '90 Hari Terakhir',

    // Export/Import
    'export_success': 'Data berhasil diekspor',
    'import_success': 'Data berhasil diimpor',
    'export_failed': 'Gagal mengekspor data',
    'import_failed': 'Gagal mengimpor data',
    'select_file': 'Pilih File',
    'exporting': 'Mengekspor...',
    'importing': 'Mengimpor...',

    // Filters
    'filter': 'Filter',
    'filter_by_status': 'Filter berdasarkan status:',
    'all': 'Semua',
    'orders_count': 'pesanan',

    // Actions
    'actions': 'Aksi',
    'view': 'Lihat',
    'view_details': 'Lihat Detail',
    'share': 'Bagikan',
    'download': 'Unduh',
    'refresh': 'Segarkan',
    'update': 'Perbarui',
    'create': 'Buat',

    // Bluetooth Printer
    'bluetooth_printer': 'Printer Bluetooth',
    'connect_thermal_printer': 'Hubungkan printer thermal untuk cetak struk',
    'scan_devices': 'Cari Perangkat',
    'scanning': 'Mencari...',
    'connect': 'Hubungkan',
    'disconnect': 'Putuskan',
    'connected': 'Terhubung',
    'available_devices': 'Perangkat Tersedia',
    'no_devices_found': 'Tidak ada perangkat ditemukan',
    'tap_scan_to_search': 'Ketuk Cari Perangkat untuk mencari printer',
    'bluetooth_not_supported_web':
        'Bluetooth tidak didukung di browser. Gunakan aplikasi mobile atau desktop.',

    'printer_settings': 'Pengaturan Printer',
    'payment_settings': 'Pengaturan Pembayaran',
    'midtrans_server_key': 'Midtrans Server Key',
    'midtrans_enabled': 'Aktifkan Pembayaran Midtrans',
    'midtrans_sandbox_hint':
        'Gunakan Server Key dari akun Midtrans Sandbox/Production Anda.',
  };

  static const Map<String, String> _englishStrings = {
    // General
    'app_name': 'POS System',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'edit': 'Edit',
    'add': 'Add',
    'search': 'Search',
    'close': 'Close',
    'confirm': 'Confirm',
    'success': 'Success',
    'error': 'Error',
    'field_required': 'Field is required',
    'warning': 'Warning',
    'loading': 'Loading...',
    'no_data': 'No data',
    'yes': 'Yes',
    'no': 'No',

    // Auth
    'login': 'Login',
    'logout': 'Logout',
    'username': 'Username',
    'password': 'Password',
    'remember_me': 'Remember Me',
    'forgot_password': 'Forgot Password?',
    'sign_in': 'Sign In',
    'sign_in_to_continue': 'Please sign in to continue',
    'invalid_credentials': 'Invalid username or password',
    'logout_confirm': 'Are you sure you want to logout?',
    'welcome_back': 'Welcome Back',

    // Navigation
    'dashboard': 'Dashboard',
    'products': 'Products',
    'sales': 'Sales',
    'reports': 'Reports',
    'settings': 'Settings',
    'cashier': 'Cashier',
    'menu': 'Menu',
    'history': 'History',
    'price': 'Price',

    // Dashboard
    'total_revenue': 'Total Revenue',
    'total_products': 'Total Products',
    'total_orders': 'Total Orders',
    'today_revenue': 'Today Revenue',
    'weekly_sales': 'Weekly Sales',
    'recent_transactions': 'Recent Transactions',
    'view_all': 'View All',
    'all_time': 'All Time',
    'active_products': 'Active Products',
    'completed_orders': 'Completed Orders',

    // Products
    'add_product': 'Add Product',
    'edit_product': 'Edit Product',
    'delete_product': 'Delete Product',
    'product_name': 'Product Name',
    'category': 'Category',

    'stock': 'Stock',
    'description': 'Description',
    'image_url': 'Image URL',
    'active': 'Active',
    'inactive': 'Inactive',
    'out_of_stock': 'Out of Stock',
    'low_stock': 'Low Stock',
    'in_stock': 'In Stock',
    'search_products': 'Search products...',
    'no_products': 'No products found',
    'product_added': 'Product added successfully',
    'product_updated': 'Product updated successfully',
    'product_deleted': 'Product deleted successfully',
    'confirm_delete_product': 'Are you sure you want to delete this product?',
    'all_categories': 'All Categories',

    // Orders
    'current_order': 'Current Order',
    'order_number': 'Order Number',
    'order_date': 'Order Date',
    'order_status': 'Order Status',
    'order_items': 'Order Items',
    'subtotal': 'Subtotal',
    'tax': 'Tax',
    'discount': 'Discount',
    'add_discount': 'Add Discount',
    'discount_amount': 'Discount Amount',
    'remove': 'Remove',
    'total': 'Total',
    'checkout': 'Checkout',
    'clear': 'Clear',
    'no_items': 'No items in cart',
    'add_items': 'Tap on products to add',
    'item_added': 'added to cart',
    'pending': 'Pending',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
    'search_orders': 'Search orders...',
    'no_orders': 'No orders found',
    'order_details': 'Order Details',
    'items': 'items',
    'customer': 'Customer',
    'walk_in': 'Walk-in',
    'customer_name_label': 'Customer Name',
    'order_type_label': 'Order Type',
    'enter_name_hint': 'Enter name',
    'dine_in': 'Dine In',
    'take_away': 'Takeaway',

    // Payment
    'payment': 'Payment',
    'payment_method': 'Payment Method',
    'cash': 'Cash',
    'card': 'Card',
    'qris': 'QRIS',
    'amount_paid': 'Amount Paid',
    'change': 'Change',
    'complete_payment': 'Complete Payment',
    'payment_successful': 'Payment Successful',
    'total_amount': 'Total Amount',

    // Receipt
    'digital_receipt': 'Digital Receipt',
    'print_receipt': 'Print Receipt',
    'new_order': 'New Order',
    'transaction': 'Transaction',
    'thank_you': 'Thank you for your purchase!',
    'come_again': 'Please come again',
    'receipt_preview': 'Receipt Preview',
    'customize_receipt': 'Customize Receipt',

    // Reports
    'reports_analytics': 'Reports & Analytics',
    'sales_overview': 'Sales Overview',
    'top_products': 'Top Products',
    'order_statistics': 'Order Statistics',
    'today': 'Today',
    'this_week': 'This Week',
    'this_month': 'This Month',
    'this_year': 'This Year',
    'custom': 'Custom',
    'export_report': 'Export Report',
    'average_order': 'Average Order',
    'best_selling': 'Best Selling',
    'sold': 'sold',
    'order_status_distribution': 'Order Status Distribution',

    // Settings
    'general_settings': 'General Settings',
    'language': 'Language',
    'select_language': 'Select application language',
    'currency': 'Currency',
    'select_currency': 'Select display currency',
    'tax_rate': 'Tax Rate',
    'default_tax_rate': 'Default tax rate for orders',
    'appearance': 'Appearance',
    'notifications': 'Notifications',
    'push_notifications': 'Push Notifications',
    'receive_notifications': 'Receive notifications for new orders',
    'data_backup': 'Data & Backup',
    'auto_backup': 'Auto Backup',
    'auto_backup_desc': 'Automatically backup data daily',
    'export_data': 'Export Data',
    'export_data_desc': 'Export all data to CSV',
    'import_data': 'Import Data',
    'import_data_desc': 'Import data from CSV file',
    'clear_data': 'Clear All Data',
    'clear_data_desc': 'Delete all orders and reset statistics',
    'clear_data_confirm':
        'This action will permanently delete all data. Are you sure?',
    'account': 'Account',
    'change_password': 'Change Password',
    'update_password': 'Update your account password',
    'manage_users': 'Manage Users',
    'manage_users_desc': 'Add or remove user accounts',
    'about': 'About',
    'version': 'Version',
    'developer': 'Developer',
    'privacy_policy': 'Privacy Policy',
    'terms_of_service': 'Terms of Service',

    // Company Settings
    'company_settings': 'Company Settings',
    'company_name': 'Company Name',
    'company_address': 'Company Address',
    'company_phone': 'Company Phone',
    'company_logo': 'Company Logo',
    'select_logo': 'Select Logo',
    'remove_logo': 'Remove Logo',

    // Receipt Settings
    'receipt_settings': 'Receipt Settings',
    'receipt_header': 'Receipt Header',
    'receipt_footer': 'Receipt Footer',
    'auto_print': 'Auto Print',
    'auto_print_desc': 'Automatically print receipt after payment',

    // User Management
    'add_user': 'Add User',
    'edit_user': 'Edit User',
    'delete_user': 'Delete User',
    'user_name': 'Name',
    'user_role': 'Role',
    'admin': 'Admin',
    'current_password': 'Current Password',
    'new_password': 'New Password',
    'confirm_password': 'Confirm Password',
    'password_changed': 'Password changed successfully',
    'password_mismatch': 'Passwords do not match',
    'wrong_password': 'Current password is incorrect',
    'user_added': 'User added successfully',
    'user_updated': 'User updated successfully',
    'user_deleted': 'User deleted successfully',
    'confirm_delete_user': 'Are you sure you want to delete this user?',
    'you': 'You',

    // Date Range
    'select_date_range': 'Select Date Range',
    'start_date': 'Start Date',
    'end_date': 'End Date',
    'apply': 'Apply',
    'reset': 'Reset',
    'last_7_days': 'Last 7 Days',
    'last_30_days': 'Last 30 Days',
    'last_90_days': 'Last 90 Days',

    // Export/Import
    'export_success': 'Data exported successfully',
    'import_success': 'Data imported successfully',
    'export_failed': 'Failed to export data',
    'import_failed': 'Failed to import data',
    'select_file': 'Select File',
    'exporting': 'Exporting...',
    'importing': 'Importing...',

    // Filters
    'filter': 'Filter',
    'filter_by_status': 'Filter by status:',
    'all': 'All',
    'orders_count': 'orders',

    // Actions
    'actions': 'Actions',
    'view': 'View',
    'view_details': 'View Details',
    'share': 'Share',
    'download': 'Download',
    'refresh': 'Refresh',
    'update': 'Update',
    'create': 'Create',

    // Payment Settings
    'payment_settings': 'Payment Settings',
    'midtrans_server_key': 'Midtrans Server Key',
    'midtrans_enabled': 'Enable Midtrans Payment',
    'midtrans_sandbox_hint':
        'Use Server Key from your Midtrans Sandbox/Production dashboard.',
  };
}
