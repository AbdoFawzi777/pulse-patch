/// User-configured notification reminder entity.
class ReminderRecord {
  const ReminderRecord({
    this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.isEnabled,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
  });

  final int? id;
  final int hour;
  final int minute;
  final String label;
  final bool isEnabled;
  final List<int> daysOfWeek;

  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  ReminderRecord copyWith({
    int? id,
    int? hour,
    int? minute,
    String? label,
    bool? isEnabled,
    List<int>? daysOfWeek,
  }) {
    return ReminderRecord(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'label': label,
    'isEnabled': isEnabled,
    'daysOfWeek': daysOfWeek.join(','),
  };

  factory ReminderRecord.fromJson(Map<String, dynamic> json) => ReminderRecord(
    id: json['id'] as int?,
    hour: json['hour'] as int,
    minute: json['minute'] as int,
    label: json['label'] as String,
    isEnabled: json['isEnabled'] as bool,
    daysOfWeek: (json['daysOfWeek'] as String)
        .split(',')
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .toList(),
  );
}
