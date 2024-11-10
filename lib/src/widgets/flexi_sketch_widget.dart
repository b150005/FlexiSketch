import 'package:flexi_sketch/src/utils/progress_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../flexi_sketch_controller.dart';
import '../canvas/infinite_canvas.dart';
import '../handlers/save_handler.dart';
import 'toolbar.dart';

/// FlexiSketch のメインウィジェット
///
/// キャンバス・ツールバー・カラーパレット・線幅スライダーなどを含みます。
/// 状態管理は [controller] で行い、保存処理は [saveAsImage] と [saveAsData] で定義します。
class FlexiSketchWidget extends StatefulWidget {
  /// 画像として保存する際のコールバック
  final SaveSketchAsImage? onSaveAsImage;

  /// データとして保存する際のコールバック
  final SaveSketchAsData? onSaveAsData;

  /// 初期データ（JSONオブジェクト）
  final Map<String, dynamic>? data;

  /// エラー発生時のコールバック
  final void Function(String message)? onError;

  /// FlexiSketchウィジェットを作成します。
  ///
  /// [controller] は必須で、スケッチの状態管理を行います。
  const FlexiSketchWidget({
    super.key,
    this.onSaveAsImage,
    this.onSaveAsData,
    this.data,
    this.onError,
  });

  @override
  State<FlexiSketchWidget> createState() => _FlexiSketchWidgetState();
}

class _FlexiSketchWidgetState extends State<FlexiSketchWidget> with ProgressHandler {
  /// スケッチの状態を管理するコントローラ
  ///
  /// このコントローラを通じて、描画ツールの選択、色の変更、Undo/Redoなどの操作を行うことができます。
  final FlexiSketchController _controller = FlexiSketchController();

  @override
  void initState() {
    super.initState();
    _controller.onError = widget.onError;
    _initializeWithData();
  }

  @override
  void didUpdateWidget(FlexiSketchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _initializeWithData();
    }
    _controller.onError = widget.onError;
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
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _controller.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): _controller.redo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _controller.redo,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): _controller.pasteImageFromClipboard,
      },
      child: Focus(
        autofocus: true,
        child: SafeArea(
          child: Stack(
            children: [
              // キャンバス
              LayoutBuilder(
                builder: (context, constraints) {
                  // キャンバスサイズの更新
                  _controller.updateCanvasSize(Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ));
                  return InfiniteCanvas(controller: _controller);
                },
              ),
              // ツールバー
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Toolbar(
                  controller: _controller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeWithData() async {
    if (widget.data != null) {
      try {
        await _controller.loadFromJson(widget.data!);
      } catch (e) {
        widget.onError?.call('データの読み込みに失敗しました: $e');
      }
    }
  }
}
