import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../objects/image_object.dart';
import '../object_serializer.dart';

/// ImageObjectのシリアライズを担当するクラス
class ImageObjectSerializer extends ObjectSerializer<ImageObject> {
  const ImageObjectSerializer();

  static const _instance = ImageObjectSerializer();
  static ImageObjectSerializer get instance => _instance;

  @override
  Map<String, Object> toJson(ImageObject object) {
    return {
      'imageBytes': object.encodedImageData,
      'size': <String, Object>{
        'width': object.size.width,
        'height': object.size.height,
      },
    };
  }

  @override
  Future<ImageObject> fromJson(Map<String, Object> json) async {
    final imageBytes = base64Decode(json['imageBytes'] as String);
    final sizeData = json['size'] as Map<String, Object>;
    final size = Size(
      sizeData['width'] as double,
      sizeData['height'] as double,
    );

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();

    return ImageObject(
      image: frame.image,
      globalCenter: Offset.zero,
      size: size,
    );
  }
}
