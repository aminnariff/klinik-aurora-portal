import 'package:flutter/foundation.dart';

bool isWebMobile =
    kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
