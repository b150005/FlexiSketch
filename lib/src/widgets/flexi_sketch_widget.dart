import 'dart:developer' as developer;

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
  /// スケッチの状態を管理するコントローラ
  ///
  /// このコントローラを通じて、描画ツールの選択、色の変更、Undo/Redoなどの操作を行うことができます。
  final FlexiSketchController controller;

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
    required this.controller,
    this.onSaveAsImage,
    this.onSaveAsData,
    this.data,
    this.onError,
  });

  @override
  State<FlexiSketchWidget> createState() => FlexiSketchWidgetState();
}

class FlexiSketchWidgetState extends State<FlexiSketchWidget> {
  // 保存処理用の進捗状態
  bool _isSaving = false;

  /// InfiniteCanvasへの参照
  final GlobalKey<InfiniteCanvasState> _canvasKey = GlobalKey<InfiniteCanvasState>();

  @override
  void initState() {
    super.initState();
    widget.controller.onError = widget.onError;
    _initializeWithData();
  }

  @override
  void didUpdateWidget(FlexiSketchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _initializeWithData();
    }
    widget.controller.onError = widget.onError;
  }

  @override
  void dispose() {
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
        child: SafeArea(
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
                  return InfiniteCanvas(
                    key: _canvasKey,
                    controller: widget.controller,
                  );
                },
              ),
              // ツールバー
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: Toolbar(
                    controller: widget.controller,
                    onSaveAsImage: widget.onSaveAsImage != null
                        ? (context, imageData) async {
                            setState(() {
                              _isSaving = true;
                            });

                            try {
                              await widget.onSaveAsImage!(context, imageData);
                            } finally {
                              setState(() {
                                _isSaving = false;
                              });
                            }
                          }
                        : null,
                    onSaveAsData: widget.onSaveAsData != null
                        ? (context, jsonData, imageData) async {
                            setState(() {
                              _isSaving = true;
                            });

                            try {
                              await widget.onSaveAsData!(context, jsonData, imageData);
                            } catch (e) {
                              developer.log(e.toString());
                            } finally {
                              setState(() {
                                _isSaving = false;
                              });
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
                              const Text('保存中...'),
                              const SizedBox(
                                height: 3,
                              ),
                              const Text(
                                'この処理には時間がかかります',
                                style: TextStyle(fontSize: 12),
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

  /// 初期データを読み込んでキャンバスを初期化します。
  ///
  /// このメソッドは以下の処理を順次実行します：
  /// 1. JSONデータが存在する場合、そのデータをコントローラを通じて読み込みます
  /// 2. データの読み込みが完了したら、キャンバスの初期変換を設定します
  ///
  /// データの読み込み中にエラーが発生した場合は、 [widget.onError] を通じてエラーメッセージが通知されます。
  Future<void> _initializeWithData() async {
    if (widget.data != null) {
      try {
        await widget.controller.loadFromJson(widget.data!);
        // データ読み込み後にキャンバスの初期変換を設定
        _canvasKey.currentState?.setInitialTransform();
      } catch (e) {
        widget.onError?.call('データの読み込みに失敗しました: $e');
      }
    }
  }
}
