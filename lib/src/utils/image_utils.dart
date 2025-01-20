import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

class ImageUtils {
  /// Base64エンコードされた画像データをデコードしてui.Imageオブジェクトを生成する
  static Future<ui.Image> decodeBase64Image(String encodedData) async {
    final bytes = base64Decode(encodedData);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// ui.Imageオブジェクトをbase64エンコードされた文字列に変換する
  static Future<String> encodeImageToBase64(ui.Image image) async {
    // バイトデータに変換
    final ByteData? byteData = await image.toByteData(
      // TIP: .png だと処理が遅くUIブロッキングが生じる, .rawRgba だとUIブロッキングは発生しないが描画できないことがあるので×, それ以外のオプションは未検証
      format: ui.ImageByteFormat.png,
    );
    final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);

    final encodedImage = base64Encode(bytes); // TIP: ByteData → String の変換も Image → ByteData の変換と同様UIスレッドのブロッキングが生じる

    return encodedImage;
  }
}
