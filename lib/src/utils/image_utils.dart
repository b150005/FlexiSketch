import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);
    return base64Encode(bytes);
  }
}
