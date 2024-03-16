import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';

class TopBarController extends ChangeNotifier {
  int _pageIndex = 0;
  int get pageIndex => _pageIndex;

  set pageValue(int value) {
    pageController.selectIndex(value);
    _pageIndex = value;

    notifyListeners();
  }
}
