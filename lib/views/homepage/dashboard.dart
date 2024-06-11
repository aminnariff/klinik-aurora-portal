import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/dashboard_controller.dart';
import 'package:klinik_aurora_portal/views/homepage/graph.dart';
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
    DashboardController.get(context).then((value) {
      if (responseCode(value.code)) {
        context.read<DashboardController>().dashboardResponse = value.data;
      }
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
          AppPadding.vertical(denominator: 1 / 2),
          Row(
            children: [
              firstContent(),
              // secondContent(),
            ],
          )
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
        width: screenWidth1728(85),
        child: Column(
          children: [
            Container(
              height: screenHeight829(20),
              margin: EdgeInsets.symmetric(horizontal: screenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  firstRowContent(darkModeCardColor, "Total Users", "${snapshot.dashboardResponse?.data?.totalUser}",
                      textColor: Colors.white),
                  firstRowContent(
                      cardColor, "Total Active Users", "${snapshot.dashboardResponse?.data?.totalActiveUser}"),
                  firstRowContent(
                      cardColor, "Total Active Branch", "${snapshot.dashboardResponse?.data?.totalActiveBranch}"),
                  firstRowContent(
                      cardColor, "Total Active Promotion", "${snapshot.dashboardResponse?.data?.totalActivePromotion}"),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding / 2),
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

  secondContent() {
    return Expanded(
      child: SizedBox(
        height: screenHeight(100),
        width: screenWidth1728(10),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(0, screenPadding * 2, screenPadding, screenPadding / 2),
                decoration: BoxDecoration(
                    color: bgContainer,
                    border: Border.all(
                      color: const Color.fromRGBO(226, 225, 225, 1),
                    ),
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserData {
  String email;

  UserData({required this.email});
}
