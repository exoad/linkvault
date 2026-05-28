import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Faint static film grain overlay for a filmic, "tech" texture.
///
/// Generates one small noise tile and repeats it across the screen at very low
/// opacity. Static (no per-frame work) and pointer-transparent.
class FilmGrain extends StatefulWidget {
  const FilmGrain({
    super.key,
    this.opacity = 0.05,
    this.tileSize = 160,
  });

  /// Overall strength of the grain (0–1).
  final double opacity;

  /// Pixel size of the repeating noise tile.
  final int tileSize;

  @override
  State<FilmGrain> createState() => _FilmGrainState();
}

class _FilmGrainState extends State<FilmGrain> {
  ui.Image? _noise;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final size = widget.tileSize;
    final rng = Random(7);
    final pixels = Uint8List(size * size * 4);
    for (var i = 0; i < size * size; i++) {
      final v = rng.nextInt(256);
      final o = i * 4;
      pixels[o] = v;
      pixels[o + 1] = v;
      pixels[o + 2] = v;
      pixels[o + 3] = rng.nextInt(256);
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      size,
      size,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;
    if (mounted) {
      setState(() => _noise = image);
    } else {
      image.dispose();
    }
  }

  @override
  void dispose() {
    _noise?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noise = _noise;
    if (noise == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GrainPainter(noise: noise, opacity: widget.opacity),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.noise, required this.opacity});

  final ui.Image noise;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.ImageShader(
        noise,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      )
      ..colorFilter = ColorFilter.mode(
        Color.fromARGB((opacity * 255).round(), 255, 255, 255),
        BlendMode.modulate,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      oldDelegate.noise != noise || oldDelegate.opacity != opacity;
}
