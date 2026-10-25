import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/pill_button.dart';

/// Screen managing local SQLite storage transparency, exports, and data deletion.
/// Derived screen #20 adhering strictly to design tokens.
class PrivacyDataManagementScreen extends ConsumerStatefulWidget {
  const PrivacyDataManagementScreen({super.key});

  @override
  ConsumerState<PrivacyDataManagementScreen> createState() =>
      _PrivacyDataManagementScreenState();
}

class _PrivacyDataManagementScreenState
    extends ConsumerState<PrivacyDataManagementScreen> {
  int _sessionCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  void _loadStorageStats() {
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final sessions = repo.getAllSessions();
      setState(() {
        _sessionCount = sessions.length;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportJson() async {
    final repo = ref.read(sessionRepositoryProvider);
    final jsonStr = repo.exportToJson();
    await SharePlus.instance.share(
      ShareParams(text: jsonStr, subject: 'PulsePatch_Database_Export.json'),
    );
  }

  Future<void> _exportCsv() async {
    final repo = ref.read(sessionRepositoryProvider);
    final csvStr = repo.exportToCsv();
    await SharePlus.instance.share(
      ShareParams(text: csvStr, subject: 'PulsePatch_Sessions_Export.csv'),
    );
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmDialog(
        title: 'Erase All Data?',
        message:
            'Permanently delete all recorded pulse sessions, optical samples, computed statistics, and local pattern history?\n\nThis action cannot be undone.',
        confirmLabel: 'Erase Everything',
        isDestructive: true,
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(sessionRepositoryProvider);
      await repo.deleteAllData();
      _loadStorageStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'All local data erased permanently.',
              style: TextStyle(fontFamily: 'Outfit'),
            ),
            backgroundColor: Color(0xFF0F2160),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvasScaffold(
      child: Column(
        children: [
          // Top Bar
          Row(
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Privacy & Data',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 56.0),
            ],
          ),
          const SizedBox(height: 12.0),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Privacy Declaration Hero Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: AppColors.accentCyan,
                              size: 26.0,
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                'Zero Data Leaves This Phone',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.0),
                        Text(
                          'PulsePatch Lite is strictly offline-first. There are no analytics trackers, no cloud sync servers, no advertising IDs, and no third-party telemetry collectors.\n\nAll optical pulse data and local neural network inferences remain in your encrypted local SQLite database.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.5,
                            color: Color(0xFFCBD5E1),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // Database Storage Stats Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.6, -0.8),
                        end: Alignment(0.6, 0.8),
                        colors: [Color(0xFF0F2160), Color(0xFF08122E)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Local Database Metrics',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Recorded Sessions',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              _isLoading ? '...' : '$_sessionCount',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                'Database Engine',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.0),
                            Expanded(
                              flex: 5,
                              child: Text(
                                'SQLite3 (Pure C / FFI)',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.accentCyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                'Network Connections',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.0),
                            Expanded(
                              flex: 5,
                              child: Text(
                                '0 active (Offline)',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.accentPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // Export Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.6, -0.8),
                        end: Alignment(0.6, 0.8),
                        colors: [Color(0xFF0F2160), Color(0xFF08122E)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Export Your Data',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          'Download all sessions, metrics, and raw samples in standard formats.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        Row(
                          children: [
                            Expanded(
                              child: PillButton(
                                label: 'Export JSON',
                                style: PillButtonStyle.white,
                                onPressed: _exportJson,
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: PillButton(
                                label: 'Export CSV',
                                style: PillButtonStyle.dark,
                                onPressed: _exportCsv,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // Destructive Erase Action
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.6, -0.8),
                        end: Alignment(0.6, 0.8),
                        colors: [Color(0xFF451A2E), Color(0xFF1E0818)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              size: 22.0,
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              'Permanent Deletion',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        const Text(
                          'Erase all recorded pulse data, computed baseline metrics, and AI results from this device.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        PillButton(
                          label: 'Erase All Data',
                          style: PillButtonStyle.dark,
                          onPressed: _confirmDeleteAll,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
