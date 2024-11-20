/// キャンバスと画像のサイズ調整に関する設定を管理するクラス
class FlexiSketchSizeConfig {
  /// キャンバスの使用可能領域の割合(0.0 - 1.0)
  final double canvasUsableRatio;

  /// キャンバスの最小マージン[px]
  final double minimumMargin;

  const FlexiSketchSizeConfig({
    this.canvasUsableRatio = 0.8,
    this.minimumMargin = 32.0,
  });

  /// デフォルトの設定
  static const FlexiSketchSizeConfig defaultConfig = FlexiSketchSizeConfig();
}
