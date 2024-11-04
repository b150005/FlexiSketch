import 'package:flexi_sketch/src/utils/progress_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../flexi_sketch_controller.dart';
import '../canvas/infinite_canvas.dart';
import '../storage/sketch_storage.dart';
import 'save_dialog.dart';
import 'sketch_list.dart';
import 'toolbar.dart';

/// FlexiSketch のメインウィジェット
///
/// キャンバス・ツールバー・カラーパレット・線幅スライダーなどを含みます。
/// 全ての状態管理は [controller] で行うため、このウィジェットは `StatelessWidget` として実装しています。
class FlexiSketchWidget extends StatefulWidget {
  /// スケッチの状態を管理するコントローラ
  final FlexiSketchController controller;

  const FlexiSketchWidget({super.key, required this.controller});

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
                      onSave: () => _handleSave(context),
                      onOpen: () => _handleOpen(context),
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

  // 保存処理
  Future<void> _handleSave(BuildContext context) async {
    try {
      showProgress(context, '保存中...');
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const SaveDialog(),
      );

      if (result != null) {
        await widget.controller.saveSketch(
          title: result['title'] as String,
          asImage: result['asImage'] as bool,
        );
        hideProgress();
        if (context.mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('保存しました')),
          );
        }
      } else {
        hideProgress();
      }
    } catch (e) {
      if (context.mounted) {
        showError(
          context,
          '保存に失敗しました: $e',
          onRetry: () => _handleSave(context),
        );
      }
    }
  }

  // 読み込み処理
  Future<void> _handleOpen(BuildContext context) async {
    try {
      final storage = widget.controller.storage;
      if (storage == null) {
        throw Exception('ストレージが設定されていません');
      }

      final controller = SketchListController(storage);
      final metadata = await showDialog<SketchMetadata>(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: 800,
            height: 600,
            child: Column(
              children: [
                AppBar(
                  title: const Text('スケッチを開く'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: SketchList(
                    controller: controller,
                    onSketchTap: (metadata) => Navigator.of(context).pop(metadata),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (metadata != null && context.mounted) {
        showProgress(context, '読み込み中...');
        await widget.controller.loadSketch(metadata.id);
        hideProgress();
        if (context.mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('読み込みました')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showError(
          context,
          '読み込みに失敗しました: $e',
          onRetry: () => _handleOpen(context),
        );
      }
    }
  }
}
