// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get_locum_admin/graph.dart';
// import 'package:get_locum_admin/views/widgets/app_padding.dart';
// import 'package:get_locum_admin/views/widgets/button.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:sizer/sizer.dart';

// class MainPage extends StatefulWidget {
//   const MainPage({super.key});

//   @override
//   State<MainPage> createState() => _MainPageState();
// }

// class _MainPageState extends State<MainPage> {
//   Color bgContainer = const Color.fromARGB(255, 248, 251, 255);
//   final Stream<QuerySnapshot> usersStream = FirebaseFirestore.instance.collection('users').snapshots();
//   List<UserData> userData = [];

//   @override
//   void initState() {
//     // FirebaseFirestore.instance.collection('users').where('isLocum', isEqualTo: true).get().then((val) {
//     //   print(val);
//     //   val.docs
//     //       .map((DocumentSnapshot document) {
//     //         Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
//     //         userData.add(UserData(email: data['email']));
//     //       })
//     //       .toList()
//     //       .cast();
//     //   print(userData[0].email);
//     // });
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: SingleChildScrollView(
//       child: Column(
//         children: [
//           Padding(
//             padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 IconButton(
//                     onPressed: () {},
//                     icon: const Icon(
//                       Icons.notifications,
//                       color: Colors.black,
//                     )),
//                 const Icon(
//                   Icons.person,
//                   color: Colors.black,
//                 ),
//                 Text(
//                   "ADMIN",
//                   style: GoogleFonts.quicksand(
//                     fontSize: 3.sp,
//                   ),
//                 )
//               ],
//             ),
//           ),
//           Row(
//             children: [firstContent(), secondContent()],
//           )
//         ],
//       ),
//     )
//         //         ;
//         //       });
//         // })
//         );
//   }

//   firstRowContent(double width, double height, Color color, bool enabledBorder, String label, String total) {
//     return Container(
//       width: width,
//       height: height,
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: enabledBorder ? const Color.fromRGBO(226, 225, 225, 1) : Colors.transparent,
//         ),
//         color: color,
//         borderRadius: BorderRadius.circular(30),
//       ),
//       child: Padding(
//         padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 1.2.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: GoogleFonts.quicksand(
//                 fontSize: 3.sp,
//                 fontWeight: FontWeight.w600,
//                 color: enabledBorder ? Colors.black : Colors.white,
//               ),
//             ),
//             Text(
//               total,
//               style: GoogleFonts.quicksand(
//                 fontSize: 6.sp,
//                 fontWeight: FontWeight.w600,
//                 color: enabledBorder ? Colors.black : Colors.white,
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   firstContent() {
//     return SizedBox(
//       width: 70.w,
//       child: Column(
//         children: [
//           Container(
//             height: 25.h,
//             margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 firstRowContent(15.w, 25.h, Colors.black, false, "Total Session", "2.4k+"),
//                 firstRowContent(15.w, 20.h, bgContainer, true, "Total Visitor", ""),
//                 firstRowContent(15.w, 20.h, bgContainer, true, "Total Spend", ""),
//                 firstRowContent(15.w, 20.h, bgContainer, true, "Avg Req Received", ""),
//               ],
//             ),
//           ),
//           Container(
//             height: 38.h,
//             margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
//             padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
//             decoration: BoxDecoration(
//                 color: bgContainer,
//                 border: Border.all(
//                   color: const Color.fromRGBO(226, 225, 225, 1),
//                 ),
//                 borderRadius: BorderRadius.circular(30)),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "APP SESSION",
//                       style: GoogleFonts.quicksand(fontSize: 4.sp, fontWeight: FontWeight.bold),
//                     ),
//                     Button(
//                       width: 10.w,
//                       height: 2.w,
//                       label: "Download CSV",
//                       onTap: () {},
//                     )
//                   ],
//                 ),
//                 const AppPadding(
//                   denominator: 5,
//                 ).vertical(),
//                 const GraphWidget(),
//               ],
//             ),
//           ),
//           Container(
//             height: 27.h,
//             margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
//             decoration: BoxDecoration(
//                 color: bgContainer,
//                 border: Border.all(
//                   color: const Color.fromRGBO(226, 225, 225, 1),
//                 ),
//                 borderRadius: BorderRadius.circular(30)),
//           ),
//         ],
//       ),
//     );
//   }

//   secondContent() {
//     return Expanded(
//       child: SizedBox(
//         height: 100.h,
//         child: Column(
//           children: [
//             Expanded(
//               child: Container(
//                 margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
//                 decoration: BoxDecoration(
//                     color: bgContainer,
//                     border: Border.all(
//                       color: const Color.fromRGBO(226, 225, 225, 1),
//                     ),
//                     borderRadius: BorderRadius.circular(30)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class UserData {
//   String email;

//   UserData({required this.email});
// }
