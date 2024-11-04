import 'package:flutter/material.dart';

import '../../objects/shape_object.dart';
import '../../tools/shape_tool.dart';
import '../object_serializer.dart';

/// ShapeObjectのシリアライズを担当するクラス
class ShapeObjectSerializer extends ObjectSerializer<ShapeObject> {
  const ShapeObjectSerializer();

  static const _instance = ShapeObjectSerializer();
  static ShapeObjectSerializer get instance => _instance;

  @override
  Map<String, Object> toJson(ShapeObject object) {
    return {
      'startPoint': <String, Object>{
        'dx': object.startPoint.dx,
        'dy': object.startPoint.dy,
      },
      'endPoint': <String, Object>{
        'dx': object.endPoint.dx,
        'dy': object.endPoint.dy,
      },
      'shapeType': object.shapeType.index,
      'paint': <String, Object>{
        'color': object.paint.color.value,
        'strokeWidth': object.paint.strokeWidth,
        'style': object.paint.style.index,
      },
    };
  }

  @override
  ShapeObject fromJson(Map<String, Object> json) {
    final startPoint = Offset(
      (json['startPoint'] as Map<String, Object>)['dx'] as double,
      (json['startPoint'] as Map<String, Object>)['dy'] as double,
    );
    final endPoint = Offset(
      (json['endPoint'] as Map<String, Object>)['dx'] as double,
      (json['endPoint'] as Map<String, Object>)['dy'] as double,
    );
    final paintData = json['paint'] as Map<String, Object>;

    final paint = Paint()
      ..color = Color(paintData['color'] as int)
      ..strokeWidth = paintData['strokeWidth'] as double
      ..style = PaintingStyle.values[paintData['style'] as int];

    return ShapeObject(
      startPoint: startPoint,
      endPoint: endPoint,
      shapeType: ShapeType.values[json['shapeType'] as int],
      paint: paint,
    );
  }
}
