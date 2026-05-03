import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/base_scaffold_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/shop_hours_model.dart';
import 'package:handyman_provider_flutter/models/shop_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:nb_utils/nb_utils.dart';

const List<String> _daysOrder = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

String _dayDisplayName(String day) {
  if (day.isEmpty) return day;
  return day[0].toUpperCase() + day.substring(1);
}

TimeOfDay _roundToFiveMinutes(TimeOfDay t) {
  int m = ((t.minute + 2) ~/ 5) * 5;
  if (m >= 60) return TimeOfDay(hour: (t.hour + 1) % 24, minute: 0);
  return TimeOfDay(hour: t.hour, minute: m);
}

String _timeOfDayToHHmm(TimeOfDay t) {
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// Formats a 24-hour "HH:mm" string for display in 12-hour AM/PM format.
String _format24hTo12hDisplay(String time24) {
  if (time24.isEmpty) return '--';
  final t = _parseTime(time24);
  final h = t.hour;
  final m = t.minute;
  const am = 'AM';
  const pm = 'PM';
  final period = h < 12 ? am : pm;
  final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$hour12:${m.toString().padLeft(2, '0')} $period';
}

TimeOfDay _parseTime(String time) {
  if (time.isEmpty) return TimeOfDay(hour: 9, minute: 0);
  final parts = time.split(':');
  if (parts.length < 2) return TimeOfDay(hour: 9, minute: 0);
  final hour = int.tryParse(parts[0]) ?? 9;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
}

class ShopHoursScreen extends StatefulWidget {
  final ShopModel shop;

  const ShopHoursScreen({Key? key, required this.shop}) : super(key: key);

  @override
  State<ShopHoursScreen> createState() => _ShopHoursScreenState();
}

class _ShopHoursScreenState extends State<ShopHoursScreen> {
  late List<ShopDayModel> _days;

  List<ShopDayModel> _defaultDays() => _daysOrder
      .map((d) => ShopDayModel(
            day: d,
            startTime: '09:00',
            endTime: '18:00',
            isHoliday: false,
            breaks: [],
          ))
      .toList();

  @override
  void initState() {
    super.initState();
    _days = _defaultDays();
    init();
  }

  Future<void> init() async {
    appStore.setLoading(true);
    try {
      final list = await getShopHoursList(widget.shop.id);
      if (mounted) {
        setState(() => _days = _mergeWithDefaults(list));
      }
    } catch (e) {
      if (mounted) {
        toast(e.toString());
      }
      // _days already has defaults from initState
    } finally {
      if (mounted) appStore.setLoading(false);
    }
  }

  List<ShopDayModel> _mergeWithDefaults(List<ShopDayModel> fromApi) {
    final byDay = <String, ShopDayModel>{};
    for (final d in fromApi) {
      if (d.day.isNotEmpty) byDay[d.day.toLowerCase()] = d;
    }
    return _daysOrder
        .map((day) =>
            byDay[day] ??
            ShopDayModel(
              day: day,
              startTime: '09:00',
              endTime: '18:00',
              isHoliday: false,
              breaks: [],
            ))
        .toList();
  }

  void _toggleHoliday(int index) {
    setState(() {
      _days[index] = _days[index].copyWith(isHoliday: !_days[index].isHoliday);
    });
  }

  Future<void> _pickTime(
    BuildContext context, {
    required TimeOfDay initial,
    required void Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final rounded = _roundToFiveMinutes(picked);
      onPicked(rounded);
    }
  }

  void _updateStartTime(int dayIndex, TimeOfDay time) {
    setState(() {
      _days[dayIndex] =
          _days[dayIndex].copyWith(startTime: _timeOfDayToHHmm(time));
    });
  }

  void _updateEndTime(int dayIndex, TimeOfDay time) {
    setState(() {
      _days[dayIndex] =
          _days[dayIndex].copyWith(endTime: _timeOfDayToHHmm(time));
    });
  }

  void _addBreak(int dayIndex) {
    setState(() {
      final d = _days[dayIndex];
      final start = d.startTime;
      final end = d.endTime;
      final breaks = List<BreakTimeModel>.from(d.breaks)
        ..add(BreakTimeModel(startBreak: start, endBreak: end));
      _days[dayIndex] = d.copyWith(breaks: breaks);
    });
  }

  void _removeBreak(int dayIndex, int breakIndex) {
    setState(() {
      final d = _days[dayIndex];
      final breaks = List<BreakTimeModel>.from(d.breaks)..removeAt(breakIndex);
      _days[dayIndex] = d.copyWith(breaks: breaks);
    });
  }

  void _updateBreakTime(int dayIndex, int breakIndex,
      {String? startBreak, String? endBreak}) {
    setState(() {
      final d = _days[dayIndex];
      final b = d.breaks[breakIndex];
      final newBreak = b.copyWith(
        startBreak: startBreak ?? b.startBreak,
        endBreak: endBreak ?? b.endBreak,
      );
      final breaks = List<BreakTimeModel>.from(d.breaks)
        ..[breakIndex] = newBreak;
      _days[dayIndex] = d.copyWith(breaks: breaks);
    });
  }

  bool _timeLessThan(String a, String b) {
    final ta = _parseTime(a);
    final tb = _parseTime(b);
    if (ta.hour != tb.hour) return ta.hour < tb.hour;
    return ta.minute < tb.minute;
  }

  String? _validate() {
    for (int i = 0; i < _days.length; i++) {
      final d = _days[i];
      if (d.isHoliday) continue;
      if (_timeLessThan(d.endTime, d.startTime) || d.startTime == d.endTime) {
        return '${_dayDisplayName(d.day)}: ${languages.lblValidationStartTimeBeforeEndTime}';
      }
      for (int j = 0; j < d.breaks.length; j++) {
        final b = d.breaks[j];
        if (_timeLessThan(b.endBreak, b.startBreak) ||
            b.startBreak == b.endBreak) {
          return '${_dayDisplayName(d.day)}: ${languages.lblValidationBreakStartBeforeEnd}';
        }
        if (_timeLessThan(b.startBreak, d.startTime) ||
            _timeLessThan(d.endTime, b.endBreak)) {
          return '${_dayDisplayName(d.day)}: ${languages.lblValidationBreakWithinWorkingHours}';
        }
      }
    }
    return null;
  }

  Future<void> _submitShopHours() async {
    final err = _validate();
    if (err != null) {
      toast(err);
      return;
    }
    if (!await isNetworkAvailable()) {
      toast(languages.internetNotAvailable);
      return;
    }
    appStore.setLoading(true);
    try {
      final request = {
        'shop_hours': _days.map((d) => d.toJson()).toList(),
      };
      await saveShopHours(widget.shop.id, request);
      toast(languages.lblShopHoursSaved);
      if (mounted) finish(context, true);
    } catch (e) {
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: languages.lblBusinessHours,
      body: Stack(
        children: [
          Observer(
            builder: (_) => AbsorbPointer(
              absorbing: appStore.isLoading,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shop.name,
                          style: boldTextStyle(size: 18),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        16.height,
                        ...List.generate(_days.length, (index) {
                          return _DaySection(
                            day: _days[index],
                            dayDisplayName: _dayDisplayName(_days[index].day),
                            isHoliday: _days[index].isHoliday,
                            onToggleHoliday: () => _toggleHoliday(index),
                            onPickStart: () => _pickTime(
                              context,
                              initial: _parseTime(_days[index].startTime),
                              onPicked: (t) => _updateStartTime(index, t),
                            ),
                            onPickEnd: () => _pickTime(
                              context,
                              initial: _parseTime(_days[index].endTime),
                              onPicked: (t) => _updateEndTime(index, t),
                            ),
                            onAddBreak: () => _addBreak(index),
                            onRemoveBreak: (breakIndex) =>
                                _removeBreak(index, breakIndex),
                            onPickBreakStart: (breakIndex) => _pickTime(
                              context,
                              initial: _parseTime(
                                  _days[index].breaks[breakIndex].startBreak),
                              onPicked: (t) => _updateBreakTime(
                                  index, breakIndex,
                                  startBreak: _timeOfDayToHHmm(t)),
                            ),
                            onPickBreakEnd: (breakIndex) => _pickTime(
                              context,
                              initial: _parseTime(
                                  _days[index].breaks[breakIndex].endBreak),
                              onPicked: (t) => _updateBreakTime(
                                  index, breakIndex,
                                  endBreak: _timeOfDayToHHmm(t)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: AppButton(
                      width: context.width(),
                      color: context.primaryColor,
                      child: Text(languages.btnSave,
                          style: boldTextStyle(color: Colors.white)),
                      onTap: _submitShopHours,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Observer(
            builder: (_) => LoaderWidget().center().visible(appStore.isLoading),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final ShopDayModel day;
  final String dayDisplayName;
  final bool isHoliday;
  final VoidCallback onToggleHoliday;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onAddBreak;
  final void Function(int) onRemoveBreak;
  final void Function(int) onPickBreakStart;
  final void Function(int) onPickBreakEnd;

  const _DaySection({
    required this.day,
    required this.dayDisplayName,
    required this.isHoliday,
    required this.onToggleHoliday,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onAddBreak,
    required this.onRemoveBreak,
    required this.onPickBreakStart,
    required this.onPickBreakEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: boxDecorationDefault(color: context.cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(dayDisplayName, style: boldTextStyle(size: 16)),
              ),
              Row(
                children: [
                  Text(languages.lblAddDayOff,
                      style: secondaryTextStyle(size: 12)),
                  8.width,
                  Checkbox(
                    value: isHoliday,
                    onChanged: (_) => onToggleHoliday(),
                    activeColor: context.primaryColor,
                  ),
                ],
              ),
            ],
          ),
          12.height,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(languages.lblStartTime,
                        style: secondaryTextStyle(size: 11)),
                    4.height,
                    InkWell(
                      onTap: isHoliday ? null : onPickStart,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: boxDecorationDefault(
                          color: isHoliday
                              ? context.cardColor.withValues(alpha: 0.5)
                              : context.scaffoldBackgroundColor,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 20, color: context.iconColor),
                            8.width,
                            Text(
                              _format24hTo12hDisplay(day.startTime),
                              style: secondaryTextStyle(size: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(languages.lblEndTime,
                        style: secondaryTextStyle(size: 11)),
                    4.height,
                    InkWell(
                      onTap: isHoliday ? null : onPickEnd,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: boxDecorationDefault(
                          color: isHoliday
                              ? context.cardColor.withValues(alpha: 0.5)
                              : context.scaffoldBackgroundColor,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 20, color: context.iconColor),
                            8.width,
                            Text(
                              _format24hTo12hDisplay(day.endTime),
                              style: secondaryTextStyle(size: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isHoliday) ...[
            8.height,
            Row(
              children: [
                Text(languages.lblBreak, style: boldTextStyle(size: 14))
                    .expand(),
                TextButton.icon(
                  onPressed: onAddBreak,
                  icon: Icon(Icons.add, size: 20, color: context.primaryColor),
                  label: Text(languages.lblAddBreak,
                      style: secondaryTextStyle(color: context.primaryColor)),
                ),
              ],
            ),
            8.height,
            if (day.breaks.isNotEmpty)
              ...List.generate(day.breaks.length, (i) {
                final b = day.breaks[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(languages.lblStartBreak,
                                    style: secondaryTextStyle(size: 11)),
                                4.height,
                                InkWell(
                                  onTap: () => onPickBreakStart(i),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 14),
                                    decoration: boxDecorationDefault(
                                      color: context.scaffoldBackgroundColor,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 20, color: context.iconColor),
                                        8.width,
                                        Text(
                                          _format24hTo12hDisplay(b.startBreak),
                                          style: secondaryTextStyle(size: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          12.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(languages.lblEndBreak,
                                    style: secondaryTextStyle(size: 11)),
                                4.height,
                                InkWell(
                                  onTap: () => onPickBreakEnd(i),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 14),
                                    decoration: boxDecorationDefault(
                                      color: context.scaffoldBackgroundColor,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 20, color: context.iconColor),
                                        8.width,
                                        Text(
                                          _format24hTo12hDisplay(b.endBreak),
                                          style: secondaryTextStyle(size: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: IconButton(
                              icon: Icon(Icons.remove_circle_outline,
                                  size: 20, color: context.primaryColor),
                              onPressed: () => onRemoveBreak(i),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}
