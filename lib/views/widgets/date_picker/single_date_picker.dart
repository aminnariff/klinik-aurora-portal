// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class SingleDatePicker extends StatelessWidget {
//   final DateTime? initialSelectedDate;
//   final bool isAfterToday;
//   final bool isBeforeToday;
//   final bool isWeekdayOnly;
//   final bool isPayoutDate;
//   final bool isChargedDate;
//   final String datePass;
//   final DatePickerAttribute? attribute;

//   const SingleDatePicker({
//     Key? key,
//     this.attribute,
//     this.initialSelectedDate,
//     this.isAfterToday = false,
//     this.isBeforeToday = false,
//     this.isWeekdayOnly = false,
//     this.isPayoutDate = false,
//     this.isChargedDate = false,
//     this.datePass = "",
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               SizedBox(
//                 width: isMobile ? null : 43.31.w,
//                 height: isMobile ? 65.h : 60.h,
//                 child: Card(
//                   elevation: 2.0,
//                   color: Colors.white,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                   // decoration: const BoxDecoration(
//                   //   borderRadius: BorderRadius.all(Radius.circular(15)),
//                   //   color: WHITE_COLOR,
//                   // ),
//                   margin: EdgeInsets.fromLTRB(
//                     isMobile ? screenPadding : 2.w,
//                     isMobile ? 10.w : 0.w,
//                     isMobile ? screenPadding : 2.w,
//                     isMobile ? 10.w : 2.w,
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.fromLTRB(2.w, 0, 2.w, 1.w),
//                     child: SfDateRangePicker(
//                       headerHeight: isMobile ? 13.h : 10.h,
//                       selectionRadius: isMobile ? 10.w : 3.w,
//                       todayHighlightColor: secondaryColor,
//                       rangeSelectionColor: primary,
//                       selectionColor: secondaryColor,
//                       endRangeSelectionColor: secondaryColor,
//                       startRangeSelectionColor: secondaryColor,
//                       minDate: attribute?.minDate,
//                       maxDate: attribute?.maxDate,
//                       selectionShape: DateRangePickerSelectionShape.circle,
//                       initialSelectedDate: initialSelectedDate,
//                       initialDisplayDate: initialSelectedDate,
//                       backgroundColor: cardColor,
//                       enableMultiView: false,
//                       viewSpacing: isMobile ? 40 : 20,
//                       showNavigationArrow: true,
//                       view: DateRangePickerView.month,
//                       selectionMode: DateRangePickerSelectionMode.single,
//                       onSelectionChanged: (DateRangePickerSelectionChangedArgs args) async {
//                         Navigator.pop(context, args.value);
//                       },
//                       selectableDayPredicate: (DateTime date) {
//                         if (isBeforeToday) {
//                           if (date.isAfter(DateTime.now())) {
//                             return false;
//                           }
//                         }
//                         if (isAfterToday) {
//                           if (date.isBefore(DateTime.now())) {
//                             return false;
//                           }
//                         }
//                         if (isPayoutDate) {
//                           final now = DateFormat('dd/MM/yyyy').parse(datePass);
//                           final newRange = now.weekday == DateTime.friday || now.weekday == DateTime.thursday
//                               ? now.add(const Duration(days: 4))
//                               : now.weekday == DateTime.saturday
//                                   ? now.add(const Duration(days: 3))
//                                   : now.add(const Duration(days: 2));
//                           final maxRange = newRange.add(const Duration(days: 120));
//                           if (date.isBefore(newRange)) {
//                             return false;
//                           }
//                           if (date.isAfter(maxRange)) {
//                             return false;
//                           }
//                         }
//                         if (isChargedDate) {
//                           final now = DateFormat("dd/MM/yyyy").parse(datePass);
//                           final newRange = now.add(const Duration(days: 60));
//                           final temp = DateTime.now().subtract(const Duration(days: 1));
//                           if (date.isAfter(newRange)) {
//                             return false;
//                           }
//                           if (date.isBefore(temp)) {
//                             return false;
//                           }
//                         }
//                         if (isWeekdayOnly) {
//                           if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
//                             return false;
//                           }
//                         }
//                         return true;
//                       },
//                       yearCellStyle: const DateRangePickerYearCellStyle(
//                           textStyle: TextStyle(fontSize: 16, color: textPrimaryColor),
//                           leadingDatesTextStyle: TextStyle(fontSize: 16, color: textPrimaryColor),
//                           todayTextStyle: TextStyle(fontSize: 16, color: secondaryColor)),
//                       monthCellStyle: DateRangePickerMonthCellStyle(
//                         todayTextStyle: const TextStyle(fontSize: 16, color: secondaryColor),
//                         weekendTextStyle:
//                             const TextStyle(fontSize: 16, color: tertiaryColor, fontWeight: FontWeight.w500),
//                         disabledDatesTextStyle:
//                             TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.5), fontWeight: FontWeight.w500),
//                         textStyle: const TextStyle(fontSize: 16, color: textPrimaryColor, fontWeight: FontWeight.w500),
//                       ),
//                       monthViewSettings: const DateRangePickerMonthViewSettings(
//                         viewHeaderStyle: DateRangePickerViewHeaderStyle(
//                           textStyle: TextStyle(fontSize: 16, color: textPrimaryColor, fontWeight: FontWeight.w500),
//                         ),
//                         weekNumberStyle: DateRangePickerWeekNumberStyle(
//                           textStyle: TextStyle(fontSize: 16, color: textPrimaryColor, fontWeight: FontWeight.w500),
//                         ),
//                       ),
//                       headerStyle: DateRangePickerHeaderStyle(
//                         textAlign: TextAlign.center,
//                         textStyle: TextStyle(
//                             color: textPrimaryColor, fontSize: isMobile ? 23 : 17, fontWeight: FontWeight.w500),
//                       ),
//                       selectionTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

class DatePickerAttribute {
  final DateTime? initialSelectedDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool isAfterToday;
  final bool isBeforeToday;
  final bool isWeekdayOnly;
  final bool isPayoutDate;
  final bool isChargedDate;
  final String? afterDate;
  final String datePass;

  DatePickerAttribute({
    this.initialSelectedDate,
    this.minDate,
    this.maxDate,
    this.isAfterToday = false,
    this.isBeforeToday = false,
    this.isWeekdayOnly = false,
    this.isPayoutDate = false,
    this.isChargedDate = false,
    this.afterDate,
    this.datePass = '',
  });
}
