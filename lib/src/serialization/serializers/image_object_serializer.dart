import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../objects/image_object.dart';
import '../../utils/image_utils.dart';
import '../object_serializer.dart';

/// ImageObjectのシリアライズを担当するクラス
class ImageObjectSerializer implements ObjectSerializer<ImageObject> {
  static const ImageObjectSerializer instance = ImageObjectSerializer._();

  const ImageObjectSerializer._();

  @override
  Future<ImageObject> fromJson(Map<String, dynamic> json) async {
    final imageData = json['image'] as Map<String, dynamic>;
    final encodedData = imageData['data'] as String;

    final size = Size(
      (imageData['size']['width'] as num).toDouble(),
      (imageData['size']['height'] as num).toDouble(),
    );

    // Base64エンコードされた画像データをデコード
    final ui.Image image = await ImageUtils.decodeBase64Image(encodedData);

    return ImageObject(
      image: image,
      size: size,
      globalCenter: Offset.zero,
    );
  }

  @override
  Future<Map<String, dynamic>> toJson(ImageObject object) async {
    final encodedData = await ImageUtils.encodeImageToBase64(object.image);

    return {
      'image': {
        'data': encodedData,
        'size': {
          'width': object.size.width,
          'height': object.size.height,
        },
      },
    };
  }
}
