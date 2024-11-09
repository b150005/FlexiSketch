import 'package:flexi_sketch/src/utils/progress_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../flexi_sketch_controller.dart';
import '../canvas/infinite_canvas.dart';
import 'toolbar.dart';

/// FlexiSketch のメインウィジェット
///
/// キャンバス・ツールバー・カラーパレット・線幅スライダーなどを含みます。
/// 状態管理は [controller] で行い、保存処理は [saveAsImage] と [saveAsData] で定義します。
class FlexiSketchWidget extends StatefulWidget {
  /// スケッチの状態を管理するコントローラ
  ///
  /// このコントローラを通じて、描画ツールの選択・色の変更・アンドゥ/リドゥなどの
  /// 操作を行うことができます。
  final FlexiSketchController controller;

  /// FlexiSketchウィジェットを作成します。
  ///
  /// [controller] は必須で、スケッチの状態管理を行います。
  const FlexiSketchWidget({
    super.key,
    required this.controller,
  });

  @override
  State<FlexiSketchWidget> createState() => _FlexiSketchWidgetState();
}

class _FlexiSketchWidgetState extends State<FlexiSketchWidget> with ProgressHandler {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    widget.controller.onError = _showError;
  }

  @override
  void dispose() {
    // ProgressHandler の dispose を呼び出す
    disposeProgress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): widget.controller.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): widget.controller.redo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): widget.controller.redo,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): widget.controller.pasteImageFromClipboard,
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
                      widget.controller.updateCanvasSize(Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ));
                      return InfiniteCanvas(controller: widget.controller);
                    },
                  ),
                  // ツールバー
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Toolbar(
                      controller: widget.controller,
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
