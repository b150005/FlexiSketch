import 'package:flutter/material.dart';

import '../../objects/shape_object.dart';
import '../../tools/shape_tool.dart';
import '../object_serializer.dart';

/// ShapeObjectのシリアライズを担当するクラス
class ShapeObjectSerializer implements ObjectSerializer<ShapeObject> {
  static const ShapeObjectSerializer instance = ShapeObjectSerializer._();

  const ShapeObjectSerializer._();

  @override
  Future<ShapeObject> fromJson(Map<String, dynamic> json) async {
    final shapeData = json['shape'] as Map<String, dynamic>;

    final startPoint = Offset(
      (shapeData['startPoint']['x'] as num).toDouble(),
      (shapeData['startPoint']['y'] as num).toDouble(),
    );

    final endPoint = Offset(
      (shapeData['endPoint']['x'] as num).toDouble(),
      (shapeData['endPoint']['y'] as num).toDouble(),
    );

    final shapeType = ShapeType.values.firstWhere(
      (type) => type.toString() == shapeData['shapeType'],
    );

    final paintData = shapeData['paint'] as Map<String, dynamic>;
    final paint = Paint()
      ..color = Color(paintData['color'] as int)
      ..strokeWidth = (paintData['strokeWidth'] as num).toDouble()
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.values.firstWhere(
        (mode) => mode.toString() == paintData['blendMode'],
      );

    return ShapeObject(
      startPoint: startPoint,
      endPoint: endPoint,
      shapeType: shapeType,
      paint: paint,
    );
  }

  @override
  Map<String, dynamic> toJson(ShapeObject object) {
    return {
      'shape': {
        'startPoint': {
          'x': object.startPoint.dx,
          'y': object.startPoint.dy,
        },
        'endPoint': {
          'x': object.endPoint.dx,
          'y': object.endPoint.dy,
        },
        'shapeType': object.shapeType.toString(),
        'paint': {
          'color': object.paint.color.value,
          'strokeWidth': object.paint.strokeWidth,
          'blendMode': object.paint.blendMode.toString(),
        },
      },
    };
  }
}
