import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';

class UserPointDetail extends StatefulWidget {
  const UserPointDetail({super.key});

  @override
  State<UserPointDetail> createState() => _UserPointDetailState();
}

class _UserPointDetailState extends State<UserPointDetail> {
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CardContainer(
              Column(
                children: [],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
