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
  State<FlexiSketchWidget> createState() => FlexiSketchWidgetState();
}

class FlexiSketchWidgetState extends State<FlexiSketchWidget> with ProgressHandler {
  /// スケッチの状態を管理するコントローラ
  ///
  /// このコントローラを通じて、描画ツールの選択、色の変更、Undo/Redoなどの操作を行うことができます。
  final FlexiSketchController _controller = FlexiSketchController();

  /// スケッチの状態を管理するコントローラ
  ///
  /// このコントローラを通じて、描画ツールの選択、色の変更、Undo/Redoなどの操作を行うことができます。
  FlexiSketchController get controller => _controller;

  // 保存処理用の進捗状態
  bool _isSaving = false;
  double _saveProgress = 0.0;

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
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: Toolbar(
                    controller: _controller,
                    onSaveAsImage: widget.onSaveAsImage != null
                        ? (imageData) async {
                            setState(() {
                              _isSaving = true;
                              _saveProgress = 0.0;
                            });

                            try {
                              await widget.onSaveAsImage!(imageData);
                            } finally {
                              setState(() {
                                _isSaving = false;
                              });
                            }
                          }
                        : null,
                    onSaveAsData: widget.onSaveAsData != null
                        ? (jsonData, imageData, progress) async {
                            setState(() {
                              _isSaving = true;
                              _saveProgress = progress;
                            });

                            try {
                              await widget.onSaveAsData!(jsonData, imageData, progress);
                            } finally {
                              if (progress >= 1.0) {
                                setState(() {
                                  _isSaving = false;
                                });
                              }
                            }
                          }
                        : null,
                  ),
                ),
              ),
              // 保存中のプログレスインジケーター
              if (_isSaving)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                value: _saveProgress,
                              ),
                              const SizedBox(height: 16),
                              const Text('保存中...'),
                              Text(
                                '${(_saveProgress * 100).toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
