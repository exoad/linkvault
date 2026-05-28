import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

class DisplayModeService {
  static Future<void> ensureHighRefreshRate() async {
    if (!Platform.isAndroid) return;
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } on PlatformException {
      // noAPI, noActivity, or unsupported — keep default mode
    }
  }
}
