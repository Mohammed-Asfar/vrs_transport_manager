import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/app_version.dart';

class UpdateCheckerService {
  final FirebaseFirestore _firestore;

  UpdateCheckerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'app_config';
  static const String _document = 'version';

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      debugPrint('Update check: fetching $_collection/$_document...');
      final doc =
          await _firestore.collection(_collection).doc(_document).get();
      if (!doc.exists) {
        debugPrint('Update check: document does not exist');
        return;
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('Update check: document data is null');
        return;
      }
      debugPrint('Update check: data=$data');

      final latestVersion = data['latest_version'] as String?;
      final downloadUrl = data['download_url'] as String?;
      final releaseNotes = data['release_notes'] as String?;
      final forceUpdate = data['force_update'] as bool? ?? false;

      if (latestVersion == null) {
        debugPrint('Update check: latest_version is null');
        return;
      }

      debugPrint('Update check: latest=$latestVersion current=${AppVersion.currentVersion} newer=${_isNewerVersion(latestVersion, AppVersion.currentVersion)}');

      if (_isNewerVersion(latestVersion, AppVersion.currentVersion)) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            latestVersion: latestVersion,
            downloadUrl: downloadUrl ?? '',
            releaseNotes: releaseNotes,
            forceUpdate: forceUpdate,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts =
        latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts =
        current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (latestParts.length < 3) {
      latestParts.add(0);
    }
    while (currentParts.length < 3) {
      currentParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  void _showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String downloadUrl,
    String? releaseNotes,
    bool forceUpdate = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.separator, width: 0.5),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.system_update_rounded,
                    color: AppColors.accent, size: 24),
              ),
              const SizedBox(height: 16),

              Text('Update Available', style: AppTextStyles.heading2),
              const SizedBox(height: 6),
              Text(
                'A new version of ${AppVersion.appName} is available.',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Version comparison
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.separator, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _versionColumn(
                        'Current', 'v${AppVersion.currentVersion}'),
                    Icon(Icons.arrow_forward_rounded,
                        color: AppColors.textTertiary, size: 18),
                    _versionColumn('New', 'v$latestVersion',
                        isNew: true),
                  ],
                ),
              ),

              // Release notes
              if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("What's New",
                      style: AppTextStyles.label
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.separator, width: 0.5),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      releaseNotes,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  if (!forceUpdate) ...[
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Later'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(downloadUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                          if (context.mounted && !forceUpdate) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.download_rounded,
                            size: 16),
                        label: const Text('Download Update'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _versionColumn(String label, String version,
      {bool isNew = false}) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        Text(
          version,
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.w700,
            color: isNew ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
