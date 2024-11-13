import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/dashboard_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/dashboard_response.dart';
import 'package:klinik_aurora_portal/views/homepage/graph.dart';
import 'package:klinik_aurora_portal/views/homepage/graph2.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  Color bgContainer = const Color.fromARGB(255, 248, 251, 255);
  // final Stream<QuerySnapshot> usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  List<UserData> userData = [];

  @override
  void initState() {
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      DashboardController.get(context).then((value) {
        if (responseCode(value.code)) {
          final currentDate = DateTime.now();
          final List<TotalRegistrationByMonth> totalRegistrationList = value.data?.data?.totalRegistrationByMonth ?? [];
          final List<TotalRegistrationByMonth> lastThreeMonths = [];
          final List<TotalRegistrationByDay> last7days = value.data?.data?.totalRegistrationByDay ?? [];
          for (int i = (value.data?.data?.totalRegistrationByMonth?.length ?? 0) - 1; i >= 0; i--) {
            final targetMonth = DateTime(currentDate.year, currentDate.month - i, 1);
            final registrationData = totalRegistrationList.firstWhere(
              (item) => item.year == targetMonth.year && item.month == targetMonth.month,
              orElse: () => TotalRegistrationByMonth(
                year: targetMonth.year,
                month: targetMonth.month,
                totalRegistrationByMonth: 0,
              ),
            );
            lastThreeMonths.add(registrationData);
          }

          final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
          last7days.sort((a, b) {
            if (a.date == null || b.date == null) return 0;
            final DateTime dateA = dateFormat.parse(a.date!);
            final DateTime dateB = dateFormat.parse(b.date!);
            return dateA.compareTo(dateB);
          });

          if (!mounted) return;
          context.read<DashboardController>().dashboardResponse = DashboardResponse(
            message: value.data?.message,
            data: Data(
              totalActiveUser: value.data?.data?.totalActiveUser,
              totalActiveBranch: value.data?.data?.totalActiveBranch,
              totalActivePromotion: value.data?.data?.totalActivePromotion,
              totalUser: value.data?.data?.totalUser,
              totalRegistrationByMonth: lastThreeMonths,
              totalRegistrationByDay: last7days,
            ),
          );
          value.data;
        }
      });
    });

    // FirebaseFirestore.instance.collection('users').where('isLocum', isEqualTo: true).get().then((val) {
    //   print(val);
    //   val.docs
    //       .map((DocumentSnapshot document) {
    //         Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
    //         userData.add(UserData(email: data['email']));
    //       })
    //       .toList()
    //       .cast();
    //   print(userData[0].email);
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              firstContent(),
            ],
          ),
          AppPadding.vertical(denominator: 2),
          secondContent(),
          AppPadding.vertical(),
        ],
      ),
    );
  }

  Widget secondContent() {
    return Container(
      width: screenWidth(85),
      margin: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 0),
      decoration: BoxDecoration(
          color: bgContainer,
          border: Border.all(
            color: const Color.fromRGBO(226, 225, 225, 1),
          ),
          borderRadius: BorderRadius.circular(30)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     const Text(
          //       "APP SESSION",
          //     ),
          //     Button(
          //       () {},
          //     )
          //   ],
          // ),
          Graph2Widget(),
        ],
      ),
    );
  }

  firstRowContent(Color color, String label, String total, {Color? textColor}) {
    return Expanded(
      child: CardContainer(
        Padding(
          padding: EdgeInsets.symmetric(vertical: screenPadding / 2, horizontal: screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodyLarge(context).apply(color: textColor),
              ),
              Text(
                total,
                style: AppTypography.bodyMedium(context).apply(color: textColor, fontSizeDelta: 10, fontWeightDelta: 3),
              )
            ],
          ),
        ),
        color: color,
        margin: EdgeInsets.all(screenPadding / 2),
      ),
    );
  }

  firstContent() {
    return Consumer<DashboardController>(builder: (context, snapshot, _) {
      return SizedBox(
        width: screenWidth(85),
        child: Column(
          children: [
            Container(
              height: 160,
              margin: EdgeInsets.symmetric(horizontal: screenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  firstRowContent(
                      darkModeCardColor, "Total Users", "${snapshot.dashboardResponse?.data?.totalUser ?? ''}",
                      textColor: Colors.white),
                  firstRowContent(
                      cardColor, "Total Active Users", "${snapshot.dashboardResponse?.data?.totalActiveUser ?? ''}"),
                  firstRowContent(
                      cardColor, "Total Active Branch", "${snapshot.dashboardResponse?.data?.totalActiveBranch ?? ''}"),
                  firstRowContent(cardColor, "Total Active Promotion",
                      "${snapshot.dashboardResponse?.data?.totalActivePromotion ?? ''}"),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 0),
              decoration: BoxDecoration(
                  color: bgContainer,
                  border: Border.all(
                    color: const Color.fromRGBO(226, 225, 225, 1),
                  ),
                  borderRadius: BorderRadius.circular(30)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     const Text(
                  //       "APP SESSION",
                  //     ),
                  //     Button(
                  //       () {},
                  //     )
                  //   ],
                  // ),
                  GraphWidget(),
                ],
              ),
            ),
            // Container(
            //   height: screenHeight(27),
            //   margin: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding),
            //   decoration: BoxDecoration(
            //       color: bgContainer,
            //       border: Border.all(
            //         color: const Color.fromRGBO(226, 225, 225, 1),
            //       ),
            //       borderRadius: BorderRadius.circular(30)),
            // ),
          ],
        ),
      );
    });
  }

  // secondContent() {
  //   return Expanded(
  //     child: SizedBox(
  //       height: screenHeight(100),
  //       width: screenWidth1728(10),
  //       child: Column(
  //         children: [
  //           Expanded(
  //             child: Container(
  //               margin: EdgeInsets.fromLTRB(0, screenPadding * 2, screenPadding, screenPadding / 2),
  //               decoration: BoxDecoration(
  //                   color: bgContainer,
  //                   border: Border.all(
  //                     color: const Color.fromRGBO(226, 225, 225, 1),
  //                   ),
  //                   borderRadius: BorderRadius.circular(30)),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

class UserData {
  String email;

  UserData({required this.email});
}
