import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../excel/excel_export_service.dart';
import '../../shared/widgets/glass_snackbar.dart';
import 'change_pin_sheet.dart';

/// Page paramètres (informations app, export Excel).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.showBackButton = true});

  /// Si false (ex. dans MainShellPage avec bottom nav), pas de bouton retour.
  final bool showBackButton;

  Future<void> _exportExcel(BuildContext context) async {
    try {
      final path = await ExcelExportService.instance.exportToFile();
      Rect? sharePositionOrigin;
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
      }
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Export HSE',
        subject: 'Export HSE Offline',
        sharePositionOrigin: sharePositionOrigin,
      );
      if (context.mounted) {
        showGlassSnackBar(context, message: 'Export Excel partagé');
      }
    } catch (e) {
      if (context.mounted) {
        showGlassSnackBar(
          context,
          message: 'Erreur export : ${e.toString().split('\n').first}',
        );
      }
    }
  }

  Widget _iconContainer(BuildContext context, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: theme.colorScheme.primary, size: 22),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _iconContainer(context, icon),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        trailing: onTap != null
            ? Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
                size: 24,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String label, {
    bool isFirst = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 8, top: isFirst ? 8 : 20),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _sectionHeader(context, 'Application', isFirst: true),
          _settingsTile(
            context: context,
            icon: Icons.business_rounded,
            title: 'À propos',
            subtitle: 'SOTASERV - CI SARL - Gestion EPI et incidents',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SOTASERV - CI SARL',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.shield_rounded,
                  color: theme.colorScheme.primary,
                  size: 48,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _settingsTile(
            context: context,
            icon: Icons.lock_rounded,
            title: 'Modifier le code',
            subtitle: 'Changer le code de connexion (4 chiffres)',
            onTap: () => showChangePinSheet(context),
          ),
          _sectionHeader(context, 'Données'),
          _settingsTile(
            context: context,
            icon: Icons.table_chart_rounded,
            title: 'Exporter en Excel',
            subtitle: 'Fichier .xlsx (EPI, mouvements, incidents)',
            onTap: () => _exportExcel(context),
          ),
          const SizedBox(height: 8),
          _settingsTile(
            context: context,
            icon: Icons.dns_rounded,
            title: 'Données locales',
            subtitle: 'SQLite - mode hors ligne',
          ),
          _sectionHeader(context, 'Alertes'),
          _settingsTile(
            context: context,
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Alertes stock critique',
          ),
        ],
      ),
    );
  }
}
