import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class CashierSettingsScreen extends StatefulWidget {
  const CashierSettingsScreen({super.key});

  @override
  State<CashierSettingsScreen> createState() => _CashierSettingsScreenState();
}

class _CashierSettingsScreenState extends State<CashierSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    // Reusing the same layout style as the admin settings for consistency,
    // but with reduced options.
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(settings.tr('general_settings')),
                  const SizedBox(height: 16),
                  _buildGeneralSettingsCard(settings),
                  const SizedBox(height: 32),
                  _buildSectionTitle(settings.tr('receipt_settings')),
                  const SizedBox(height: 16),
                  _buildReceiptSettingsCard(settings),
                  const SizedBox(height: 32),
                  _buildSectionTitle(settings.tr('account')),
                  const SizedBox(height: 16),
                  _buildAccountSettingsCard(settings),
                  const SizedBox(height: 32),
                  _buildSectionTitle(settings.tr('about')),
                  const SizedBox(height: 16),
                  _buildAboutCard(settings),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
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
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56, endIndent: 16);
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }

  Widget _buildDropdownBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  // --- Cards ---

  Widget _buildGeneralSettingsCard(SettingsProvider settings) {
    return _buildSettingsCard([
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildIconBox(Icons.language),
        title: Text(
          settings.tr('language'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          settings.tr('select_language'),
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        trailing: _buildDropdownBox(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AppLanguage>(
              value: settings.language,
              items: const [
                DropdownMenuItem(
                  value: AppLanguage.indonesian,
                  child: Text('Indonesia'),
                ),
                DropdownMenuItem(
                  value: AppLanguage.english,
                  child: Text('English'),
                ),
              ],
              onChanged: (v) {
                if (v != null) settings.setLanguage(v);
              },
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildReceiptSettingsCard(SettingsProvider settings) {
    return _buildSettingsCard([
      _buildSwitchTile(
        icon: Icons.print_outlined,
        title: settings.tr('auto_print'),
        subtitle: settings.tr('auto_print_desc'),
        value: settings.autoPrint,
        onChanged: (v) => settings.setAutoPrint(v),
      ),
    ]);
  }

  Widget _buildAccountSettingsCard(SettingsProvider settings) {
    return _buildSettingsCard([
      _buildActionTile(
        icon: Icons.lock_outline,
        title: settings.tr('change_password'),
        subtitle: settings.tr('update_password'),
        onTap: () => _showChangePasswordDialog(settings),
      ),
    ]);
  }

  Widget _buildAboutCard(SettingsProvider settings) {
    return _buildSettingsCard([
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildIconBox(Icons.info_outline),
        title: Text(
          settings.tr('version'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        trailing: const Text(
          '1.0.0',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      _buildDivider(),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildIconBox(Icons.code),
        title: Text(
          settings.tr('developer'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        trailing: const Text(
          'POS System Team',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    ]);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildIconBox(icon),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog(SettingsProvider settings) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settings.tr('change_password')),
        content: SizedBox(
          width: MediaQuery.of(context).size.width < 400
              ? double.maxFinite
              : 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: settings.tr('current_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: settings.tr('new_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: settings.tr('confirm_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(settings.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(settings.tr('password_mismatch'))),
                );
                return;
              }
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final success = await authProvider.changePassword(
                currentController.text,
                newController.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? settings.tr('password_changed')
                          : settings.tr('wrong_password'),
                    ),
                  ),
                );
              }
            },
            child: Text(settings.tr('update')),
          ),
        ],
      ),
    );
  }
}
