import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/cloud/cloud_auth_service.dart';
import '../../domain/cloud/sync_queue_service.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';

class CloudSyncScreen extends ConsumerStatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  ConsumerState<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends ConsumerState<CloudSyncScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSignInDialog(bool isRtl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isRtl ? 'تسجيل الدخول للمزامنة السحابية' : 'Cloud Connect Sign In',
          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: isRtl ? 'البريد الإلكتروني' : 'Email Address',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.canvasDarkNavy,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: isRtl ? 'كلمة المرور' : 'Password',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.canvasDarkNavy,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isRtl ? 'إلغاء' : 'Cancel', style: const TextStyle(color: AppColors.textSecondary)),
          ),
          PillButton(
            label: isRtl ? 'اتصال' : 'Connect',
            style: PillButtonStyle.white,
            height: 40.0,
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = ref.read(cloudAuthServiceProvider);
              await auth.signInWithEmail(
                _emailController.text.trim().isEmpty ? 'patient@pulsepatch.health' : _emailController.text.trim(),
                _passwordController.text,
              );
              await ref.read(syncQueueServiceProvider).processQueue();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final syncQueueService = ref.watch(syncQueueServiceProvider);
    final syncStateAsync = ref.watch(syncStateStreamProvider);
    final syncState = syncStateAsync.value ?? syncQueueService.currentState;
    final auth = ref.watch(cloudAuthServiceProvider);
    final user = auth.currentUser;
    final isGuest = user == null || user.isGuest;

    Color badgeColor = AppColors.textSecondary;
    IconData badgeIcon = Icons.offline_pin_rounded;
    switch (syncState.status) {
      case SyncStatus.synced:
        badgeColor = AppColors.accentGreen;
        badgeIcon = Icons.cloud_done_rounded;
        break;
      case SyncStatus.syncing:
        badgeColor = AppColors.accentCyan;
        badgeIcon = Icons.sync_rounded;
        break;
      case SyncStatus.offlineQueued:
        badgeColor = AppColors.statusAmber;
        badgeIcon = Icons.cloud_queue_rounded;
        break;
      case SyncStatus.error:
        badgeColor = AppColors.statusRed;
        badgeIcon = Icons.cloud_off_rounded;
        break;
      case SyncStatus.localOnly:
        badgeColor = AppColors.textSecondary;
        badgeIcon = Icons.offline_pin_rounded;
        break;
    }

    return DesignCanvasScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    isRtl ? 'المزامنة السحابية والنسخ الاحتياطي' : 'Cloud Sync & Backup',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48.0),
            ],
          ),
          const SizedBox(height: 16.0),

          // Main Scrollable Area
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Sync Status Hero Card
                MetricCard(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badgeColor.withValues(alpha: 0.15),
                          border: Border.all(color: badgeColor, width: 2),
                        ),
                        child: Icon(badgeIcon, color: badgeColor, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isRtl ? syncState.status.labelAr : syncState.status.labelEn,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isGuest
                            ? (isRtl
                                ? 'وضع الزائر النشط: بياناتك محفوظة 100% على هذا الهاتف فقط ولا تخرج للإنترنت.'
                                : 'Active Guest Mode: All biometric records remain 100% local on this device.')
                            : (isRtl
                                ? 'الحساب: ${user.email ?? user.displayName}\nالمعرف: ${user.uid}'
                                : 'Account: ${user.email ?? user.displayName}\nUID: ${user.uid}'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (syncState.pendingCount > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.statusAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isRtl
                                ? '${syncState.pendingCount} عناصر في قائمة الانتظار'
                                : '${syncState.pendingCount} pending records in outbox',
                            style: const TextStyle(
                              color: AppColors.statusAmber,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PillButton(
                            label: isRtl ? 'مزامنة فورية' : 'Sync Now',
                            style: PillButtonStyle.white,
                            height: 42.0,
                            onPressed: () => ref.read(syncQueueServiceProvider).processQueue(),
                          ),
                          const SizedBox(width: 12),
                          if (isGuest)
                            PillButton(
                              label: isRtl ? 'ربط حساب' : 'Connect Cloud',
                              style: PillButtonStyle.dark,
                              height: 42.0,
                              onPressed: () => _showSignInDialog(isRtl),
                            )
                          else
                            PillButton(
                              label: isRtl ? 'تسجيل الخروج' : 'Sign Out',
                              style: PillButtonStyle.dark,
                              height: 42.0,
                              onPressed: () async {
                                await auth.signOut();
                                await ref.read(syncQueueServiceProvider).processQueue();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Architecture & Security Info
                MetricCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security_rounded, color: AppColors.accentCyan, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isRtl ? 'أمان وخصوصية البيانات الطبية' : 'Data Privacy & Cloud Security',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRtl
                            ? '• قواعد أمان صارمة (Firestore Security Rules): لا يمكن لأي مستخدم آخر قراءة أو كتابة جلساتك.\n'
                                '• مسار البيانات المنفصل: users/{userId}/sessions/{sessionId}.\n'
                                '• التخزين السحابي للتقارير مشفر (Cloud Storage).\n'
                                '• المعمارية غير متصلة أولاً (Offline-First): SQLite هو المرجع الأساسي المستمر.'
                            : '• Strict Firestore Security Rules: Only authenticated user UID can access personal records.\n'
                                '• Isolated Document Path: users/{userId}/sessions/{sessionId}.\n'
                                '• Encrypted PDF storage via Google Cloud Storage.\n'
                                '• Offline-first SQLite persistence guarantees zero data loss during network disruptions.',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
