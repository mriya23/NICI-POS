import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'checkout_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'receipt_screen.dart';
import '../../utils/formatters.dart';
import '../admin/sales_screen.dart';
import 'cashier_settings_screen.dart';
import '../../providers/shift_provider.dart';
import '../../models/shift_model.dart';

class CashierMainScreen extends StatefulWidget {
  const CashierMainScreen({super.key});

  @override
  State<CashierMainScreen> createState() => _CashierMainScreenState();
}

class _CashierMainScreenState extends State<CashierMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.setTaxRate(settings.taxRate / 100);
      _checkShift();
    });
  }

  Future<void> _checkShift() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      await shiftProvider.checkActiveShift(user.id);

      if (!mounted) return;
      if (shiftProvider.currentShift == null) {
        // Show Start Shift Dialog
        _showStartShiftDialog();
      }
    }
  }

  void _showStartShiftDialog() {
    final startCashController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                color: AppColors.primary,
                child: Column(
                  children: [
                    const Icon(
                      Icons.store_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Buka Kasir',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Pagi! Masukkan modal awal yang ada di laci kasir untuk memulai shift.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: startCashController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Modal Awal',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final text = startCashController.text.replaceAll(
                            '.',
                            '',
                          );
                          final amount = double.tryParse(text);
                          if (amount == null) return;

                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final shiftProvider = Provider.of<ShiftProvider>(
                            context,
                            listen: false,
                          );

                          if (authProvider.currentUser != null) {
                            final success = await shiftProvider.startShift(
                              authProvider.currentUser!.id,
                              amount,
                            );
                            if (success) {
                              if (!mounted) return;
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Buka Kasir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          // Logout logic
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          authProvider.logout();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndShiftDialog() {
    final actualCashController = TextEditingController();
    final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                color: AppColors.error,
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tutup Kasir',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Silakan hitung total uang fisik yang ada di laci kasir saat ini untuk verifikasi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: actualCashController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Total Uang Fisik',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: AppColors.textSecondary,
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final text = actualCashController.text.replaceAll(
                                '.',
                                '',
                              );
                              final amount = double.tryParse(text);
                              if (amount == null) return;

                              final closedShift = await shiftProvider.endShift(
                                amount,
                              );
                              if (!mounted) return;
                              Navigator.pop(context); // Close Dialog
                              if (closedShift != null) {
                                _showShiftSummaryDialog(closedShift);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Tutup Shift',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShiftSummaryDialog(Shift shift) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 400,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  color: AppColors.success,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Shift Selesai',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Waktu Mulai',
                        Formatters.formatDateTime(shift.startTime),
                      ),
                      if (shift.endTime != null)
                        _buildDetailRow(
                          'Waktu Selesai',
                          Formatters.formatDateTime(shift.endTime!),
                        ),
                      const Divider(height: 32),
                      _buildDetailRow(
                        'Modal Awal',
                        settings.formatCurrency(shift.startCash),
                      ),
                      _buildDetailRow(
                        'Penjualan Tunai',
                        settings.formatCurrency(
                          shift.expectedCash - shift.startCash,
                        ),
                      ),
                      _buildDetailRow(
                        'Total Sistem',
                        settings.formatCurrency(shift.expectedCash),
                      ),
                      _buildDetailRow(
                        'Uang Fisik',
                        settings.formatCurrency(shift.actualCash ?? 0),
                      ),
                      const Divider(height: 32),
                      _buildDetailRow(
                        'Selisih',
                        settings.formatCurrency(shift.difference),
                        color: shift.difference < 0
                            ? AppColors.error
                            : AppColors.success,
                        isBold: true,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _checkShift();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Selesai & Keluar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProducts() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    await productProvider.loadProducts();
  }

  void _handleLogout() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settings.tr('logout')),
        content: Text(settings.tr('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(settings.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(settings.tr('logout')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final user = authProvider.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: isMobile
              ? _buildMobileDrawer(user?.name ?? 'Cashier', settings)
              : null,
          floatingActionButton: isMobile ? _buildMobileCartFab(settings) : null,
          body: Row(
            children: [
              // Sidebar (Desktop only)
              if (!isMobile) _buildSidebar(user?.name ?? 'Cashier', settings),

              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // Top Bar
                    _buildTopBar(settings, isMobile),

                    // Products Section
                    Expanded(child: _buildProductsSection(settings, isMobile)),
                  ],
                ),
              ),

              // Right Panel (Desktop only)
              if (!isMobile) _buildOrderPanel(settings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(SettingsProvider settings, bool isMobile) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.companyName.isNotEmpty
                    ? settings.companyName
                    : 'Point of Sale',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!isMobile)
                Text(
                  Formatters.formatDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const Spacer(),

          // Search Bar
          if (!isMobile)
            Container(
              width: 300,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  return TextField(
                    onChanged: provider.setSearchQuery,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: settings.tr('search_products'),
                      hintStyle: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  );
                },
              ),
            )
          else
            IconButton(
              onPressed: () {
                // Expand search on mobile (simplified for now)
              },
              icon: const Icon(Icons.search),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(String userName, SettingsProvider settings) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(userName),
            accountEmail: const Text('Cashier'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view_rounded),
            title: Text(settings.tr('menu')),
            selected: true,
            selectedColor: AppColors.primary,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: Text(settings.tr('history')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text(settings.tr('history')),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                    ),
                    body: const SalesScreen(),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(settings.tr('settings')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text(settings.tr('settings')),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                    ),
                    body: const CashierSettingsScreen(),
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              settings.tr('logout'),
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMobileCartFab(SettingsProvider settings) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.cartItems.isEmpty) return const SizedBox();
        return FloatingActionButton.extended(
          onPressed: () => _showMobileCart(context, settings),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          label: Text(
            '${provider.cartItemCount} - ${settings.formatCurrency(provider.total)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  void _showMobileCart(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(child: _buildOrderPanel(settings, isMobileView: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(String userName, SettingsProvider settings) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          if (settings.companyLogo.isNotEmpty)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildLogoImage(settings),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.point_of_sale,
                color: Colors.white,
                size: 24,
              ),
            ),
          const SizedBox(height: 32),
          _buildNavItem(
            Icons.grid_view_rounded,
            settings.tr('menu'),
            true,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildNavItem(
            Icons.history_rounded,
            settings.tr('history'),
            false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text(settings.tr('history')),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                    ),
                    body: const SalesScreen(),
                    backgroundColor: AppColors.background,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildNavItem(
            Icons.settings_outlined,
            settings.tr('settings'),
            false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text(settings.tr('settings')),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                    ),
                    body: const CashierSettingsScreen(),
                    backgroundColor: AppColors.background,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          _buildNavItem(
            Icons.point_of_sale_rounded,
            'Shift',
            false,
            onTap: _showEndShiftDialog,
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryBg,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                IconButton(
                  onPressed: _handleLogout,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoImage(SettingsProvider settings) {
    if (settings.companyLogo.startsWith('http') ||
        settings.companyLogo.startsWith('data:')) {
      return Image.network(
        settings.companyLogo,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.primary,
          child: const Icon(Icons.point_of_sale, color: Colors.white, size: 24),
        ),
      );
    }
    if (!kIsWeb) {
      return Image.file(
        File(settings.companyLogo),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.primary,
          child: const Icon(Icons.point_of_sale, color: Colors.white, size: 24),
        ),
      );
    }
    return Container(
      color: AppColors.primary,
      child: const Icon(Icons.point_of_sale, color: Colors.white, size: 24),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? AppColors.sidebarActiveItem : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: onTap ?? () {},
            icon: Icon(
              icon,
              color: isActive
                  ? AppColors.sidebarActiveIcon
                  : AppColors.sidebarInactiveIcon,
              size: 22,
            ),
            tooltip: label,
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Widget _buildProductsSection(SettingsProvider settings, bool isMobile) {
    return Column(
      children: [
        _buildCategoryTabs(settings),
        Expanded(child: _buildProductsGrid(settings, isMobile)),
      ],
    );
  }

  Widget _buildCategoryTabs(SettingsProvider settings) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              final isSelected = provider.selectedCategory == category;
              final categoryColor = AppCategories.getCategoryColor(category);

              return GestureDetector(
                onTap: () => provider.setCategory(category),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? categoryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? categoryColor : AppColors.border,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: categoryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(
                          AppCategories.getCategoryIcon(category),
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid(SettingsProvider settings, bool isMobile) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = provider.filteredProducts;

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  settings.tr('no_products'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(24, 24, 24, isMobile ? 80 : 24),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isMobile ? 200 : 220,
            childAspectRatio: 0.75,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(products[index], settings);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product, SettingsProvider settings) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return GestureDetector(
          onTap: () {
            if (product.stock > 0) {
              orderProvider.addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} ${settings.tr('item_added')}'),
                  width: 250,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(milliseconds: 1000),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${product.name} ${settings.tr('out_of_stock')}',
                  ),
                  backgroundColor: AppColors.error,
                  width: 250,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.cardShadowList,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.image_not_supported_rounded,
                                      size: 40,
                                      color: AppColors.textHint,
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Icon(
                                  Icons.coffee_rounded,
                                  size: 40,
                                  color: AppColors.textHint,
                                ),
                              ),
                        if (product.stock <= 0)
                          Container(
                            color: Colors.white.withValues(alpha: 0.7),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                settings.tr('out_of_stock'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stock: ${product.stock}',
                              style: TextStyle(
                                fontSize: 11,
                                color: product.stock < 10
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              settings.formatCurrency(product.price),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderPanel(
    SettingsProvider settings, {
    bool isMobileView = false,
  }) {
    // If not mobile view, use fixed width. If mobile view (in bottom sheet), flexible width.
    return Container(
      width: isMobileView ? double.infinity : 400,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: isMobileView
            ? null
            : Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.tr('current_order'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Consumer<OrderProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${provider.cartItemCount} items',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Consumer<OrderProvider>(
                  builder: (context, provider, child) {
                    if (provider.cartItems.isEmpty) return const SizedBox();
                    return IconButton(
                      onPressed: () => provider.clearCart(),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.error,
                      tooltip: settings.tr('clear'),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, provider, child) {
                if (provider.cartItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          settings.tr('no_items'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          settings.tr('add_items'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: provider.cartItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildOrderItem(
                      provider.cartItems[index],
                      provider,
                      settings,
                    );
                  },
                );
              },
            ),
          ),
          Consumer<OrderProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      settings.tr('subtotal'),
                      provider.subtotal,
                      settings,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      settings.tr('tax'),
                      provider.taxAmount,
                      settings,
                      isSecondary: true,
                    ),
                    const SizedBox(height: 12),
                    if (provider.discount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            settings.tr('discount'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            '-${settings.formatCurrency(provider.discount)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          settings.tr('total'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          settings.formatCurrency(provider.total),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: provider.cartItems.isEmpty
                            ? null
                            : () => _showCheckoutDialog(
                                context,
                                provider,
                                settings,
                              ),
                        style: ElevatedButton.styleFrom(
                          elevation: 4,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          settings.tr('checkout'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    OrderItem item,
    OrderProvider provider,
    SettingsProvider settings,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            image: (item.productImage != null && item.productImage!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(item.productImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (item.productImage == null || item.productImage!.isEmpty)
              ? const Icon(
                  Icons.image_not_supported_rounded,
                  size: 20,
                  color: AppColors.textHint,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                settings.formatCurrency(item.price),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => provider.decrementCartItem(item.id),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text(
                  item.quantity.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: () => provider.incrementCartItem(item.id),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    SettingsProvider settings, {
    bool isSecondary = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSecondary
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
        Text(
          settings.formatCurrency(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSecondary ? FontWeight.normal : FontWeight.w600,
            color: isSecondary
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showCheckoutDialog(
    BuildContext context,
    OrderProvider orderProvider,
    SettingsProvider settings,
  ) {
    if (orderProvider.total <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(settings.tr('cart_empty'))));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    showDialog(
      context: context,
      builder: (_) => CheckoutDialog(
        onComplete: (paymentMethod, amountPaid, customerName, isDineIn) async {
          debugPrint('Starting checkout process...');
          try {
            debugPrint('Calling createOrder...');
            final order = await orderProvider.createOrder(
              cashierId: user?.id ?? '',
              cashierName: user?.name ?? 'Cashier',
              customerName: customerName,
              isDineIn: isDineIn,
            );
            debugPrint('createOrder result: ${order?.id}');

            if (order != null) {
              debugPrint('Calling completeOrder...');
              final completedOrder = await orderProvider.completeOrder(
                orderId: order.id,
                paymentMethod: paymentMethod,
                amountPaid: amountPaid,
              );
              debugPrint('completeOrder result: ${completedOrder?.id}');

              if (completedOrder != null) {
                if (!context.mounted) {
                  debugPrint('Context not mounted after completeOrder');
                  return false;
                }

                debugPrint('Loading products...');
                await Provider.of<ProductProvider>(
                  context,
                  listen: false,
                ).loadProducts();

                if (!context.mounted) return false;

                // Show success receipt
                debugPrint('Navigating to ReceiptScreen');

                // Close the dialog explicitly first
                Navigator.of(context).pop();

                // Then push the receipt screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReceiptScreen(order: completedOrder),
                  ),
                );

                // Return false to prevent the dialog from trying to pop again
                // (since we just popped it manually)
                return false;
              }
            }

            // If we get here, something failed but didn't throw
            debugPrint(
              'Checkout failed logically. Error: ${orderProvider.errorMessage}',
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    orderProvider.errorMessage ?? 'Gagal memproses pesanan',
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return false;
          } catch (e, stack) {
            debugPrint('Checkout Exception: $e');
            debugPrint('Stack trace: $stack');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return false;
          }
        },
      ),
    );
  }
}
