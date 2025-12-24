import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/admin_sidebar.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'reports_screen.dart';
import 'shift_report_screen.dart';
import 'settings_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Defer provider calls to after the first frame to avoid notifying listeners
    // while the widget tree is still building (common on web/slow devices).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    await Future.wait([
      productProvider.loadAllProducts(),
      orderProvider.loadOrders(),
    ]);
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ProductsScreen();
      case 2:
        return const SalesScreen();
      case 3:
        return const ReportsScreen();
      case 4:
        return const ShiftReportScreen();
      case 5:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  String _getTitle(SettingsProvider settings) {
    switch (_selectedIndex) {
      case 0:
        return settings.tr('dashboard');
      case 1:
        return settings.tr('products');
      case 2:
        return settings.tr('sales');
      case 3:
        return settings.tr('reports');
      case 4:
        return 'Shift Reports';
      case 5:
        return settings.tr('settings');
      default:
        return settings.tr('dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final user = authProvider.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 900;

        if (isSmallScreen) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(
                _getTitle(settings),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 2,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Implement mobile search
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            drawer: Drawer(
              child: AdminSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context); // Close drawer
                },
                onLogout: _handleLogout,
                userName: user?.name ?? 'Admin',
                userRole:
                    user?.role.toString().split('.').last.toUpperCase() ??
                    'ADMIN',
              ),
            ),
            body: Container(color: AppColors.background, child: _buildBody()),
          );
        }

        // Desktop Layout
        return Scaffold(
          body: Row(
            children: [
              // Sidebar
              AdminSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                onLogout: _handleLogout,
                userName: user?.name ?? 'Admin',
                userRole:
                    user?.role.toString().split('.').last.toUpperCase() ??
                    'ADMIN',
              ),

              // Main Content
              Expanded(
                child: Container(
                  color: AppColors.background,
                  child: Column(
                    children: [
                      // Top Bar
                      _buildTopBar(settings, user, isSmallScreen),

                      // Content
                      Expanded(child: _buildBody()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(
    SettingsProvider settings,
    dynamic user,
    bool isSmallScreen,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _getTitle(settings),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
