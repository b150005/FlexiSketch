import 'package:flutter/material.dart';

import 'file_handler.dart';
import 'file_handler_mobile.dart' if (dart.library.html) 'file_handler_web.dart';

/// FileHandlerのインスタンスを生成するファクトリクラス
class FileHandlerFactory {
  /// プラットフォームに応じたFileHandlerのインスタンスを生成する
  static FileHandler create(BuildContext context) {
    return FileHandlerImpl(context);
  }
}
