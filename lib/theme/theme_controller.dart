import 'package:flutter/material.dart';

import 'ambient_lava_palette.dart';
import 'linkvault_accent.dart';

/// App chrome tokens. Linkvault is dark-only; ambient color cycles automatically.
class ThemeController {
  /// Static shell accent for [MaterialApp]; living color uses [AmbientLavaPalette]
  /// with [AmbientMotionScope] phase in widgets.
  LinkvaultAccent get accent => AmbientLavaPalette.defaultAccent;
}
