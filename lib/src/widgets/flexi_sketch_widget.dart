import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart';
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

  /// `Toolbar` のウィジェットサイズを測定するために使用する `GlobalKey`
  ///
  /// このキーを使用して `Toolbar` の実際のサイズを取得し、画面内に収まるように位置を制限します。
  final GlobalKey _toolbarKey = GlobalKey<ToolbarState>();

  /// `Toolbar` の表示位置
  ///
  /// この値は画面サイズと `Toolbar` のサイズに基づいて制限されます。
  Offset _toolbarPosition = Offset.zero;

  /// `Toolbar` の実際のウィジェットサイズ
  ///
  /// `LayoutBuilder` と `PostFrameCallback` で測定された `Toolbar` の実際の幅と高さを保持します。
  Size _toolbarSize = Size.zero;

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
    final Size screenSize = MediaQuery.of(context).size;
    _initializeToolbarPosition(screenSize);

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
                left: _toolbarPosition.dx,
                top: _toolbarPosition.dy,
                child: LayoutBuilder(builder: (context, constraints) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final RenderBox? renderBox = _toolbarKey.currentContext?.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      final Size size = renderBox.size;
                      if (size != _toolbarSize) {
                        setState(() {
                          _toolbarSize = size;
                          _adjustToolbarPosition(screenSize);
                        });
                      }
                    }
                  });

                  return GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _toolbarPosition += details.delta;
                        // 画面外に出ないように制限
                        _adjustToolbarPosition(screenSize);
                      });
                    },
                    child: Container(
                      key: _toolbarKey,
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
                  );
                }),
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

  /// AppBarの高さを取得します
  ///
  /// 現在のコンテキストから `AppBar` の高さを取得します。
  /// `AppBar` が存在しない場合は 0 を返します。
  double _getAppBarHeight(BuildContext context) {
    final ScaffoldState? scaffold = Scaffold.maybeOf(context);
    if (scaffold == null) return 0;

    final AppBar? appBar = scaffold.widget.appBar as AppBar?;
    return appBar?.preferredSize.height ?? 0;
  }

  /// `Toolbar` の位置を画面内に収めるように調整します
  ///
  /// [screenSize] 現在の画面サイズ
  ///
  /// `Toolbar` の実際のサイズ、`AppBar` の高さ、および `SafeArea` の余白に基づいて、画面からはみ出さないように位置を制限します。
  void _adjustToolbarPosition(Size screenSize) {
    final double appBarHeight = _getAppBarHeight(context);

    // FIXME: iOS だと下に見切れてしまうが、画面を有効活用できるので現時点では OK とする
    _toolbarPosition = Offset(
      _toolbarPosition.dx.clamp(0.01, screenSize.width - _toolbarSize.width), // 第1引数を0に設定すると左上に移動させたときに初期位置に戻されてしまう
      _toolbarPosition.dy.clamp(0, screenSize.height - appBarHeight - _toolbarSize.height),
    );
  }

  /// `Toolbar` の初期位置を画面中央下部に設定します
  ///
  /// [screenSize] 現在の画面サイズ
  ///
  /// `Toolbar` が未配置の場合（`_toolbarPosition == Offset.zero`）、画面の中央下部に配置します。
  void _initializeToolbarPosition(Size screenSize) {
    if (_toolbarPosition == Offset.zero) {
      final double appBarHeight = _getAppBarHeight(context);
      final ViewPadding padding = View.of(context).padding;

      _toolbarPosition = Offset(
        screenSize.width / 3,
        screenSize.height - appBarHeight - padding.top - padding.bottom,
      );
    }
  }
}
