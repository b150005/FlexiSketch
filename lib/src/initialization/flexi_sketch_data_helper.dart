import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import '../objects/image_object.dart';

/// Uint8List の画像データから ImageObject や FlexiSketch の初期データを生成するヘルパークラス
class FlexiSketchDataHelper {
  /// 画像データから FlexiSketch の初期データを生成する
  ///
  /// [imageData] 画像のバイトデータ
  /// [width] キャンバスの幅（省略時は画像サイズを使用）
  /// [height] キャンバスの高さ（省略時は画像サイズを使用）
  static Future<Map<String, dynamic>> createInitialDataFromImage(
    Uint8List imageData, {
    double? width,
    double? height,
  }) async {
    // 一時的なコントローラを作成
    final controller = FlexiSketchController();

    try {
      // 画像をデコード
      final decodedImage = await decodeImageFromBytes(imageData);

      // キャンバスサイズの設定
      // FIXME: 画像サイズをもとに画像を貼付する処理は共通化できそう(FlexiSketchController#addImageFromBytes の画像の貼付位置も現在描画しているキャンバス領域の中心などに調整する必要がある)
      final canvasWidth = width ?? decodedImage.width.toDouble();
      final canvasHeight = height ?? decodedImage.height.toDouble();
      controller.updateCanvasSize(Size(canvasWidth, canvasHeight));

      // 画像オブジェクトを生成してコントローラに追加
      final imageObject = createImageObject(
        image: decodedImage,
        center: getCanvasCenter(Size(canvasWidth, canvasHeight)),
      );
      controller.objects.add(imageObject);

      // コントローラを使用してJSONデータを生成
      return await controller.generateJsonData();
    } finally {
      // 一時的なコントローラを破棄
      controller.dispose();
    }
  }

  /// バイトデータから画像をデコードする
  ///
  /// [imageData] 画像のバイトデータ
  static Future<ui.Image> decodeImageFromBytes(Uint8List imageData) async {
    final codec = await ui.instantiateImageCodec(imageData);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// ImageObject を生成する
  ///
  /// [image] 画像データ
  /// [center] 画像の中心座標
  /// [size] 画像のサイズ（省略時は画像の元のサイズを使用）
  static ImageObject createImageObject({
    required ui.Image image,
    required Offset center,
    Size? size,
  }) {
    final imageSize = size ??
        Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );

    return ImageObject(
      image: image,
      globalCenter: center,
      size: imageSize,
    );
  }

  /// キャンバスの中心座標を取得する
  ///
  /// [canvasSize] キャンバスのサイズ
  static Offset getCanvasCenter(Size canvasSize) {
    return Offset(
      canvasSize.width / 2,
      canvasSize.height / 2,
    );
  }
}
