import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/entities/session_record.dart';
import '../../domain/signal/session_recorder.dart';
import '../../shared/widgets/bottom_circle_nav.dart';
import '../device/connect_device_screen.dart';
import '../device/heart_rate_source.dart';
import '../history/measurement_history_screen.dart';
import '../history/session_details_screen.dart';
import '../insights/ai_insights_dashboard_screen.dart';
import '../measurement/live_measurement_screen.dart';
import '../measurement/measurement_complete_screen.dart';
import '../measurement/measurement_preparation_screen.dart';
import '../settings/notifications_center_screen.dart';
import '../settings/profile_preferences_screen.dart';
import 'home_screen.dart';

enum AppView {
  home,
  history,
  insights,
  device,
  measurePrep,
  measureLive,
  measureComplete,
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  AppView _currentView = AppView.home;
  int _navIndex = 0;
  SessionRecorder? _activeRecorder;

  void _navigateToTab(int index) {
    setState(() {
      _navIndex = index;
      switch (index) {
        case 0:
          _currentView = AppView.home;
          break;
        case 1:
          _currentView = AppView.history;
          break;
        case 2:
          _currentView = AppView.insights;
          break;
        case 3:
          _currentView = AppView.device;
          break;
      }
    });
  }

  void _startMeasurementPrep() {
    setState(() => _currentView = AppView.measurePrep);
  }

  void _beginLiveSession(SessionType type, Duration duration) {
    final sessionId = 'sess-${DateTime.now().millisecondsSinceEpoch}';
    final bleSource = ref.read(heartRateSourceProvider);

    _activeRecorder = SessionRecorder(
      sessionId: sessionId,
      sessionType: type,
      targetDuration: duration,
      source: bleSource.isSimulator
          ? SessionSource.simulator
          : bleSource.source,
    );

    setState(() => _currentView = AppView.measureLive);
  }

  void _onSessionComplete(SessionRecorder recorder) {
    setState(() => _currentView = AppView.measureComplete);
  }

  Future<void> _saveSession() async {
    if (_activeRecorder == null) return;
    final recorder = _activeRecorder!;
    final stats = recorder.finalStats;

    final session = SessionRecord(
      id: recorder.sessionId,
      startedAt: recorder.startedAt ?? DateTime.now(),
      endedAt: recorder.endedAt ?? DateTime.now(),
      type: recorder.sessionType,
      qualitySummary: QualitySummary.good,
      appVersion: recorder.appVersion,
      source: recorder.source,
    );

    await ref
        .read(sessionRepositoryProvider)
        .insertSession(
          session: session,
          samples: recorder.samples,
          stats: stats,
        );

    setState(() {
      _activeRecorder = null;
      _currentView = AppView.home;
      _navIndex = 0;
    });
  }

  void _discardSession() {
    _activeRecorder?.dispose();
    _activeRecorder = null;
    setState(() {
      _currentView = AppView.home;
      _navIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bleSource = ref.watch(heartRateSourceProvider);

    Widget body;
    bool showBottomNav = true;

    switch (_currentView) {
      case AppView.home:
        body = HomeScreen(
          onStartMeasure: _startMeasurementPrep,
          onOpenDevice: () => _navigateToTab(3),
          showBottomNav: false,
          onOpenProfile: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfilePreferencesScreen(),
              ),
            );
          },
          onOpenNotifications: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationsCenterScreen(),
              ),
            );
          },
        );
        break;

      case AppView.measurePrep:
        showBottomNav = false;
        body = MeasurementPreparationScreen(
          onStart: _beginLiveSession,
          onBack: () => setState(() => _currentView = AppView.home),
        );
        break;

      case AppView.measureLive:
        showBottomNav = false;
        body = LiveMeasurementScreen(
          recorder: _activeRecorder!,
          source: bleSource,
          onComplete: _onSessionComplete,
          onBack: () => setState(() => _currentView = AppView.home),
        );
        break;

      case AppView.measureComplete:
        showBottomNav = false;
        body = MeasurementCompleteScreen(
          stats: _activeRecorder!.finalStats!,
          onSave: _saveSession,
          onDiscard: _discardSession,
          onViewInsights: () => _navigateToTab(2),
          onBack: () => setState(() => _currentView = AppView.home),
          isSampleData: bleSource.isSimulator,
        );
        break;

      case AppView.history:
        body = MeasurementHistoryScreen(
          onBack: () => setState(() => _currentView = AppView.home),
          showBottomNav: false,
          onSelectSession: (session) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SessionDetailsScreen(
                  session: session,
                  onBack: () => Navigator.of(context).maybePop(),
                  onDeleted: () => Navigator.of(context).maybePop(),
                ),
              ),
            );
          },
        );
        break;

      case AppView.insights:
        body = AiInsightsDashboardScreen(
          onBack: () => setState(() => _currentView = AppView.home),
          showBottomNav: false,
        );
        break;

      case AppView.device:
        body = ConnectDeviceScreen(
          onBack: () => setState(() => _currentView = AppView.home),
          onSelectTab: _navigateToTab,
          showBottomNav: false,
        );
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: body,
      bottomNavigationBar: showBottomNav
          ? BottomCircleNav(currentIndex: _navIndex, onTap: _navigateToTab)
          : null,
    );
  }
}
