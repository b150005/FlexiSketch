import 'dart:ui' as ui;
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import '../config/flexi_sketch_size_config.dart';
import '../objects/image_object.dart';
import 'flexi_sketch_size_helper.dart';

/// Uint8List の画像データから ImageObject や FlexiSketch の初期データを生成するヘルパークラス
class FlexiSketchDataHelper {
  /// 画像データから ImageObject を生成する
  ///
  /// 返却値は生成された ImageObject と、計算されたキャンバスサイズのタプル
  ///
  /// [imageData] 画像のバイトデータ
  /// [config] サイズ調整の設定
  /// [canvasSize] キャンバスのサイズ（省略時は画像サイズから計算）
  static Future<(ImageObject, Size)> createImageObjectFromBytes(
    Uint8List imageData, {
    FlexiSketchSizeConfig config = FlexiSketchSizeConfig.defaultConfig,
    Size? canvasSize,
  }) async {
    // 画像をデコード
    final ui.Image decodedImage = await decodeImageFromBytes(imageData);

    // 画像の元サイズを取得
    final Size imageSize = Size(
      decodedImage.width.toDouble(),
      decodedImage.height.toDouble(),
    );

    // キャンバスサイズの決定
    final Size effectiveCanvasSize = canvasSize ??
        FlexiSketchSizeHelper.calculateCanvasSize(
          imageSize: imageSize,
          config: config,
        );

    // 画像の表示サイズを計算
    final Size displaySize = FlexiSketchSizeHelper.calculateDisplaySize(
      imageSize: imageSize,
      canvasSize: effectiveCanvasSize,
      config: config,
    );

    // 画像オブジェクトを生成
    final ImageObject imageObject = createImageObject(
      image: decodedImage,
      center: getCanvasCenter(effectiveCanvasSize),
      size: displaySize,
    );

    return (imageObject, effectiveCanvasSize);
  }

  /// 画像データから FlexiSketch の初期データを生成する
  ///
  /// [imageData] 画像のバイトデータ
  /// [width] キャンバスの幅（省略時は画像サイズを使用）
  /// [height] キャンバスの高さ（省略時は画像サイズを使用）
  static Future<Map<String, dynamic>> createInitialDataFromImage(
    Uint8List imageData, {
    double? width,
    double? height,
    FlexiSketchSizeConfig config = FlexiSketchSizeConfig.defaultConfig,
  }) async {
    final FlexiSketchController controller = FlexiSketchController();

    try {
      final Size? canvasSize = width != null && height != null ? Size(width, height) : null;

      // 画像オブジェクトの生成
      final (ImageObject imageObject, Size effectiveCanvasSize) = await createImageObjectFromBytes(
        imageData,
        config: config,
        canvasSize: canvasSize,
      );

      // コントローラの設定
      controller.updateCanvasSize(effectiveCanvasSize);
      controller.objects.add(imageObject);

      // JSONデータを生成
      final Map<String, dynamic> result = await controller.generateJsonData(null);

      return result;
    } catch (e) {
      developer.log(e.toString());
      rethrow;
    } finally {
      controller.dispose();
    }
  }

  /// バイトデータから画像をデコードする
  ///
  /// [imageData] 画像のバイトデータ
  static Future<ui.Image> decodeImageFromBytes(Uint8List imageData) async {
    final ui.Codec codec = await ui.instantiateImageCodec(imageData);
    final ui.FrameInfo frame = await codec.getNextFrame();
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
    final Size imageSize = size ??
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
