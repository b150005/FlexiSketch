import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../flexi_sketch_controller.dart';
import '../canvas/infinite_canvas.dart';
import 'toolbar.dart';

/// FlexiSketch のメインウィジェット
///
/// キャンバス・ツールバー・カラーパレット・線幅スライダーなどを含みます。
/// 全ての状態管理は [controller] で行うため、このウィジェットは `StatelessWidget` として実装しています。
class FlexiSketchWidget extends StatelessWidget {
  /// スケッチの状態を管理するコントローラ
  final FlexiSketchController controller;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  FlexiSketchWidget({super.key, required this.controller}) {
    controller.onError = _showError;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): controller.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): controller.redo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): controller.redo,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): controller.pasteImageFromClipboard,
      },
      child: Focus(
        autofocus: true,
        child: ScaffoldMessenger(
          key: _scaffoldMessengerKey,
          child: Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  // キャンバス
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // キャンバスサイズの更新
                      controller.updateCanvasSize(Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ));
                      return InfiniteCanvas(controller: controller);
                    },
                  ),
                  // ツールバー（下部中央に配置）
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Toolbar(controller: controller),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// エラーメッセージを SnackBar で表示する
  ///
  /// [message] 表示するエラーメッセージ
  void _showError(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8.0),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
          label: '閉じる',
          textColor: Colors.white,
          onPressed: () => _scaffoldMessengerKey.currentState?.hideCurrentSnackBar),
    ));
  }
}
