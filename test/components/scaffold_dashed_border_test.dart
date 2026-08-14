import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_dashed_border.dart';

void main() {
  test('degenerate dash/gap values paint nothing instead of hanging', () {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    const painter = ScaffoldDashedBorderPainter(
      color: Colors.black,
      strokeWidth: 1.0,
      borderRadius: BorderRadius.zero,
      dashLength: 0.0,
      gapLength: 0.0,
    );
    // Previously this looped forever; the guard makes it a no-op.
    painter.paint(canvas, const Size(100, 100));

    final picture = recorder.endRecording();
    expect(picture, isNotNull);
    picture.dispose();
  });

  test('a negative gap (non-positive advance) is also guarded', () {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    const painter = ScaffoldDashedBorderPainter(
      color: Colors.black,
      strokeWidth: 1.0,
      borderRadius: BorderRadius.zero,
      dashLength: 1.0,
      gapLength: -2.0,
    );
    painter.paint(canvas, const Size(100, 100));

    final picture = recorder.endRecording();
    expect(picture, isNotNull);
    picture.dispose();
  });

  test('normal dash/gap values paint a border', () {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    const painter = ScaffoldDashedBorderPainter(
      color: Colors.black,
      strokeWidth: 1.0,
      borderRadius: BorderRadius.zero,
      dashLength: 6.0,
      gapLength: 4.0,
    );
    painter.paint(canvas, const Size(100, 100));

    final picture = recorder.endRecording();
    expect(picture, isNotNull);
    picture.dispose();
  });
}
