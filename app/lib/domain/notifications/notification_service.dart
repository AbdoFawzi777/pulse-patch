import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_event.dart';

final notificationServiceProvider =
    NotifierProvider<NotificationServiceNotifier, List<NotificationEvent>>(() {
      return NotificationServiceNotifier();
    });

class NotificationServiceNotifier extends Notifier<List<NotificationEvent>> {
  @override
  List<NotificationEvent> build() {
    // Initial real event logs for verification
    return [
      NotificationEvent.reminderScheduled('08:00 AM'),
      NotificationEvent(
        id: 'init-ready',
        title: 'System Ready',
        message: 'PulsePatch Lite initialized in offline mode.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        category: NotificationCategory.system,
      ),
    ];
  }

  void addEvent(NotificationEvent event) {
    state = [event, ...state];
  }

  void clearAll() {
    state = [];
  }

  void removeEvent(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  Future<bool> checkPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
