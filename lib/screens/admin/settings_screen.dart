import 'dart:convert';
import 'dart:io';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../models/export_import_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/export_import_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../widgets/bluetooth_printer_settings.dart';
import '../../widgets/import_result_dialog.dart';
import 'users_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _taxRateController = TextEditingController();
  bool _didInitTaxRate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitTaxRate) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _taxRateController.text = _formatTaxRate(settings.taxRate);
    _didInitTaxRate = true;
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final width = MediaQuery.of(context).size.width;
        final isWide = width >= 1100;
        final isAdmin = Provider.of<AuthProvider>(context).isAdmin;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _SectionCard(
                            icon: Icons.business_rounded,
                            title: settings.tr('company_settings'),
                            children: [
                              _buildCompanyHeader(settings),
                              const Divider(height: 1),
                              _SettingsTile(
                                icon: Icons.badge_outlined,
                                title: settings.tr('company_name'),
                                subtitle: settings.companyName,
                                onTap: () => _showTextEditDialog(
                                  title: settings.tr('company_name'),
                                  initialValue: settings.companyName,
                                  onSave: settings.setCompanyName,
                                ),
                              ),
                              const Divider(height: 1),
                              _SettingsTile(
                                icon: Icons.location_on_outlined,
                                title: settings.tr('company_address'),
                                subtitle: settings.companyAddress,
                                maxLines: 2,
                                onTap: () => _showTextEditDialog(
                                  title: settings.tr('company_address'),
                                  initialValue: settings.companyAddress,
                                  maxLines: 3,
                                  onSave: settings.setCompanyAddress,
                                ),
                              ),
                              const Divider(height: 1),
                              _SettingsTile(
                                icon: Icons.phone_outlined,
                                title: settings.tr('company_phone'),
                                subtitle: settings.companyPhone,
                                onTap: () => _showTextEditDialog(
                                  title: settings.tr('company_phone'),
                                  initialValue: settings.companyPhone,
                                  onSave: settings.setCompanyPhone,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.paddingLG),
                          _SectionCard(
                            icon: Icons.receipt_long_rounded,
                            title: settings.tr('receipt_settings'),
                            children: [
                              _SettingsTile(
                                icon: Icons.text_fields_rounded,
                                title: settings.tr('receipt_header'),
                                subtitle: settings.receiptHeader.isEmpty
                                    ? '-'
                                    : settings.receiptHeader,
                                maxLines: 2,
                                onTap: () => _showTextEditDialog(
                                  title: settings.tr('receipt_header'),
                                  initialValue: settings.receiptHeader,
                                  maxLines: 3,
                                  onSave: settings.setReceiptHeader,
                                ),
                              ),
                              const Divider(height: 1),
                              _SettingsTile(
                                icon: Icons.text_snippet_outlined,
                                title: settings.tr('receipt_footer'),
                                subtitle: settings.receiptFooter.isEmpty
                                    ? '-'
                                    : settings.receiptFooter,
                                maxLines: 2,
                                onTap: () => _showTextEditDialog(
                                  title: settings.tr('receipt_footer'),
                                  initialValue: settings.receiptFooter,
                                  maxLines: 3,
                                  onSave: settings.setReceiptFooter,
                                ),
                              ),
                              const Divider(height: 1),
                              _SettingsTile(
                                icon: Icons.print_outlined,
                                title: settings.tr('auto_print'),
                                subtitle: settings.tr('auto_print_desc'),
                                trailing: Switch(
                                  value: settings.autoPrint,
                                  onChanged: settings.setAutoPrint,
                                  activeTrackColor: AppColors.primary
                                      .withValues(alpha: 0.4),
                                  activeThumbColor: AppColors.primary,
                                ),
                              ),
                              const Divider(height: 1),
                              _SettingsTile(
                                icon: Icons.visibility_outlined,
                                title: settings.tr('receipt_preview'),
                                subtitle: settings.tr('receipt_preview'),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textHint,
                                ),
                                onTap: () => _showReceiptPreview(settings),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.paddingLG),
                          const BluetoothPrinterSettings(),
                          const SizedBox(height: AppDimensions.paddingLG),
                          _SectionCard(
                            icon: Icons.backup_outlined,
                            title: settings.tr('data_backup'),
                            children: [
                              _SettingsTile(
                                icon: Icons.backup_outlined,
                                title: settings.tr('auto_backup'),
                                subtitle: settings.tr('auto_backup_desc'),
                                trailing: Switch(
                                  value: settings.autoBackup,
                                  onChanged: settings.setAutoBackup,
                                  activeTrackColor: AppColors.primary
                                      .withValues(alpha: 0.4),
                                  activeThumbColor: AppColors.primary,
                                ),
                              ),
                              if (isAdmin) ...[
                                const Divider(height: 1),
                                _SettingsTile(
                                  icon: Icons.download_outlined,
                                  title: settings.tr('export_data'),
                                  subtitle: settings.tr('export_data_desc'),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textHint,
                                  ),
                                  onTap: () => _exportData(settings),
                                ),
                                const Divider(height: 1),
                                _SettingsTile(
                                  icon: Icons.upload_outlined,
                                  title: settings.tr('import_data'),
                                  subtitle: settings.tr('import_data_desc'),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textHint,
                                  ),
                                  onTap: () => _importData(settings),
                                ),
                              ],
                              const Divider(height: 1),
                              _SettingsTile(
                                icon: Icons.delete_outline_rounded,
                                title: settings.tr('clear_data'),
                                subtitle: settings.tr('clear_data_desc'),
                                isDestructive: true,
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textHint,
                                ),
                                onTap: () => _showClearDataDialog(settings),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingLG),
                    Expanded(
                      child: Column(
                        children: [
                          _SectionCard(
                            icon: Icons.tune_rounded,
                            title: settings.tr('general_settings'),
                            children: [
                              _SettingsTile(
                                icon: Icons.language_rounded,
                                title: settings.tr('language'),
                                subtitle: settings.tr('select_language'),
                                trailing: _DropdownBox(
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
                              const Divider(height: 1),
                              _SettingsTile(
                                icon: Icons.payments_outlined,
                                title: settings.tr('currency'),
                                subtitle: settings.tr('select_currency'),
                                trailing: _DropdownBox(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<AppCurrency>(
                                      value: settings.currency,
                                      items: const [
                                        DropdownMenuItem(
                                          value: AppCurrency.idr,
                                          child: Text('IDR (Rp)'),
                                        ),
                                        DropdownMenuItem(
                                          value: AppCurrency.usd,
                                          child: Text('USD (\$)'),
                                        ),
                                        DropdownMenuItem(
                                          value: AppCurrency.eur,
                                          child: Text('EUR (€)'),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) settings.setCurrency(v);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              _SettingsTile(
                                icon: Icons.percent_rounded,
                                title: settings.tr('tax_rate'),
                                subtitle: settings.tr('default_tax_rate'),
                                trailing: SizedBox(
                                  width: 92,
                                  child: TextField(
                                    controller: _taxRateController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    decoration: const InputDecoration(
                                      suffixText: '%',
                                      isDense: true,
                                    ),
                                    onSubmitted: (_) =>
                                        _applyTaxRateFromController(settings),
                                    onEditingComplete: () =>
                                        _applyTaxRateFromController(settings),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.paddingLG),
                          _SectionCard(
                            icon: Icons.person_rounded,
                            title: settings.tr('account'),
                            children: [
                              _SettingsTile(
                                icon: Icons.people_outline_rounded,
                                title: settings.tr('manage_users'),
                                subtitle: settings.tr('manage_users_desc'),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textHint,
                                ),
                                onTap: () => _showManageUsersDialog(settings),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.paddingLG),
                          _SectionCard(
                            icon: Icons.info_outline_rounded,
                            title: settings.tr('about'),
                            children: [
                              _SettingsTile(
                                icon: Icons.info_outline_rounded,
                                title: settings.tr('version'),
                                subtitle: AppConstants.appVersion,
                                trailing: const SizedBox.shrink(),
                              ),
                              const Divider(height: 1),
                              _SettingsTile(
                                icon: Icons.code_rounded,
                                title: settings.tr('developer'),
                                subtitle: 'POS System Team',
                                trailing: const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _SectionCard(
                      icon: Icons.business_rounded,
                      title: settings.tr('company_settings'),
                      children: [
                        _buildCompanyHeader(settings),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.badge_outlined,
                          title: settings.tr('company_name'),
                          subtitle: settings.companyName,
                          onTap: () => _showTextEditDialog(
                            title: settings.tr('company_name'),
                            initialValue: settings.companyName,
                            onSave: settings.setCompanyName,
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.location_on_outlined,
                          title: settings.tr('company_address'),
                          subtitle: settings.companyAddress,
                          maxLines: 2,
                          onTap: () => _showTextEditDialog(
                            title: settings.tr('company_address'),
                            initialValue: settings.companyAddress,
                            maxLines: 3,
                            onSave: settings.setCompanyAddress,
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.phone_outlined,
                          title: settings.tr('company_phone'),
                          subtitle: settings.companyPhone,
                          onTap: () => _showTextEditDialog(
                            title: settings.tr('company_phone'),
                            initialValue: settings.companyPhone,
                            onSave: settings.setCompanyPhone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingLG),
                    _SectionCard(
                      icon: Icons.tune_rounded,
                      title: settings.tr('general_settings'),
                      children: [
                        _SettingsTile(
                          icon: Icons.language_rounded,
                          title: settings.tr('language'),
                          subtitle: settings.tr('select_language'),
                          trailing: _DropdownBox(
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
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.payments_outlined,
                          title: settings.tr('currency'),
                          subtitle: settings.tr('select_currency'),
                          trailing: _DropdownBox(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<AppCurrency>(
                                value: settings.currency,
                                items: const [
                                  DropdownMenuItem(
                                    value: AppCurrency.idr,
                                    child: Text('IDR (Rp)'),
                                  ),
                                  DropdownMenuItem(
                                    value: AppCurrency.usd,
                                    child: Text('USD (\$)'),
                                  ),
                                  DropdownMenuItem(
                                    value: AppCurrency.eur,
                                    child: Text('EUR (€)'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) settings.setCurrency(v);
                                },
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.percent_rounded,
                          title: settings.tr('tax_rate'),
                          subtitle: settings.tr('default_tax_rate'),
                          trailing: SizedBox(
                            width: 92,
                            child: TextField(
                              controller: _taxRateController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                suffixText: '%',
                                isDense: true,
                              ),
                              onSubmitted: (_) =>
                                  _applyTaxRateFromController(settings),
                              onEditingComplete: () =>
                                  _applyTaxRateFromController(settings),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingLG),
                    _SectionCard(
                      icon: Icons.receipt_long_rounded,
                      title: settings.tr('receipt_settings'),
                      children: [
                        _SettingsTile(
                          icon: Icons.text_fields_rounded,
                          title: settings.tr('receipt_header'),
                          subtitle: settings.receiptHeader.isEmpty
                              ? '-'
                              : settings.receiptHeader,
                          maxLines: 2,
                          onTap: () => _showTextEditDialog(
                            title: settings.tr('receipt_header'),
                            initialValue: settings.receiptHeader,
                            maxLines: 3,
                            onSave: settings.setReceiptHeader,
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.text_snippet_outlined,
                          title: settings.tr('receipt_footer'),
                          subtitle: settings.receiptFooter.isEmpty
                              ? '-'
                              : settings.receiptFooter,
                          maxLines: 2,
                          onTap: () => _showTextEditDialog(
                            title: settings.tr('receipt_footer'),
                            initialValue: settings.receiptFooter,
                            maxLines: 3,
                            onSave: settings.setReceiptFooter,
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.print_outlined,
                          title: settings.tr('auto_print'),
                          subtitle: settings.tr('auto_print_desc'),
                          trailing: Switch(
                            value: settings.autoPrint,
                            onChanged: settings.setAutoPrint,
                            activeTrackColor: AppColors.primary.withValues(
                              alpha: 0.4,
                            ),
                            activeThumbColor: AppColors.primary,
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.visibility_outlined,
                          title: settings.tr('receipt_preview'),
                          subtitle: settings.tr('receipt_preview'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textHint,
                          ),
                          onTap: () => _showReceiptPreview(settings),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingLG),
                    const BluetoothPrinterSettings(),
                    const SizedBox(height: AppDimensions.paddingLG),
                    _SectionCard(
                      icon: Icons.payments_rounded,
                      title: settings.tr('payment_settings'),
                      children: [
                        _SettingsTile(
                          icon: Icons.key_rounded,
                          title: settings.tr('midtrans_server_key'),
                          subtitle: settings.midtransServerKey.isEmpty
                              ? settings.tr('midtrans_sandbox_hint')
                              : '••••••••••••••••',
                          onTap: () => _showTextEditDialog(
                            title: settings.tr('midtrans_server_key'),
                            initialValue: settings.midtransServerKey,
                            onSave: settings.setMidtransServerKey,
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.toggle_on_rounded,
                          title: settings.tr('midtrans_enabled'),
                          subtitle: settings.tr('midtrans_enabled'),
                          trailing: Switch(
                            value: settings.isMidtransEnabled,
                            onChanged: settings.setMidtransEnabled,
                            activeTrackColor: AppColors.primary.withValues(
                              alpha: 0.4,
                            ),
                            activeThumbColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingLG),
                    _SectionCard(
                      icon: Icons.backup_outlined,
                      title: settings.tr('data_backup'),
                      children: [
                        _SettingsTile(
                          icon: Icons.backup_outlined,
                          title: settings.tr('auto_backup'),
                          subtitle: settings.tr('auto_backup_desc'),
                          trailing: Switch(
                            value: settings.autoBackup,
                            onChanged: settings.setAutoBackup,
                            activeTrackColor: AppColors.primary.withValues(
                              alpha: 0.4,
                            ),
                            activeThumbColor: AppColors.primary,
                          ),
                        ),
                        if (isAdmin) ...[
                          const Divider(height: 1),
                          _SettingsTile(
                            icon: Icons.download_outlined,
                            title: settings.tr('export_data'),
                            subtitle: settings.tr('export_data_desc'),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textHint,
                            ),
                            onTap: () => _exportData(settings),
                          ),
                          const Divider(height: 1),
                          _SettingsTile(
                            icon: Icons.upload_outlined,
                            title: settings.tr('import_data'),
                            subtitle: settings.tr('import_data_desc'),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textHint,
                            ),
                            onTap: () => _importData(settings),
                          ),
                        ],
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.delete_outline_rounded,
                          title: settings.tr('clear_data'),
                          subtitle: settings.tr('clear_data_desc'),
                          isDestructive: true,
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textHint,
                          ),
                          onTap: () => _showClearDataDialog(settings),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingLG),
                    _SectionCard(
                      icon: Icons.person_rounded,
                      title: settings.tr('account'),
                      children: [
                        _SettingsTile(
                          icon: Icons.lock_outline_rounded,
                          title: settings.tr('change_password'),
                          subtitle: settings.tr('update_password'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textHint,
                          ),
                          onTap: () => _showChangePasswordDialog(settings),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.people_outline_rounded,
                          title: settings.tr('manage_users'),
                          subtitle: settings.tr('manage_users_desc'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textHint,
                          ),
                          onTap: () => _showManageUsersDialog(settings),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingLG),
                    _SectionCard(
                      icon: Icons.info_outline_rounded,
                      title: settings.tr('about'),
                      children: [
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          title: settings.tr('version'),
                          subtitle: AppConstants.appVersion,
                          trailing: const SizedBox.shrink(),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.code_rounded,
                          title: settings.tr('developer'),
                          subtitle: 'POS System Team',
                          trailing: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCompanyHeader(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _CompanyLogoAvatar(logo: settings.companyLogo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.companyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  settings.companyAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _pickLogo(settings),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
            ),
            child: Text(settings.tr('select_logo')),
          ),
        ],
      ),
    );
  }

  String _formatTaxRate(double rate) {
    final trimmed = rate.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
    return trimmed.endsWith('.')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  void _applyTaxRateFromController(SettingsProvider settings) {
    final raw = _taxRateController.text.trim().replaceAll(',', '.');
    final rate = double.tryParse(raw);
    if (rate == null) return;

    settings.setTaxRate(rate);
    Provider.of<OrderProvider>(context, listen: false).setTaxRate(rate / 100);
  }

  Future<void> _pickLogo(SettingsProvider settings) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) return;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        await settings.setCompanyLogo('data:image/png;base64,$base64Image');
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'company_logo_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedFile = await File(
          image.path,
        ).copy('${appDir.path}/$fileName');
        await settings.setCompanyLogo(savedFile.path);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Logo berhasil diubah'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Gagal memilih gambar: $e')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _showTextEditDialog({
    required String title,
    required String initialValue,
    required Future<void> Function(String) onSave,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await onSave(controller.text.trim());
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text('$title berhasil disimpan')),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Gagal menyimpan: $e')),
                        ],
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showReceiptPreview(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      settings.tr('receipt_preview'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _ReceiptPreviewCard(settings: settings),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(settings.tr('close')),
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

  void _exportData(SettingsProvider settings) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.isIndonesian ? 'Akses ditolak' : 'Access denied',
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _ExportDataDialog(settings: settings),
    );
  }

  void _importData(SettingsProvider settings) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.isIndonesian ? 'Akses ditolak' : 'Access denied',
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _ImportDataDialog(settings: settings),
    );
  }

  void _showClearDataDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(settings.tr('clear_data')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(settings.tr('clear_data_confirm')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data yang dihapus:\n• Semua pesanan\n• Semua transaksi',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(settings.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Menghapus data...'),
                    ],
                  ),
                ),
              );

              try {
                final result = await DatabaseService()
                    .clearAllTransactionData();

                // Close loading dialog
                if (mounted) Navigator.pop(context);

                // Refresh order provider
                if (mounted) {
                  Provider.of<OrderProvider>(
                    context,
                    listen: false,
                  ).clearCart();
                }

                // Show success
                if (mounted) {
                  final total = result['orders']! + result['transactions']!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Berhasil menghapus $total data (${result['orders']} pesanan, ${result['transactions']} transaksi)',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog
                if (mounted) Navigator.pop(context);

                // Show error
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Gagal menghapus data: $e')),
                        ],
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(settings.tr('delete')),
          ),
        ],
      ),
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
              : 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: settings.tr('current_password'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: settings.tr('new_password'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: settings.tr('confirm_password'),
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

              if (!context.mounted) return;
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
            },
            child: Text(settings.tr('update')),
          ),
        ],
      ),
    );
  }

  void _showManageUsersDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            child: const UsersScreen(),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.cardShadowList,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                _IconBox(icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final int maxLines;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.maxLines = 1,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDestructive ? AppColors.error : AppColors.textPrimary;
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _IconBox(icon: icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _DropdownBox extends StatelessWidget {
  final Widget child;

  const _DropdownBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      ),
      child: child,
    );
  }
}

class _CompanyLogoAvatar extends StatelessWidget {
  final String logo;

  const _CompanyLogoAvatar({required this.logo});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppColors.primaryBg,
      child: const Icon(Icons.store_rounded, color: AppColors.primary),
    );

    Widget image;
    if (logo.isEmpty) {
      image = fallback;
    } else if (logo.startsWith('http') || logo.startsWith('data:')) {
      image = Image.network(
        logo,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (!kIsWeb) {
      image = Image.file(
        File(logo),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      image = fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 52, height: 52, child: image),
    );
  }
}

class _ReceiptPreviewCard extends StatelessWidget {
  final SettingsProvider settings;

  const _ReceiptPreviewCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        boxShadow: AppShadows.cardShadowList,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _CompanyLogoAvatar(logo: settings.companyLogo)),
          const SizedBox(height: 10),
          Text(
            settings.companyName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            settings.companyAddress,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            settings.companyPhone,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _row(settings.tr('order_number'), '#ORD-2023-001'),
          const SizedBox(height: 4),
          _row(settings.tr('order_date'), '14 Oct 2023'),
          const SizedBox(height: 4),
          _row(settings.tr('cashier'), 'John Doe'),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _item('Iced Latte', 2, 25000),
          const SizedBox(height: 6),
          _item('Croissant', 1, 18000),
          const SizedBox(height: 6),
          _item('Mineral Water', 1, 5000),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 8),
          _row(settings.tr('subtotal'), settings.formatCurrency(73000)),
          const SizedBox(height: 4),
          _row(settings.tr('tax'), settings.formatCurrency(7300)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                settings.tr('total'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                settings.formatCurrency(80300),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          if (settings.receiptHeader.isNotEmpty)
            Text(
              settings.receiptHeader,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          if (settings.receiptFooter.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              settings.receiptFooter,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Center(
            child: BarcodeWidget(
              barcode: Barcode.code128(),
              data: 'ORD-2023-001',
              drawText: false,
              width: 200,
              height: 50,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _item(String name, int qty, double price) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            '${qty}x',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          settings.formatCurrency(price * qty),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Export Data Dialog
class _ExportDataDialog extends StatefulWidget {
  final SettingsProvider settings;
  const _ExportDataDialog({required this.settings});

  @override
  State<_ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<_ExportDataDialog> {
  final _provider = ExportImportProvider();
  String _selectedType = 'all';
  ExportFormat _format = ExportFormat.json;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.settings.tr('export_data')),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih data yang akan diekspor:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _buildOption(
              'all',
              'Backup Lengkap',
              'Semua data (direkomendasikan)',
            ),
            _buildOption('products', 'Produk', 'Katalog produk saja'),
            _buildOption('categories', 'Kategori', 'Daftar kategori saja'),
            _buildOption('orders', 'Pesanan', 'Riwayat pesanan'),
            _buildOption('transactions', 'Transaksi', 'Catatan transaksi'),
            const SizedBox(height: 16),
            Text('Format:', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFormatChip(ExportFormat.csv, 'CSV'),
                const SizedBox(width: 8),
                _buildFormatChip(ExportFormat.json, 'JSON'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(widget.settings.tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _doExport,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Ekspor'),
        ),
      ],
    );
  }

  Widget _buildOption(String value, String title, String subtitle) {
    final selected = _selectedType == value;
    return InkWell(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(ExportFormat format, String label) {
    final selected = _format == format;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _format = format),
    );
  }

  Future<void> _doExport() async {
    // If full backup is selected with CSV, warn user that it will be JSON
    if (_selectedType == 'all' && _format == ExportFormat.csv) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Backup Lengkap hanya mendukung format JSON. Otomatis beralih ke JSON.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    setState(() => _isLoading = true);

    switch (_selectedType) {
      case 'all':
        await _provider.exportAllData();
        break;
      case 'products':
        await _provider.exportProducts(_format);
        break;
      case 'categories':
        await _provider.exportCategories(_format);
        break;
      case 'orders':
        await _provider.exportOrders(_format);
        break;
      case 'transactions':
        await _provider.exportTransactions(_format);
        break;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);

    final result = _provider.lastExportResult;
    if (result != null && result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Berhasil mengekspor ${result.recordCount} data'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(result?.errorMessage ?? 'Ekspor gagal')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

// Import Data Dialog
class _ImportDataDialog extends StatefulWidget {
  final SettingsProvider settings;
  const _ImportDataDialog({required this.settings});

  @override
  State<_ImportDataDialog> createState() => _ImportDataDialogState();
}

class _ImportDataDialogState extends State<_ImportDataDialog> {
  final _provider = ExportImportProvider();
  String _selectedType = 'products';
  ExportFormat _format = ExportFormat.csv;
  ImportConflictResolution _resolution = ImportConflictResolution.skip;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.settings.tr('import_data')),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih jenis data:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _buildOption('products', 'Produk', 'Impor katalog produk'),
            _buildOption('categories', 'Kategori', 'Impor daftar kategori'),
            const SizedBox(height: 16),
            Text(
              'Format file:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFormatChip(ExportFormat.csv, 'CSV'),
                const SizedBox(width: 8),
                _buildFormatChip(ExportFormat.json, 'JSON'),
              ],
            ),
            if (_selectedType == 'products') ...[
              const SizedBox(height: 16),
              Text(
                'Jika data sudah ada:',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              _buildResolutionOption(ImportConflictResolution.skip, 'Lewati'),
              _buildResolutionOption(
                ImportConflictResolution.overwrite,
                'Timpa',
              ),
              _buildResolutionOption(
                ImportConflictResolution.createNew,
                'Buat Baru',
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.settings.tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _provider.isLoading ? null : _doImport,
          child: const Text('Pilih File & Impor'),
        ),
      ],
    );
  }

  Widget _buildOption(String value, String title, String subtitle) {
    final selected = _selectedType == value;
    return InkWell(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(ExportFormat format, String label) {
    final selected = _format == format;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _format = format),
    );
  }

  Widget _buildResolutionOption(ImportConflictResolution res, String label) {
    return RadioListTile<ImportConflictResolution>(
      value: res,
      groupValue: _resolution,
      onChanged: (v) => setState(() => _resolution = v!),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _doImport() async {
    Navigator.pop(context);
    if (_selectedType == 'products') {
      await _provider.importProducts(_format, _resolution);
    } else {
      await _provider.importCategories(_format);
    }
    if (!mounted) return;
    final result = _provider.lastImportResult;
    if (result != null) {
      showDialog(
        context: context,
        builder: (_) => ImportResultDialog(result: result),
      );
    }
  }
}
