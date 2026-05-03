import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';

/// user for DateTime formatting
import 'package:intl/intl.dart';

/// `const CustomCalendar({
///   Key? key,
///   this.initialStartDate,
///   this.initialEndDate,
///   this.startEndDateChange,
///   this.minimumDate,
///   this.maximumDate,
///   required this.primaryColor,
/// })`
class CustomCalendar extends StatefulWidget {
  /// The minimum date that can be selected on the calendar
  final DateTime? minimumDate;

  /// The maximum date that can be selected on the calendar
  final DateTime? maximumDate;

  /// The initial start date to be shown on the calendar
  final DateTime? initialStartDate;

  /// The initial end date to be shown on the calendar
  final DateTime? initialEndDate;

  /// The primary color to be used in the calendar's color scheme
  final Color primaryColor;

  /// A function to be called when the selected date range changes
  final Function(DateTime, DateTime)? startEndDateChange;

  const CustomCalendar({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    this.startEndDateChange,
    this.minimumDate,
    this.maximumDate,
    required this.primaryColor,
    required Color disabledDateColor,
  }) : super(key: key);

  @override
  CustomCalendarState createState() => CustomCalendarState();
}

class CustomCalendarState extends State<CustomCalendar> {
  List<DateTime> dateList = <DateTime>[];

  DateTime currentMonthDate = DateTime.now();

  DateTime? startDate;

  DateTime? endDate;

  DateTime? selectedDate;

  @override
  void initState() {
    setListOfDate(currentMonthDate);
    if (widget.initialStartDate != null) {
      startDate = widget.initialStartDate;
    }
    if (widget.initialEndDate != null) {
      endDate = widget.initialEndDate;
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void setListOfDate(DateTime monthDate) {
    dateList.clear();
    final DateTime newDate = DateTime(monthDate.year, monthDate.month, 0);
    int previousMothDay = 0;
    if (newDate.weekday < 7) {
      previousMothDay = newDate.weekday;
      for (int i = 1; i <= previousMothDay; i++) {
        dateList.add(newDate.subtract(Duration(days: previousMothDay - i)));
      }
    }
    for (int i = 0; i < (42 - previousMothDay); i++) {
      dateList.add(newDate.add(Duration(days: i + 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
            top: 4,
            bottom: 4,
          ),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(24.0)),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(24.0)),
                      onTap: () {
                        setState(() {
                          currentMonthDate = DateTime(
                            currentMonthDate.year,
                            currentMonthDate.month - 1,
                          );
                          setListOfDate(currentMonthDate);
                        });
                      },
                      child: const Icon(
                        Icons.keyboard_arrow_left,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM, yyyy', appStore.selectedLanguageCode)
                        .format(currentMonthDate),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(24.0)),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(24.0)),
                      onTap: () {
                        setState(() {
                          currentMonthDate = DateTime(
                            currentMonthDate.year,
                            currentMonthDate.month + 2,
                            0,
                          );
                          setListOfDate(currentMonthDate);
                        });
                      },
                      child: const Icon(
                        Icons.keyboard_arrow_right,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, left: 8, bottom: 8),
          child: Row(
            children: getDaysNameUI(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, left: 8),
          child: Column(
            children: getDaysNoUI(),
          ),
        ),
      ],
    );
  }

  bool get isRtl =>
      appStore.selectedLanguageCode == 'ar' ||
      appStore.selectedLanguageCode == 'he' ||
      appStore.selectedLanguageCode == 'fa' ||
      appStore.selectedLanguageCode == 'ur';

  List<Widget> getDaysNameUI() {
    final List<Widget> listUI = <Widget>[];
    for (int i = 0; i < 7; i++) {
      listUI.add(
        Expanded(
          child: Center(
            child: Text(
              DateFormat('EEE', appStore.selectedLanguageCode)
                  .format(dateList[i]),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.primaryColor,
              ),
            ),
          ),
        ),
      );
    }
    return listUI;
  }

  List<Widget> getDaysNoUI() {
    final List<Widget> noList = <Widget>[];
    int count = 0;
    for (int i = 0; i < dateList.length / 7; i++) {
      final List<Widget> listUI = <Widget>[];
      for (int i = 0; i < 7; i++) {
        final DateTime date = dateList[count];
        listUI.add(
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.0,
              // Builder gives us a context with the correct Directionality so we
              // can resolve RTL once and use it for both the pill padding and the
              // pill border-radius — keeping them perfectly in sync.
              child: Builder(
                builder: (cellContext) {
                  // isRtl resolved from state context via the getter above

                  // Which visual edge of the row needs a rounded cap on the pill?
                  //   LTR: left-cap  → start date / first column (Mon, weekday 1)
                  //         right-cap → end date   / last column  (Sun, weekday 7)
                  //   RTL: left-cap  → end date   / last visual column  (Sun, weekday 7)
                  //         right-cap → start date / first visual column (Mon, weekday 1)
                  final bool roundLeft =
                      isRtl ? isEndDateRadius(date) : isStartDateRadius(date);
                  final bool roundRight =
                      isRtl ? isStartDateRadius(date) : isEndDateRadius(date);

                  return Stack(
                    children: <Widget>[
                      // ── Range highlight pill ──────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 3),
                        child: Material(
                          color: Colors.transparent,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: 2,
                              bottom: 2,
                              left: roundLeft ? 4 : 0,
                              right: roundRight ? 4 : 0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: startDate != null && endDate != null
                                    ? getIsItStartAndEndDate(date) ||
                                            getIsInRange(date)
                                        ? widget.primaryColor
                                            .withValues(alpha: 0.4)
                                        : Colors.transparent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.only(
                                  topLeft: roundLeft
                                      ? const Radius.circular(24.0)
                                      : Radius.zero,
                                  bottomLeft: roundLeft
                                      ? const Radius.circular(24.0)
                                      : Radius.zero,
                                  topRight: roundRight
                                      ? const Radius.circular(24.0)
                                      : Radius.zero,
                                  bottomRight: roundRight
                                      ? const Radius.circular(24.0)
                                      : Radius.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ── Day number circle ─────────────────────────────────
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(32.0)),
                          onTap: () {
                            if (widget.minimumDate != null &&
                                widget.maximumDate != null) {
                              final DateTime newMinimumDate = widget
                                  .minimumDate!
                                  .subtract(const Duration(days: 1));
                              final DateTime newMaximumDate = widget
                                  .maximumDate!
                                  .add(const Duration(days: 1));
                              if (date.isAfter(newMinimumDate) &&
                                  date.isBefore(newMaximumDate)) {
                                onDateClick(date);
                              }
                            } else if (widget.minimumDate != null) {
                              final DateTime newMinimumDate = widget
                                  .minimumDate!
                                  .subtract(const Duration(days: 1));
                              if (date.isAfter(newMinimumDate)) {
                                onDateClick(date);
                              }
                            } else if (widget.maximumDate != null) {
                              final DateTime newMaximumDate = widget
                                  .maximumDate!
                                  .add(const Duration(days: 1));
                              if (date.isBefore(newMaximumDate)) {
                                onDateClick(date);
                              }
                            } else {
                              // No limit, allow any future or past date selection
                              onDateClick(date);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              decoration: BoxDecoration(
                                color: getIsItStartAndEndDate(date)
                                    ? widget.primaryColor
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(32.0)),
                                border: Border.all(
                                  color: getIsItStartAndEndDate(date)
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: getIsItStartAndEndDate(date)
                                    ? <BoxShadow>[
                                        BoxShadow(
                                          color: Colors.grey
                                              .withValues(alpha: 0.6),
                                          blurRadius: 4,
                                          offset: const Offset(0, 0),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: getIsItStartAndEndDate(date)
                                        ? Colors.white
                                        : date.isBefore(DateTime.now().subtract(
                                                const Duration(days: 1)))
                                            ? Colors.grey
                                            : (date == selectedDate)
                                                ? Colors.white
                                                : widget.primaryColor,
                                    fontSize:
                                        MediaQuery.of(cellContext).size.width >
                                                360
                                            ? 18
                                            : 16,
                                    fontWeight: date == selectedDate ||
                                            getIsItStartAndEndDate(date)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ── Today dot ─────────────────────────────────────────
                      Positioned(
                        bottom: 9,
                        right: 0,
                        left: 0,
                        child: Container(
                          height: 6,
                          width: 6,
                          decoration: BoxDecoration(
                            color: DateTime.now().day == date.day &&
                                    DateTime.now().month == date.month &&
                                    DateTime.now().year == date.year
                                ? getIsInRange(date)
                                    ? Colors.white
                                    : widget.primaryColor
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        count += 1;
      }
      noList.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: listUI,
        ),
      );
    }
    return noList;
  }

  bool getIsInRange(DateTime date) {
    if (startDate != null && endDate != null) {
      if (date.isAfter(startDate!) && date.isBefore(endDate!)) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  bool getIsItStartAndEndDate(DateTime date) {
    if (startDate != null &&
        startDate!.day == date.day &&
        startDate!.month == date.month &&
        startDate!.year == date.year) {
      return true;
    } else if (endDate != null &&
        endDate!.day == date.day &&
        endDate!.month == date.month &&
        endDate!.year == date.year) {
      return true;
    } else {
      return false;
    }
  }

  /// True when the START cap of the range pill should apply to this date.
  /// "Start cap" = the date is the startDate, OR it sits in the first column
  /// of the row (Monday, weekday 1).  The Builder in getDaysNoUI swaps left/right
  /// for RTL, so these helpers never need to know the text direction.
  bool isStartDateRadius(DateTime date) {
    if (startDate != null &&
        startDate!.day == date.day &&
        startDate!.month == date.month) {
      return true;
    }
    // Monday is the first column (index 0) in the Mon–Sun week grid.
    if (date.weekday == DateTime.monday) return true;
    return false;
  }

  /// True when the END cap of the range pill should apply to this date.
  /// "End cap" = the date is the endDate, OR it sits in the last column
  /// of the row (Sunday, weekday 7).
  bool isEndDateRadius(DateTime date) {
    if (endDate != null &&
        endDate!.day == date.day &&
        endDate!.month == date.month) {
      return true;
    }
    // Sunday is the last column (index 6) in the Mon–Sun week grid.
    if (date.weekday == DateTime.sunday) return true;
    return false;
  }

  void onDateClick(DateTime date) {
    if (startDate == null) {
      startDate = date;
    } else if (startDate != date && endDate == null) {
      endDate = date;
    } else if (startDate!.day == date.day && startDate!.month == date.month) {
      startDate = null;
    } else if (endDate!.day == date.day && endDate!.month == date.month) {
      endDate = null;
    }
    if (startDate == null && endDate != null) {
      startDate = endDate;
      endDate = null;
    }
    if (startDate != null && endDate != null) {
      if (!endDate!.isAfter(startDate!)) {
        final DateTime d = startDate!;
        startDate = endDate;
        endDate = d;
      }
      if (date.isBefore(startDate!)) {
        startDate = date;
      }
      if (date.isAfter(endDate!)) {
        endDate = date;
      }
    }
    setState(() {
      try {
        widget.startEndDateChange!(startDate!, endDate!);
      } catch (_) {}
    });
  }
}
