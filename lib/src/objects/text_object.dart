import 'package:flutter/material.dart';

import '../serialization/object_serializer.dart';
import '../serialization/serializers/text_object_serializer.dart';
import 'drawable_object.dart';

class TextObject extends DrawableObject {
  String text;
  double fontSize;
  final Paint _paint;

  TextObject({
    required this.text,
    required super.globalCenter,
    required Paint paint,
    required this.fontSize,
    super.rotation = 0.0,
    super.scale = 1.0,
  }) : _paint = paint;

  Paint get paint => _paint;

  @override
  String get type => 'text';

  @override
  ObjectSerializer get serializer => TextObjectSerializer.instance;

  @override
  Rect get localBounds {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: _paint.color,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    return Offset.zero & textPainter.size;
  }

  @override
  void drawObject(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: _paint.color,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool checkIntersection(Path other) {
    final rect = localBounds;
    final path = Path()..addRect(rect);
    return path.getBounds().overlaps(other.getBounds());
  }

  @override
  bool checkContainsPoint(Offset localPoint) {
    return localBounds.contains(localPoint);
  }

  @override
  DrawableObject clone() {
    return TextObject(
      text: text,
      globalCenter: globalCenter,
      paint: Paint()
        ..color = _paint.color
        ..strokeWidth = _paint.strokeWidth
        ..style = _paint.style,
      fontSize: fontSize,
      rotation: rotation,
      scale: scale,
    );
  }
}
