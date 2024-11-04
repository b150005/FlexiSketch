import 'package:flutter/material.dart';

import '../../objects/drawable_object.dart';
import '../../objects/image_object.dart';
import '../../objects/path_object.dart';
import '../../objects/shape_object.dart';
import '../object_serializer.dart';
import 'image_object_serializer.dart';
import 'path_object_serializer.dart';
import 'shape_object_serializer.dart';

/// DrawableObjectのシリアライズを担当するクラス
class DrawableObjectSerializer extends ObjectSerializer<DrawableObject> {
  const DrawableObjectSerializer();

  static const _instance = DrawableObjectSerializer();

  /// シングルトンインスタンスを取得
  static DrawableObjectSerializer get instance => _instance;

  @override
  Map<String, Object> toJson(DrawableObject object) {
    return {
      'type': object.runtimeType.toString(),
      'globalCenter': <String, Object>{
        'dx': object.globalCenter.dx,
        'dy': object.globalCenter.dy,
      },
      'rotation': object.rotation,
      'scale': object.scale,
      'isSelected': object.isSelected,
      ...serializeSpecific(object),
    };
  }

  Map<String, Object> serializeSpecific(DrawableObject object) {
    final specificSerializer = _getSpecificSerializer(object);
    return specificSerializer.toJson(object);
  }

  @override
  Future<DrawableObject> fromJson(Map<String, Object> json) async {
    final type = json['type'] as String;
    final globalCenter = Offset(
      (json['globalCenter'] as Map<String, Object>)['dx'] as double,
      (json['globalCenter'] as Map<String, Object>)['dy'] as double,
    );
    final rotation = json['rotation'] as double;
    final scale = json['scale'] as double;
    final isSelected = json['isSelected'] as bool;

    final object = await _deserializeSpecific(type, json);
    object.globalCenter = globalCenter;
    object.rotation = rotation;
    object.scale = scale;
    object.isSelected = isSelected;

    return object;
  }

  Future<DrawableObject> _deserializeSpecific(String type, Map<String, Object> json) async {
    switch (type) {
      case 'PathObject':
        return PathObjectSerializer.instance.fromJson(json);
      case 'ShapeObject':
        return ShapeObjectSerializer.instance.fromJson(json);
      case 'ImageObject':
        return ImageObjectSerializer.instance.fromJson(json);
      default:
        throw Exception('Unknown object type: $type');
    }
  }

  ObjectSerializer _getSpecificSerializer(DrawableObject object) {
    if (object is PathObject) {
      return PathObjectSerializer.instance;
    } else if (object is ShapeObject) {
      return ShapeObjectSerializer.instance;
    } else if (object is ImageObject) {
      return ImageObjectSerializer.instance;
    }
    throw Exception('Unknown object type: ${object.runtimeType}');
  }
}
