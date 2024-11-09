/// FlexiSketchで発生するエラーの基底クラス
abstract class FlexiSketchError implements Exception {
  /// エラーメッセージ
  final String message;

  /// エラーの原因となった例外（オプショナル）
  final Object? cause;

  const FlexiSketchError(this.message, [this.cause]);

  @override
  String toString() => 'FlexiSketchError: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// 保存処理に関連するエラー
class SaveError extends FlexiSketchError {
  const SaveError(super.message, [super.cause]);
}

/// 保存処理が設定されていない場合のエラー
class SaveHandlerNotSetError extends SaveError {
  const SaveHandlerNotSetError(String type) : super('Save handler for $type is not set');
}

/// 画像の生成に失敗した場合のエラー
class ImageGenerationError extends SaveError {
  const ImageGenerationError(super.message, [super.cause]);
}

/// データの生成に失敗した場合のエラー
class DataGenerationError extends SaveError {
  const DataGenerationError(super.message, [super.cause]);
}
