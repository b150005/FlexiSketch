import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageUtils {
  /// Base64エンコードされた画像データをデコードしてui.Imageオブジェクトを生成する
  static Future<ui.Image> decodeBase64Image(String encodedData) async {
    final bytes = base64Decode(encodedData);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// ui.Imageオブジェクトをbase64エンコードされた文字列に変換する
  static Future<String> encodeImageToBase64(
    ui.Image image, {
    int maxWidth = 1920, // 最大幅[px]
    int maxHeight = 1080, // 最大高さ[px]
  }) async {
    // 1. まず画像をリサイズ（大きすぎる場合）
    ui.Image processedImage = image;

    if (image.width > maxWidth || image.height > maxHeight) {
      processedImage = await _resizeImage(image, maxWidth, maxHeight);
    }

    // 2. 最適化された設定でバイトデータに変換
    // FIXME: ここで UI スレッドのブロッキングが発生するが、 UI スレッドでしか実行できないので諦める
    final byteData = await processedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);

    final encodedImage = base64Encode(bytes);

    return encodedImage;
  }

  /// サイズを指定してイメージをリサイズする
  static Future<ui.Image> _resizeImage(ui.Image image, int targetWidth, int targetHeight) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // アスペクト比を保持してリサイズ
    final double scaleW = targetWidth / image.width;
    final double scaleH = targetHeight / image.height;
    final double scale = scaleW < scaleH ? scaleW : scaleH;

    final width = (image.width * scale).round();
    final height = (image.height * scale).round();

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..filterQuality = FilterQuality.medium,
    );

    final picture = pictureRecorder.endRecording();
    return await picture.toImage(width, height);
  }
}
