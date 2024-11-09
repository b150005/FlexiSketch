import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../objects/drawable_object.dart';

/// スケッチのサムネイル生成方法を定義するインターフェース
abstract class ThumbnailGenerator {
  /// プレビュー画像を生成する
  ///
  /// [objects] サムネイルを生成する対象のオブジェクトリスト
  /// [size] 生成するサムネイルのサイズ
  Future<Uint8List> generatePreview(List<DrawableObject> objects, Size size);

  /// サムネイル画像を生成する
  ///
  /// [objects] サムネイルを生成する対象のオブジェクトリスト
  /// [size] 生成するサムネイルのサイズ
  Future<Uint8List> generateThumbnail(List<DrawableObject> objects, Size size);
}

class DefaultThumbnailGenerator implements ThumbnailGenerator {
  @override
  Future<Uint8List> generatePreview(List<DrawableObject> objects, Size size) async {
    return _generateImage(objects, size);
  }

  @override
  Future<Uint8List> generateThumbnail(List<DrawableObject> objects, Size size) async {
    return _generateImage(objects, size);
  }

  Future<Uint8List> _generateImage(List<DrawableObject> objects, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 背景を描画
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );

    // オブジェクトの全体を含む矩形を計算
    final bounds = _calculateBounds(objects);
    if (bounds != null) {
      // スケールを計算
      final scaleX = size.width / bounds.width;
      final scaleY = size.height / bounds.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      // 中央に配置するための移動量を計算
      final dx = (size.width - bounds.width * scale) / 2 - bounds.left * scale;
      final dy = (size.height - bounds.height * scale) / 2 - bounds.top * scale;

      // 変換を適用
      canvas.scale(scale);
      canvas.translate(dx / scale, dy / scale);

      // オブジェクトを描画
      for (final object in objects) {
        object.draw(canvas);
      }
    }

    // 画像を生成
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.round(), size.height.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Rect? _calculateBounds(List<DrawableObject> objects) {
    if (objects.isEmpty) return null;

    var bounds = objects.first.bounds;
    for (final object in objects.skip(1)) {
      bounds = bounds.expandToInclude(object.bounds);
    }
    return bounds;
  }
}
