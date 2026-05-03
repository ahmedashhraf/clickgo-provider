/// Normalizes API time (HH:mm or HH:mm:ss) to HH:mm for internal storage.
/// Preserves AM/PM format as returned by API (e.g. shop-detail).
String normalizeTimeString(String? value, String fallback) {
  if (value == null || value.isEmpty) return fallback;
  final trimmed = value.trim();
  if (trimmed.toUpperCase().contains('AM') || trimmed.toUpperCase().contains('PM')) return trimmed;
  if (trimmed.length >= 5) return trimmed.substring(0, 5);
  return trimmed.isNotEmpty ? trimmed : fallback;
}

class BreakTimeModel {
  String startBreak;
  String endBreak;

  BreakTimeModel({
    this.startBreak = '12:00',
    this.endBreak = '13:00',
  });

  factory BreakTimeModel.fromJson(Map<String, dynamic> json) {
    return BreakTimeModel(
      startBreak: normalizeTimeString(json['start_break'] as String?, '12:00'),
      endBreak: normalizeTimeString(json['end_break'] as String?, '13:00'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_break': startBreak,
      'end_break': endBreak,
    };
  }

  BreakTimeModel copyWith({String? startBreak, String? endBreak}) {
    return BreakTimeModel(
      startBreak: startBreak ?? this.startBreak,
      endBreak: endBreak ?? this.endBreak,
    );
  }
}

class ShopDayModel {
  String day;
  String startTime;
  String endTime;
  bool isHoliday;
  List<BreakTimeModel> breaks;

  ShopDayModel({
    required this.day,
    this.startTime = '09:00',
    this.endTime = '18:00',
    this.isHoliday = false,
    List<BreakTimeModel>? breaks,
  }) : breaks = breaks ?? [];

  factory ShopDayModel.fromJson(Map<String, dynamic> json) {
    final isHoliday = json['is_holiday'] == true || json['is_holiday'] == 1;
    return ShopDayModel(
      day: json['day'] is String ? (json['day'] as String).toLowerCase() : '',
      startTime: normalizeTimeString(json['start_time'] as String?, '09:00'),
      endTime: normalizeTimeString(json['end_time'] as String?, '18:00'),
      isHoliday: isHoliday,
      breaks: json['breaks'] is List
          ? (json['breaks'] as List).map((e) => BreakTimeModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'start_time': startTime,
      'end_time': endTime,
      'is_holiday': isHoliday,
      'breaks': breaks.map((e) => e.toJson()).toList(),
    };
  }

  ShopDayModel copyWith({
    String? day,
    String? startTime,
    String? endTime,
    bool? isHoliday,
    List<BreakTimeModel>? breaks,
  }) {
    return ShopDayModel(
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isHoliday: isHoliday ?? this.isHoliday,
      breaks: breaks ?? List<BreakTimeModel>.from(this.breaks),
    );
  }
}
