import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../objects/path_object.dart';
import '../object_serializer.dart';

/// PathObjectのシリアライズを担当するクラス
class PathObjectSerializer extends ObjectSerializer<PathObject> {
  const PathObjectSerializer();

  static const _instance = PathObjectSerializer();
  static PathObjectSerializer get instance => _instance;

  @override
  Map<String, Object> toJson(PathObject object) {
    return {
      'path': object.path.toString(),
      'paint': <String, Object>{
        'color': object.paint.color.value,
        'strokeWidth': object.paint.strokeWidth,
        'style': object.paint.style.index,
        'strokeCap': object.paint.strokeCap.index,
        'strokeJoin': object.paint.strokeJoin.index,
        'blendMode': object.paint.blendMode.index,
      },
    };
  }

  @override
  PathObject fromJson(Map<String, Object> json) {
    final path = parseSvgPathData(json['path'] as String);
    final paintData = json['paint'] as Map<String, Object>;

    final paint = Paint()
      ..color = Color(paintData['color'] as int)
      ..strokeWidth = paintData['strokeWidth'] as double
      ..style = PaintingStyle.values[paintData['style'] as int]
      ..strokeCap = StrokeCap.values[paintData['strokeCap'] as int]
      ..strokeJoin = StrokeJoin.values[paintData['strokeJoin'] as int]
      ..blendMode = BlendMode.values[paintData['blendMode'] as int];

    return PathObject(
      inputPath: path,
      paint: paint,
    );
  }
}
