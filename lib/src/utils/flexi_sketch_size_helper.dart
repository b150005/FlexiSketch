import 'package:flutter/material.dart';

import '../config/flexi_sketch_size_config.dart';

/// 画像とキャンバスのサイズ計算を行うヘルパークラス
class FlexiSketchSizeHelper {
  /// アスペクト比を計算する
  ///
  /// [size] アスペクト比を計算するサイズ
  ///
  /// 返却値は width / height で計算されたアスペクト比
  /// 高さが0の場合は [double.infinity] を返す
  static double calculateAspectRatio(Size size) {
    if (size.height == 0) return double.infinity;
    return size.width / size.height;
  }

  /// 画像サイズとキャンバスサイズから、適切な表示サイズを計算する
  ///
  /// 返却値は計算された表示サイズ。アスペクト比は維持される
  ///
  /// [imageSize] 元の画像サイズ
  /// [canvasSize] 現在のキャンバスサイズ
  /// [config] サイズ調整の設定
  static Size calculateDisplaySize({
    required Size imageSize,
    required Size canvasSize,
    FlexiSketchSizeConfig config = FlexiSketchSizeConfig.defaultConfig,
  }) {
    // キャンバスの使用可能な最大領域を計算
    final maxWidth = canvasSize.width * config.canvasUsableRatio;
    final maxHeight = canvasSize.height * config.canvasUsableRatio;

    // 画像のアスペクト比を計算
    final aspectRatio = calculateAspectRatio(imageSize);
    final maxAreaAspectRatio = calculateAspectRatio(Size(maxWidth, maxHeight));

    // 使用可能領域に収まるようにアスペクト比を維持しながらサイズを計算
    double width;
    double height;
    if (maxAreaAspectRatio > aspectRatio) {
      // 高さに合わせる
      height = maxHeight;
      width = height * aspectRatio;
    } else {
      // 幅に合わせる
      width = maxWidth;
      height = width / aspectRatio;
    }

    return Size(width, height);
  }

  /// キャンバスに画像を配置する際の適切なキャンバスサイズを計算する
  ///
  /// [imageSize] 画像サイズ
  /// [config] サイズ調整の設定
  ///
  /// 返却値は必要なキャンバスサイズ
  static Size calculateCanvasSize({
    required Size imageSize,
    FlexiSketchSizeConfig config = FlexiSketchSizeConfig.defaultConfig,
  }) {
    final margin = config.minimumMargin * 2;
    return Size(
      imageSize.width / config.canvasUsableRatio + margin,
      imageSize.height / config.canvasUsableRatio + margin,
    );
  }
}
