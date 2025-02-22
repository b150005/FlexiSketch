import 'package:flutter/material.dart';

import '../../objects/text_object.dart';
import '../object_serializer.dart';

class TextObjectSerializer implements ObjectSerializer<TextObject> {
  static const TextObjectSerializer instance = TextObjectSerializer._();

  const TextObjectSerializer._();

  @override
  Future<Map<String, dynamic>> toJson(TextObject object) async {
    return {
      'text': {
        'content': object.text,
        'fontSize': object.fontSize,
        'paint': {
          'color': object.paint.color.value,
          'strokeWidth': object.paint.strokeWidth,
          'style': object.paint.style.toString(),
        },
      },
    };
  }

  @override
  Future<TextObject> fromJson(Map<String, dynamic> json) async {
    final Map<String, dynamic> textData = json['text'] as Map<String, dynamic>;
    final Map<String, dynamic> paintData = textData['paint'] as Map<String, dynamic>;

    final paint = Paint()
      ..color = Color(paintData['color'] as int)
      ..strokeWidth = (paintData['strokeWidth'] as num).toDouble()
      ..style = PaintingStyle.values.firstWhere(
        (style) => style.toString() == paintData['style'],
      );

    return TextObject(
      text: textData['content'] as String,
      globalCenter: Offset.zero, // DrawableObjectSerializerで設定される
      paint: paint,
      fontSize: (textData['fontSize'] as num).toDouble(),
    );
  }
}
