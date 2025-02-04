import 'dart:typed_data';

/// ファイル操作を抽象化するインターフェース
abstract class FileHandler {
  /// JSONファイルを保存する
  Future<void> saveJsonFile(String jsonString, String fileName);

  /// JSONファイルを読み込む
  Future<String?> loadJsonFile();

  /// 画像ファイルを保存する
  Future<void> saveImageFile(Uint8List imageData, String fileName);
}
