import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/global/status.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentCalendarView extends StatefulWidget {
  /// Counts of appointments per date (ISO date string -> count) for the visible month.
  final Map<String, int> appointmentCounts;

  /// Full appointment data for the currently selected day (fetched on demand).
  final List<Data> dayAppointments;

  /// Called when the user navigates to a new month.
  final void Function(DateTime firstOfMonth, DateTime lastOfMonth)? onMonthChanged;

  /// Called when the user taps a day — triggers a fetch for that day's appointments.
  final void Function(DateTime day)? onDaySelected;

  /// Whether data for the selected day is currently loading.
  final bool isLoadingDay;

  final VoidCallback? onRefresh;

  const AppointmentCalendarView({
    super.key,
    required this.appointmentCounts,
    this.dayAppointments = const [],
    this.onMonthChanged,
    this.onDaySelected,
    this.isLoadingDay = false,
    this.onRefresh,
  });

  @override
  State<AppointmentCalendarView> createState() => _AppointmentCalendarViewState();
}

class _AppointmentCalendarViewState extends State<AppointmentCalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  void _notifyMonthChanged() {
    final first = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final last = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    widget.onMonthChanged?.call(first, last);
  }

  @override
  Widget build(BuildContext context) {
    if (isMobile || isTablet) {
      return Column(
        children: [
          SizedBox(height: screenHeight(45), child: _buildCalendar()),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(child: _buildDayPanel()),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildCalendar()),
        const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
        Expanded(flex: 3, child: _buildDayPanel()),
      ],
    );
  }

  // ── Calendar ──────────────────────────────────────────────────────────

  Widget _buildCalendar() {
    return Container(
      color: Colors.white,
      child: TableCalendar(
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
          widget.onDaySelected?.call(selected);
        },
        onPageChanged: (focused) {
          _focusedDay = focused;
          _notifyMonthChanged();
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleTextFormatter: (date, locale) => DateFormat('MMMM yyyy').format(date),
          titleTextStyle: AppTypography.bodyLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
          formatButtonTextStyle: AppTypography.bodyMedium(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          formatButtonDecoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(8)),
          leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF6B7280)),
          rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B7280)),
          headerPadding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        ),
        calendarBuilders: CalendarBuilders(prioritizedBuilder: (context, date, focusedDay) => _buildDayCell(date)),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: secondaryColor.withAlpha(40), shape: BoxShape.circle),
          todayTextStyle: AppTypography.bodyMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w700, color: secondaryColor),
          cellMargin: const EdgeInsets.all(2),
          defaultTextStyle: AppTypography.bodyMedium(context).copyWith(color: const Color(0xFF374151), fontSize: 12),
          weekendTextStyle: AppTypography.bodyMedium(context).copyWith(color: const Color(0xFF9CA3AF), fontSize: 12),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: AppTypography.bodyMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF6B7280), fontSize: 11),
          weekendStyle: AppTypography.bodyMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF), fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isSelected = isSameDay(date, _selectedDay);
    final isToday = isSameDay(date, DateTime.now());
    final isOutsideMonth = date.month != _focusedDay.month;
    final key = DateFormat('yyyy-MM-dd').format(date);
    final count = widget.appointmentCounts[key] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F5FF) : null,
        border: isSelected ? Border.all(color: secondaryColor.withAlpha(80), width: 1) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: isToday ? const BoxDecoration(color: secondaryColor, shape: BoxShape.circle) : null,
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday
                    ? Colors.white
                    : isOutsideMonth
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF374151),
              ),
            ),
          ),
          if (count > 0)
            Container(
              width: count > 9 ? null : 18,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: secondaryColor.withAlpha(30), borderRadius: BorderRadius.circular(9)),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: secondaryColor),
                textAlign: TextAlign.center,
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Day panel ─────────────────────────────────────────────────────────

  Widget _buildDayPanel() {
    return Column(
      children: [
        _buildDaySummary(),
        Expanded(child: _buildDayAppointments()),
      ],
    );
  }

  Widget _buildDaySummary() {
    final now = DateTime.now();
    final isToday = isSameDay(_selectedDay, now);

    String label;
    if (isToday) {
      label = 'Today';
    } else {
      final tomorrow = now.add(const Duration(days: 1));
      if (isSameDay(_selectedDay, tomorrow)) {
        label = 'Tomorrow';
      } else {
        label = DateFormat('EEEE, d MMM yyyy').format(_selectedDay);
      }
    }

    final count = widget.dayAppointments.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
      child: Row(
        children: [
          Icon(isToday ? Icons.today_rounded : Icons.calendar_today_rounded, size: 16, color: secondaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: secondaryColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: Text(
              '$count appointment${count == 1 ? '' : 's'}',
              style: AppTypography.bodyMedium(
                context,
              ).copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayAppointments() {
    if (widget.isLoadingDay) {
      return const Center(child: CircularProgressIndicator(color: secondaryColor));
    }

    final list = widget.dayAppointments;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
              child: const Icon(Icons.event_busy_rounded, size: 28, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 12),
            Text(
              'No appointments on this day',
              style: AppTypography.bodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    final sorted = List<Data>.from(list);
    sorted.sort((a, b) {
      final aDt = DateTime.tryParse(a.appointmentDatetime ?? '') ?? DateTime(2000);
      final bDt = DateTime.tryParse(b.appointmentDatetime ?? '') ?? DateTime(2000);
      return aDt.compareTo(bDt);
    });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildAppointmentCard(context, sorted[index]),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Data apt) {
    final raw = convertUtcToMalaysiaTimeRange(apt.appointmentDatetime, apt.service?.serviceTime);
    final timeLabel = raw != null && raw.contains('\n') ? raw.split('\n')[1] : '—';
    final statusColor = appointmentStatusColors[apt.appointmentStatus] ?? Colors.grey;
    final initials = (apt.user?.userFullName ?? '')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openDetail(context, apt),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeLabel,
                      style: AppTypography.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF111827)),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                      color: const Color(0xFFE5E7EB),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 3,
                height: 48,
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: statusColor.withAlpha(25),
                      child: Text(
                        initials,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apt.user?.userFullName?.titleCase() ?? 'N/A',
                            style: AppTypography.bodyMedium(
                              context,
                            ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            apt.service?.serviceName ?? 'N/A',
                            style: AppTypography.bodyMedium(
                              context,
                            ).apply(fontSizeDelta: -2, color: const Color(0xFF6B7280)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppointmentStatusBadge(
                    status: apt.appointmentStatus,
                    fontSize: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Data apt) {
    showDialog(
      context: context,
      builder: (ctx) => AppointmentDetails(type: 'update', appointment: apt, tabs: [], refreshData: widget.onRefresh),
    );
  }
}
