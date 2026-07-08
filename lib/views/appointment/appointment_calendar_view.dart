import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/global/status.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentCalendarView extends StatefulWidget {
  final List<Data> appointments;
  final List<String>? currentTabs;
  final bool isSideBySide;
  final VoidCallback? onToggleLayout;
  final VoidCallback? onRefresh;

  const AppointmentCalendarView({
    super.key,
    required this.appointments,
    this.currentTabs,
    this.isSideBySide = false,
    this.onToggleLayout,
    this.onRefresh,
  });

  @override
  State<AppointmentCalendarView> createState() => _AppointmentCalendarViewState();
}

class _AppointmentCalendarViewState extends State<AppointmentCalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Data>> _grouped = {};
  static const int _maxChipsPerCell = 3;

  @override
  void initState() {
    super.initState();
    _groupByDate();
  }

  @override
  void didUpdateWidget(AppointmentCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appointments != widget.appointments) {
      _groupByDate();
    }
  }

  void _groupByDate() {
    final map = <DateTime, List<Data>>{};
    for (final apt in widget.appointments) {
      if (apt.appointmentDatetime == null) continue;
      try {
        final dt = DateTime.parse(apt.appointmentDatetime!);
        final day = DateTime(dt.year, dt.month, dt.day);
        map.putIfAbsent(day, () => []).add(apt);
      } catch (_) {}
    }
    _grouped = map;
  }

  List<Data> _appointmentsForDay(DateTime day) {
    return _grouped[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final calendarWidget = _buildCalendar();
    final listWidget = Column(
      children: [
        _buildDaySummary(),
        Expanded(child: _buildDayAppointments()),
      ],
    );

    if (widget.isSideBySide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: calendarWidget),
          const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
          Expanded(flex: 3, child: listWidget),
        ],
      );
    }

    return Column(
      children: [
        Expanded(flex: 55, child: calendarWidget),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(flex: 45, child: listWidget),
      ],
    );
  }

  // ── Calendar ──────────────────────────────────────────────────────────

  Widget _buildCalendar() {
    return Container(
      color: Colors.white,
      child: TableCalendar<Data>(
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
        },
        onPageChanged: (focused) => _focusedDay = focused,
        eventLoader: (day) => _appointmentsForDay(day),
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
        calendarBuilders: CalendarBuilders<Data>(
          prioritizedBuilder: (context, date, focusedDay) => _buildDayCell(date, _appointmentsForDay(date)),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: secondaryColor.withAlpha(40), shape: BoxShape.circle),
          todayTextStyle: AppTypography.bodyMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w700, color: secondaryColor),
          markerDecoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
          markerSize: 6,
          markersMaxCount: 3,
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

  Widget _buildDayCell(DateTime date, List<Data> dayAppointments) {
    final isSelected = isSameDay(date, _selectedDay);
    final isToday = isSameDay(date, DateTime.now());
    final isOutsideMonth = date.month != _focusedDay.month;

    final dayNumber = Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: isToday ? const BoxDecoration(color: secondaryColor, shape: BoxShape.circle) : null,
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday
                ? Colors.white
                : isOutsideMonth
                ? const Color(0xFFD1D5DB)
                : const Color(0xFF374151),
          ),
        ),
      ),
    );

    final chips = <Widget>[];
    final visible = dayAppointments.take(_maxChipsPerCell).toList();
    final overflow = dayAppointments.length - _maxChipsPerCell;

    for (final apt in visible) {
      final statusColor = appointmentStatusColors[apt.appointmentStatus] ?? Colors.grey;
      final timeStr = _formatTime(apt.appointmentDatetime);
      final name = (apt.user?.userFullName ?? '').split(' ').firstOrNull ?? '';

      chips.add(
        GestureDetector(
          onTap: () => _openDetail(context, apt),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(3),
              border: Border(left: BorderSide(color: statusColor, width: 2)),
            ),
            child: Text(
              '$timeStr $name',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: statusColor, height: 1.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    if (overflow > 0) {
      chips.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            '+$overflow more',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F5FF) : null,
        border: isSelected ? Border.all(color: secondaryColor.withAlpha(80), width: 1) : null,
      ),
      child: Column(children: [dayNumber, if (chips.isNotEmpty) ...chips]),
    );
  }

  String _formatTime(String? datetimeStr) {
    if (datetimeStr == null) return '';
    try {
      final dt = DateTime.parse(datetimeStr);
      return DateFormat('h:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  // ── Day summary bar ──────────────────────────────────────────────────

  Widget _buildDaySummary() {
    final count = _appointmentsForDay(_selectedDay).length;
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

  // ── Appointments for selected day ─────────────────────────────────────

  Widget _buildDayAppointments() {
    final list = _appointmentsForDay(_selectedDay);

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
            const SizedBox(height: 4),
            Text(
              'Tap another date or adjust your filters',
              style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    list.sort((a, b) {
      final aDt = DateTime.tryParse(a.appointmentDatetime ?? '') ?? DateTime(2000);
      final bDt = DateTime.tryParse(b.appointmentDatetime ?? '') ?? DateTime(2000);
      return aDt.compareTo(bDt);
    });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildAppointmentCard(context, list[index]),
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
      builder: (ctx) =>
          AppointmentDetails(type: 'update', appointment: apt, tabs: widget.currentTabs, refreshData: widget.onRefresh),
    );
  }
}
