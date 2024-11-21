import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import '../config/flexi_sketch_size_config.dart';
import '../loading/image_loading_state.dart';
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
    final decodedImage = await decodeImageFromBytes(imageData);

    // 画像の元サイズを取得
    final imageSize = Size(
      decodedImage.width.toDouble(),
      decodedImage.height.toDouble(),
    );

    // キャンバスサイズの決定
    final effectiveCanvasSize = canvasSize ??
        FlexiSketchSizeHelper.calculateCanvasSize(
          imageSize: imageSize,
          config: config,
        );

    // 画像の表示サイズを計算
    final displaySize = FlexiSketchSizeHelper.calculateDisplaySize(
      imageSize: imageSize,
      canvasSize: effectiveCanvasSize,
      config: config,
    );

    // 画像オブジェクトを生成
    final imageObject = createImageObject(
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
    ProgressCallback? onProgress,
  }) async {
    final controller = FlexiSketchController();

    try {
      onProgress?.call(ImageLoadingState(
        progress: 0.0,
        phase: ImageLoadingPhase.decoding,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final canvasSize = width != null && height != null ? Size(width, height) : null;

      // 画像オブジェクトの生成
      final (imageObject, effectiveCanvasSize) = await createImageObjectFromBytes(
        imageData,
        config: config,
        canvasSize: canvasSize,
      );

      onProgress?.call(ImageLoadingState(
        progress: 0.023,
        phase: ImageLoadingPhase.creating,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // コントローラの設定
      controller.updateCanvasSize(effectiveCanvasSize);
      controller.objects.add(imageObject);

      onProgress?.call(ImageLoadingState(
        progress: 0.046,
        phase: ImageLoadingPhase.serializing,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // JSONデータを生成
      final result = await controller.generateJsonData(
        null, // metadata
        (progress) async {
          // 4.6%から100%までの範囲で進捗を通知
          final totalProgress = 0.046 + (progress * 0.954);
          onProgress?.call(ImageLoadingState(
            progress: totalProgress,
            phase: ImageLoadingPhase.serializing,
          ));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        },
      );

      onProgress?.call(ImageLoadingState(
        progress: 1.0,
        phase: ImageLoadingPhase.completed,
      ));
      // 完了 UI は表示されなくても問題ないのでコメントアウト
      // await Future<void>.delayed(const Duration(milliseconds: 50));

      return result;
    } catch (e) {
      onProgress?.call(ImageLoadingState.withError(e));
      rethrow;
    } finally {
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
