import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Configures Android/iOS for edge-to-edge drawing behind system bars.
void configureEdgeToEdge() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

/// Overlay icons and bar colors that match the active [ColorScheme].
SystemUiOverlayStyle overlayForScheme(ColorScheme scheme) {
  final brightness = scheme.brightness;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness:
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: brightness,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness:
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}
