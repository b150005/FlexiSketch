import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'file_handler.dart';

/// Web環境でのファイル操作を実装するクラス
class FileHandlerImpl implements FileHandler {
  final BuildContext context;

  FileHandlerImpl(this.context);

  @override
  Future<void> saveJsonFile(String jsonString, String fileName) async {
    final bytes = utf8.encode(jsonString);
    final array = bytes.toJS;
    final options = web.BlobPropertyBag(type: 'application/json');
    final parts = [array].toJS;
    final blob = web.Blob(parts, options);
    final url = web.URL.createObjectURL(blob);

    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }

  @override
  Future<String?> loadJsonFile() async {
    try {
      // input要素を作成
      final input = web.HTMLInputElement()
        ..type = 'file'
        ..accept = '.json'
        ..style.display = 'none';

      web.document.body!.append(input);
      input.click();

      // ファイル選択完了を待つ
      final completer = Completer<String?>();

      input.onChange.listen((event) async {
        final files = input.files;
        if (files == null || files.length == 0) {
          completer.complete(null);
          return;
        }

        final file = files.item(0);
        if (file == null) {
          completer.complete(null);
          return;
        }

        final reader = web.FileReader();

        reader.onLoadEnd.listen((_) {
          if (reader.result case String text) {
            completer.complete(text);
          } else {
            completer.complete(null);
          }
        });

        reader.readAsText(file);
      });

      input.remove();

      return await completer.future;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveImageFile(Uint8List imageData, String fileName) async {
    final array = imageData.toJS;
    final options = web.BlobPropertyBag(type: 'image/png');
    final parts = [array].toJS;
    final blob = web.Blob(parts, options);
    final url = web.URL.createObjectURL(blob);

    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }
}
