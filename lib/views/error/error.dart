import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:rive/rive.dart';

class ErrorPage extends StatefulWidget {
  final Exception? error;

  const ErrorPage({
    super.key,
    required this.error,
  });

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Container(
        //   color: Colors.amber,
        //   width: screenWidth(700),
        //   height: screenHeight(400),
        //   child: Container(
        //     color: Colors.red,
        //     width: screenWidth(400),
        //     height: screenHeight(100),
        //   ),
        // ),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(
                vertical: screenWidthByBreakpoint(5, 5, screenWidth1728(5), useAbsoluteValueDesktop: true)),
            // constraints: BoxConstraints(
            //     maxWidth: screenWidthByBreakpoint(60, 40, screenWidth1728(50), useAbsoluteValueDesktop: true)),
            child: const RiveAnimation.asset(
              'assets/riv/error_404.riv',
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(screenPadding, screenPadding, screenPadding, screenPadding * 2),
          child: Text(
            'Sorry, we couldn\'t find that page…',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
        ),
        // But Dash is here to help! Maybe one of these will point you in the right direction?
      ],
    );
  }
}
