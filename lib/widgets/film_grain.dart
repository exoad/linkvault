import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Faint static film grain overlay for a filmic texture.
///
/// Uses a small noise tile scaled down so grains read fine, not chunky.
class FilmGrain extends StatefulWidget {
  const FilmGrain({
    super.key,
    this.opacity = 0.032,
    this.tileSize = 48,
    this.shaderScale = 0.5,
  });

  /// Overall strength of the grain (0–1).
  final double opacity;

  /// Pixel size of the generated noise tile.
  final int tileSize;

  /// Scale applied to the repeating shader (< 1 = finer apparent grain).
  final double shaderScale;

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
          painter: _GrainPainter(
            noise: noise,
            opacity: widget.opacity,
            shaderScale: widget.shaderScale,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({
    required this.noise,
    required this.opacity,
    required this.shaderScale,
  });

  final ui.Image noise;
  final double opacity;
  final double shaderScale;

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = Matrix4.diagonal3Values(shaderScale, shaderScale, 1);
    final paint = Paint()
      ..shader = ui.ImageShader(
        noise,
        TileMode.repeated,
        TileMode.repeated,
        matrix.storage,
      )
      ..colorFilter = ColorFilter.mode(
        Color.fromARGB((opacity * 255).round(), 255, 255, 255),
        BlendMode.modulate,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      oldDelegate.noise != noise ||
      oldDelegate.opacity != opacity ||
      oldDelegate.shaderScale != shaderScale;
}
