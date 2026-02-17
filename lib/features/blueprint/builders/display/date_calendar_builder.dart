import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/models/entry.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../engine/entry_filter.dart';
import '../../renderer/render_context.dart';

/// Renders an interactive monthly calendar view that highlights days with entries and shows entry details on tap.
///
/// Blueprint JSON:
/// ```json
/// {"type": "date_calendar", "dateField": "date"}
/// ```
///
/// - `dateField` (`String`, optional): The entry field key containing date values. Defaults to `"date"`.
/// - `filter` (`dynamic`, optional): Entry filter to scope which entries appear on the calendar.
Widget buildDateCalendar(BlueprintNode node, RenderContext ctx) {
  final calendar = node as DateCalendarNode;
  return _DateCalendarWidget(calendar: calendar, ctx: ctx);
}

class _DateCalendarWidget extends StatefulWidget {
  final DateCalendarNode calendar;
  final RenderContext ctx;

  const _DateCalendarWidget({required this.calendar, required this.ctx});

  @override
  State<_DateCalendarWidget> createState() => _DateCalendarWidgetState();
}

class _DateCalendarWidgetState extends State<_DateCalendarWidget> {
  late DateTime _displayedMonth;
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
  }

  List<Entry> get _filteredEntries {
    return EntryFilter.filter(
      widget.ctx.entries,
      widget.calendar.filter,
      widget.ctx.screenParams,
    ).entries;
  }

  Set<int> _datesWithEntries() {
    final dateField = widget.calendar.dateField;
    final dates = <int>{};
    for (final entry in _filteredEntries) {
      final dateStr = entry.data[dateField] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      if (date.year == _displayedMonth.year &&
          date.month == _displayedMonth.month) {
        dates.add(date.day);
      }
    }
    return dates;
  }

  List<Entry> _entriesForSelectedDay() {
    if (_selectedDay == null) return [];
    final dateField = widget.calendar.dateField;
    final targetDate = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      _selectedDay!,
    );

    return _filteredEntries.where((entry) {
      final dateStr = entry.data[dateField] as String?;
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;
      return date.year == targetDate.year &&
          date.month == targetDate.month &&
          date.day == targetDate.day;
    }).toList();
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
      _selectedDay = null;
    });
  }

  void _onDayTap(int day) {
    setState(() {
      _selectedDay = _selectedDay == day ? null : day;
    });
  }

  String? _formatDisplayValue(String? value) {
    if (value == null) return null;
    // Try parsing as ISO date
    final date = DateTime.tryParse(value);
    if (date != null) {
      if (date.hour == 0 && date.minute == 0 && date.second == 0) {
        return DateFormat.yMMMd().format(date);
      }
      return DateFormat.yMMMd().add_jm().format(date);
    }
    // Try parsing as time-only (HH:mm)
    final timeMatch = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, hour, minute);
      return DateFormat.jm().format(dt);
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final datesWithData = _datesWithEntries();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday;

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final selectedEntries = _entriesForSelectedDay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(
                PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                color: colors.onBackground,
                size: 20,
              ),
            ),
            Text(
              '${monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.onBackground,
              ),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                color: colors.onBackground,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Day-of-week headers
        Row(
          children: dayLabels.map((label) {
            return Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onBackgroundMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Day grid
        _buildDayGrid(
          colors: colors,
          today: today,
          daysInMonth: daysInMonth,
          startWeekday: startWeekday,
          datesWithData: datesWithData,
        ),

        // Selected day entries
        if (_selectedDay != null) ...[
          const SizedBox(height: AppSpacing.md),
          if (selectedEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No entries on this day',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 13,
                  color: colors.onBackgroundMuted,
                ),
              ),
            )
          else
            ...selectedEntries.map((entry) {
              final name = _formatDisplayValue(
                    entry.data['name']?.toString(),
                  ) ??
                  _formatDisplayValue(
                    entry.data['description']?.toString(),
                  ) ??
                  entry.data['activityType']?.toString() ??
                  'Entry';
              final sub = entry.data['location']?.toString() ??
                  entry.data['category']?.toString() ??
                  entry.data['entryType']?.toString() ??
                  '';

              final onEntryTap = widget.calendar.onEntryTap;

              return GestureDetector(
                onTap: onEntryTap != null
                    ? () {
                        final screen = onEntryTap['screen'] as String?;
                        if (screen == null) return;
                        final params = <String, dynamic>{};
                        if (entry.id.isNotEmpty) {
                          params['_entryId'] = entry.id;
                        }
                        for (final key in widget.calendar.forwardFields) {
                          if (entry.data.containsKey(key)) {
                            params[key] = entry.data[key];
                          }
                        }
                        widget.ctx.onNavigateToScreen(screen, params: params);
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontFamily: 'Karla',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: colors.onBackground,
                              ),
                            ),
                            if (sub.isNotEmpty)
                              Text(
                                sub,
                                style: TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 13,
                                  color: colors.onBackgroundMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (onEntryTap != null)
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: colors.onBackgroundMuted,
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ],
    );
  }

  Widget _buildDayGrid({
    required dynamic colors,
    required DateTime today,
    required int daysInMonth,
    required int startWeekday,
    required Set<int> datesWithData,
  }) {
    final rows = <Widget>[];
    var dayCounter = 1;
    final offset = startWeekday - 1;

    for (var week = 0; week < 6; week++) {
      if (dayCounter > daysInMonth) break;

      final cells = <Widget>[];
      for (var col = 0; col < 7; col++) {
        final cellIndex = week * 7 + col;
        if (cellIndex < offset || dayCounter > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 44)));
          continue;
        }

        final day = dayCounter;
        final isToday = _displayedMonth.year == today.year &&
            _displayedMonth.month == today.month &&
            day == today.day;
        final isSelected = _selectedDay == day;
        final hasData = datesWithData.contains(day);

        cells.add(
          Expanded(
            child: GestureDetector(
              onTap: () => _onDayTap(day),
              child: SizedBox(
                height: 44,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: isSelected
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.accent.withValues(alpha: 0.2),
                              border: Border.all(
                                color: colors.accent,
                                width: 1.5,
                              ),
                            )
                          : isToday
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.accent,
                                )
                              : null,
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 14,
                          fontWeight:
                              (isToday || isSelected) ? FontWeight.w700 : FontWeight.w400,
                          color: isToday && !isSelected
                              ? Colors.white
                              : isSelected
                                  ? colors.accent
                                  : colors.onBackground,
                        ),
                      ),
                    ),
                    if (hasData && !isSelected)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.accent,
                        ),
                      )
                    else
                      const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
          ),
        );
        dayCounter++;
      }

      rows.add(Row(children: cells));
    }

    return Column(children: rows);
  }
}
