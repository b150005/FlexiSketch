import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'file_handler.dart';
import 'file_handler_mobile.dart';
import 'file_handler_web.dart';

/// FileHandlerのインスタンスを生成するファクトリクラス
class FileHandlerFactory {
  /// プラットフォームに応じたFileHandlerのインスタンスを生成する
  static FileHandler create(BuildContext context) {
    if (kIsWeb) {
      return FileHandlerWeb();
    } else {
      return FileHandlerMobile(context);
    }
  }
}
