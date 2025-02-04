import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'file_handler.dart';

/// モバイル環境でのファイル操作を実装するクラス
class FileHandlerMobile implements FileHandler {
  final BuildContext context;

  FileHandlerMobile(this.context);

  @override
  Future<void> saveJsonFile(String jsonString, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsString(jsonString);

    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile(tempFile.path)],
      subject: 'JSONデータ',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );

    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }

  @override
  Future<String?> loadJsonFile() async {
    try {
      // JSONファイルを選択
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;

      // ファイルの内容を読み込む
      if (file.bytes != null) {
        // Web用のフォールバック（通常はこちらは実行されない）
        return utf8.decode(file.bytes!);
      } else if (file.path != null) {
        // モバイル/デスクトップ
        final jsonFile = File(file.path!);
        if (await jsonFile.exists()) {
          return await jsonFile.readAsString();
        }
      }

      return null;
    } catch (e) {
      // エラーダイアログを表示
      if (!context.mounted) return null;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラー'),
          content: Text('JSONファイルの読み込みに失敗しました: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return null;
    }
  }

  @override
  Future<void> saveImageFile(Uint8List imageData, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(imageData);

    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile(tempFile.path)],
      subject: '画像データ',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );

    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }
}
