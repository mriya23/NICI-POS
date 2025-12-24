import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  final String userName;
  final String userRole;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Container(
          width: AppDimensions.sidebarWidth,
          decoration: const BoxDecoration(gradient: AppColors.sidebarGradient),
          child: Column(
            children: [
              // Logo and Title
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                child: Row(
                  children: [
                    // Custom Logo or Default
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildLogo(settings),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.companyName.length > 12
                                ? '${settings.companyName.substring(0, 12)}...'
                                : settings.companyName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            settings.tr('app_name'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.divider, height: 1),

              // Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingMD,
                  ),
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      label: settings.tr('dashboard'),
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.inventory_2_outlined,
                      activeIcon: Icons.inventory_2,
                      label: settings.tr('products'),
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.shopping_cart_outlined,
                      activeIcon: Icons.shopping_cart,
                      label: settings.tr('sales'),
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart,
                      label: settings.tr('reports'),
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: Icons.history_rounded,
                      activeIcon: Icons.history,
                      label: 'Shift Reports',
                    ),
                    _buildNavItem(
                      index: 5,
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      label: settings.tr('settings'),
                    ),
                  ],
                ),
              ),

              // User Info and Logout
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                userRole,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onLogout,
                          icon: const Icon(
                            Icons.logout,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          tooltip: settings.tr('logout'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo(SettingsProvider settings) {
    if (settings.companyLogo.isEmpty) {
      return const Icon(Icons.store, color: AppColors.primary, size: 24);
    }

    if (settings.companyLogo.startsWith('http') ||
        settings.companyLogo.startsWith('data:')) {
      return Image.network(
        settings.companyLogo,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.store, color: AppColors.primary, size: 24),
      );
    }

    if (!kIsWeb) {
      return Image.file(
        File(settings.companyLogo),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.store, color: AppColors.primary, size: 24),
      );
    }

    return const Icon(Icons.store, color: AppColors.primary, size: 24);
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.marginSM,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.sidebarActiveItem : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.primary : AppColors.sidebarInactiveText,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.primary
                : AppColors.sidebarInactiveText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => onItemSelected(index),
        dense: true,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        ),
        hoverColor: AppColors.primary.withValues(alpha: 0.05),
      ),
    );
  }
}
