import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Edge-to-edge with light system bar icons on the dark canvas.
void configureEdgeToEdge() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(overlayForScheme());
}

/// Overlay icons and bar colors for the fixed dark [ColorScheme].
SystemUiOverlayStyle overlayForScheme([ColorScheme? scheme]) {
  return const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );
}
