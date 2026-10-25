enum NotificationCategory { measurement, device, system, reminder }

/// Represents a genuine, verified telemetry or device event.
/// No fake notifications or unsolicited marketing pings.
class NotificationEvent {
  const NotificationEvent({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    this.sessionId,
  });

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationCategory category;
  final String? sessionId;

  factory NotificationEvent.deviceConnected(String deviceName) =>
      NotificationEvent(
        id: 'dev-conn-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Sensor Connected',
        message: '$deviceName is paired and ready for telemetry.',
        timestamp: DateTime.now(),
        category: NotificationCategory.device,
      );

  factory NotificationEvent.deviceDisconnected() => NotificationEvent(
    id: 'dev-disc-${DateTime.now().millisecondsSinceEpoch}',
    title: 'Sensor Disconnected',
    message: 'PulsePatch BLE connection closed.',
    timestamp: DateTime.now(),
    category: NotificationCategory.device,
  );

  factory NotificationEvent.measurementCompleted(
    String sessionId,
    int bpm,
    int durationSeconds,
  ) => NotificationEvent(
    id: 'meas-comp-$sessionId',
    title: 'Measurement Saved',
    message: 'Recorded ${durationSeconds}s session: $bpm BPM average.',
    timestamp: DateTime.now(),
    category: NotificationCategory.measurement,
    sessionId: sessionId,
  );

  factory NotificationEvent.qualityWarning() => NotificationEvent(
    id: 'qual-warn-${DateTime.now().millisecondsSinceEpoch}',
    title: 'Data Quality Warning',
    message:
        'Optical signal dropped below quality threshold. Ensure steady fingertip contact.',
    timestamp: DateTime.now(),
    category: NotificationCategory.measurement,
  );

  factory NotificationEvent.aiAnalysisFinished(
    String sessionId,
    String label,
  ) => NotificationEvent(
    id: 'ai-finish-$sessionId',
    title: 'Pattern Analysis Ready',
    message: 'On-device neural network classified session as "$label".',
    timestamp: DateTime.now(),
    category: NotificationCategory.system,
    sessionId: sessionId,
  );

  factory NotificationEvent.reminderScheduled(String time) => NotificationEvent(
    id: 'rem-sched-${DateTime.now().millisecondsSinceEpoch}',
    title: 'Measurement Reminder',
    message: 'Scheduled check-in reminder set for $time.',
    timestamp: DateTime.now(),
    category: NotificationCategory.reminder,
  );
}
