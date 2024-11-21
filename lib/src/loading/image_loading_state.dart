/// 画像読み込み状態を表すクラス
class ImageLoadingState {
  /// 処理の進捗率 (0.0 ~ 1.0)
  final double progress;

  /// 現在の処理フェーズ
  final ImageLoadingPhase phase;

  /// 処理中にエラーが発生した場合のエラー情報
  final Object? error;

  const ImageLoadingState({
    required this.progress,
    required this.phase,
    this.error,
  });

  /// 初期状態
  static const initial = ImageLoadingState(
    progress: 0.0,
    phase: ImageLoadingPhase.initial,
  );

  /// エラー状態を生成
  static ImageLoadingState withError(Object error) => ImageLoadingState(
        progress: 0.0,
        phase: ImageLoadingPhase.error,
        error: error,
      );

  /// 完了状態かどうか
  bool get isCompleted => phase == ImageLoadingPhase.completed;

  /// エラー状態かどうか
  bool get hasError => error != null;
}

/// 画像読み込みの処理フェーズ
enum ImageLoadingPhase {
  /// 初期状態
  initial,

  /// 画像のデコード中
  decoding,

  /// 画像オブジェクトの生成中
  creating,

  /// JSONデータの生成中
  serializing,

  /// 完了
  completed,

  /// エラー
  error;

  String get message => switch (this) {
        ImageLoadingPhase.initial => '準備中...',
        ImageLoadingPhase.decoding => '画像を読み込んでいます...',
        ImageLoadingPhase.creating => '画像を処理しています...',
        ImageLoadingPhase.serializing => 'データを生成しています...',
        ImageLoadingPhase.completed => '完了',
        ImageLoadingPhase.error => 'エラーが発生しました',
      };
}

/// 進捗状況を通知するためのコールバック型
typedef ProgressCallback = void Function(ImageLoadingState state);
