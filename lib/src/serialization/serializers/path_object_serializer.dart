import 'dart:ui';

import 'package:flutter/material.dart';

import '../../objects/path_object.dart';
import '../object_serializer.dart';

/// PathObjectのシリアライズを担当するクラス
class PathObjectSerializer implements ObjectSerializer<PathObject> {
  static const PathObjectSerializer instance = PathObjectSerializer._();

  const PathObjectSerializer._();

  @override
  Future<PathObject> fromJson(Map<String, dynamic> json) async {
    final Map<String, dynamic> pathData = json['path'];
    final List<dynamic> points = (pathData['points'])
        .map((point) => Offset(
              (point['x'] as num).toDouble(),
              (point['y'] as num).toDouble(),
            ))
        .toList();

    final Path path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
    }

    final Paint paint = Paint()
      ..color = Color(pathData['paint']['color'] as int)
      ..strokeWidth = (pathData['paint']['strokeWidth'] as num).toDouble()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    return PathObject(
      inputPath: path,
      paint: paint,
    );
  }

  @override
  Map<String, dynamic> toJson(PathObject object) {
    final PathMetrics pathMetrics = object.path.computeMetrics();
    final List<Map<String, double>> points = <Map<String, double>>[];

    for (final metric in pathMetrics) {
      for (double distance = 0; distance <= metric.length; distance += 1) {
        final pos = metric.getTangentForOffset(distance)?.position;
        if (pos != null) {
          points.add({
            'x': pos.dx,
            'y': pos.dy,
          });
        }
      }
    }

    return {
      'path': {
        'points': points,
        'paint': {
          'color': object.paint.color.value,
          'strokeWidth': object.paint.strokeWidth,
        },
      },
    };
  }
}
