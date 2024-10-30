import 'dart:typed_data';

import 'package:pasteboard/pasteboard.dart';

/// クリップボード操作を管理するサービスクラス
class ClipboardService {
  /// クリップボードから画像を取得
  ///
  /// 成功時は画像データ、失敗時は `null` を返します。
  /// エラーが発生した場合は [`ClipboardException`] をスローします。
  static Future<Uint8List?> getImageFromClipboard() async {
    try {
      final hasImage = await Pasteboard.image != null;
      if (!hasImage) {
        return null;
      }

      final imageBytes = await Pasteboard.image;
      if (imageBytes == null || imageBytes.isEmpty) {
        throw const ClipboardException('クリップボード内の画像の取得に失敗しました');
      }

      return imageBytes;
    } catch (e) {
      throw ClipboardException('クリップボードの操作中にエラーが発生しました: $e');
    }
  }
}

/// クリップボード操作に関連するエラー
class ClipboardException implements Exception {
  final String message;

  const ClipboardException(this.message);

  @override
  String toString() => message;
}
