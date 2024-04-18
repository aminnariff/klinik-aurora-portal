import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/homepage/graph.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

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
              secondContent(),
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
                style: AppTypography.bodyMedium(context).apply(color: textColor),
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
    return SizedBox(
      width: screenWidth1728(70),
      child: Column(
        children: [
          Container(
            height: screenHeight829(20),
            margin: EdgeInsets.symmetric(horizontal: screenPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                firstRowContent(darkModeCardColor, "Total Session", "2.4k+", textColor: Colors.white),
                firstRowContent(cardColor, "Total Visitor", ""),
                firstRowContent(cardColor, "Total Spend", ""),
                firstRowContent(cardColor, "Avg Req Received", ""),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding),
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
          Container(
            height: screenHeight(27),
            margin: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding),
            decoration: BoxDecoration(
                color: bgContainer,
                border: Border.all(
                  color: const Color.fromRGBO(226, 225, 225, 1),
                ),
                borderRadius: BorderRadius.circular(30)),
          ),
        ],
      ),
    );
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
