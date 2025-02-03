import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import '../handlers/save_handler.dart';
import '../tools/eraser_tool.dart';
import '../tools/pen_tool.dart';
import '../tools/shape_tool.dart';
import 'color_button.dart';
import 'stroke_width_button.dart';
import 'tool_button.dart';

/// FlexiSketch のツールバーウィジェット
///
/// 描画ツール、図形ツール、画像操作ツール、編集操作などのツールボタンと、
/// カラーピッカー、ストロークの太さ設定を提供します。
/// モバイル画面でも使いやすいよう、コンパクトな2段組みレイアウトで設計されています。
class Toolbar extends StatefulWidget {
  /// スケッチの状態を管理するコントローラ
  final FlexiSketchController controller;

  /// 画像として保存する際のコールバック
  final SaveSketchAsImage? onSaveAsImage;

  /// データとして保存する際のコールバック
  final SaveSketchAsData? onSaveAsData;

  /// 戻る/進むボタンを非表示にするかどうか
  final bool hideUndoRedo;

  /// クリアボタンを非表示にするかどうか
  final bool hideClear;

  /// 画像アップロードボタンを非表示にするかどうか
  final bool hideUpload;

  /// 画像貼り付けボタンを非表示にするかどうか
  final bool hideImagePaste;

  /// ツールバーウィジェットを作成します。
  ///
  /// [controller] は必須で、スケッチの状態管理を行います。
  /// [isVisible] はツールバーの表示状態を制御します。
  /// [onVisibilityChanged] はツールバーの表示状態が変更されたときに呼び出されます。
  const Toolbar({
    super.key,
    required this.controller,
    this.onSaveAsImage,
    this.onSaveAsData,
    this.hideUndoRedo = false,
    this.hideClear = false,
    this.hideUpload = false,
    this.hideImagePaste = false,
  });

  @override
  State<Toolbar> createState() => ToolbarState();
}

class ToolbarState extends State<Toolbar> with SingleTickerProviderStateMixin {
  /// カラーピッカーの表示状態
  bool _isColorPickerExpanded = false;

  /// 定義済みカラーパレット
  final List<Color> _predefinedColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolbarHandle(),
            const SizedBox(height: 12),
            _buildFileTools(),
            const SizedBox(height: 12),
            _buildDrawingTools(),
            if (_isColorPickerExpanded) ...[
              const SizedBox(height: 12),
              _buildColorPalette(),
            ],
            const SizedBox(height: 12),
            _buildEditingTools(),
          ],
        ),
      ),
    );
  }

  /// ツールバーの上部にあるドラッグハンドルを構築する
  ///
  /// 上方向へのドラッグジェスチャーを検知し、ツールバーの表示/非表示を切り替える
  Widget _buildToolbarHandle() {
    return Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// ファイル操作関連のツールグループを構築する
  ///
  /// 画像保存、データ保存、画像のアップロード、画像の貼り付けなどのファイル操作に関連するツールボタンを提供する
  Widget _buildFileTools() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolGroup([
            if (widget.onSaveAsImage != null)
              ToolButton(
                icon: Icons.image,
                onPressed: () async {
                  final imageData = await widget.controller.generateImageData();
                  if (!mounted) return;
                  widget.onSaveAsImage!(context, imageData);
                },
                tooltip: '画像として保存',
              ),
            if (widget.onSaveAsData != null)
              ToolButton(
                icon: Icons.save,
                onPressed: () async {
                  // 初期状況の通知
                  await widget.onSaveAsData!(context, null, null);

                  // JSONデータ生成中は進捗状況を通知
                  final Map<String, dynamic> jsonData = await widget.controller.generateJsonData(null);

                  // 画像データの生成
                  final Uint8List imageData = await widget.controller.generateImageData();

                  if (!mounted) return;
                  widget.onSaveAsData!(context, jsonData, imageData);
                },
                tooltip: 'データとして保存',
              ),
          ]),
          if (widget.onSaveAsImage != null || widget.onSaveAsData != null) _buildVerticalDivider(),
          _buildToolGroup([
            if (!widget.hideUpload)
              ToolButton(
                icon: Icons.upload_file,
                tooltip: '画像をアップロード',
                onPressed: () => widget.controller.showImagePickerAndAddImage(context),
              ),
            if (!widget.hideImagePaste)
              ToolButton(
                icon: Icons.paste,
                tooltip: '画像を貼り付け',
                onPressed: widget.controller.pasteImageFromClipboard,
              ),
          ]),
        ],
      ),
    );
  }

  /// 描画ツールグループを構築する
  ///
  /// ペン、消しゴム、図形描画、色の選択、線の太さの設定など、描画に関連するツールボタンを提供する
  Widget _buildDrawingTools() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolGroup([
            ToolButton(
              icon: Icons.edit,
              tooltip: 'ペン',
              isSelected: widget.controller.isSpecificToolSelected(PenTool()),
              onPressed: () => widget.controller.toggleTool(PenTool()),
            ),
            ToolButton(
              icon: Icons.auto_fix_high,
              tooltip: '消しゴム',
              isSelected: widget.controller.isSpecificToolSelected(EraserTool()),
              onPressed: () => widget.controller.toggleTool(EraserTool()),
            ),
          ]),
          _buildVerticalDivider(),
          _buildToolGroup([
            ToolButton(
              icon: Icons.crop_square,
              tooltip: '四角形',
              isSelected: widget.controller.isSpecificToolSelected(
                ShapeTool(shapeType: ShapeType.rectangle),
              ),
              onPressed: () => widget.controller.toggleTool(
                ShapeTool(shapeType: ShapeType.rectangle),
              ),
            ),
            ToolButton(
              icon: Icons.circle_outlined,
              tooltip: '円',
              isSelected: widget.controller.isSpecificToolSelected(
                ShapeTool(shapeType: ShapeType.circle),
              ),
              onPressed: () => widget.controller.toggleTool(
                ShapeTool(shapeType: ShapeType.circle),
              ),
            ),
          ]),
          _buildVerticalDivider(),
          _buildToolGroup([
            ColorButton(
              color: widget.controller.currentColor,
              isExpanded: _isColorPickerExpanded,
              onPressed: _toggleColorPicker,
            ),
            StrokeWidthButton(
              strokeWidth: widget.controller.currentStrokeWidth,
              onChanged: widget.controller.setStrokeWidth,
            ),
          ]),
        ],
      ),
    );
  }

  /// 編集ツールグループを構築する
  ///
  /// 元に戻す、やり直す、全て消去などの編集操作に関連するツールボタンを提供する
  Widget _buildEditingTools() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.hideUndoRedo)
            _buildToolGroup([
              ToolButton(
                icon: Icons.undo,
                tooltip: '元に戻す',
                onPressed: widget.controller.canUndo ? widget.controller.undo : null,
              ),
              ToolButton(
                icon: Icons.redo,
                tooltip: 'やり直す',
                onPressed: widget.controller.canRedo ? widget.controller.redo : null,
              ),
            ]),
          if (!widget.hideClear) ...[
            _buildVerticalDivider(),
            _buildToolGroup([
              ToolButton(
                icon: Icons.delete_outline,
                tooltip: '全て消去',
                onPressed: widget.controller.clear,
              ),
            ]),
          ]
        ],
      ),
    );
  }

  /// カラーパレットを構築する
  ///
  /// 定義済みの色から選択できるパレットを提供する
  /// ToolButtonと同じサイズ・デザインで統一感のある表示を行う
  Widget _buildColorPalette() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _predefinedColors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final color = _predefinedColors[index];
          return InkWell(
            onTap: () {
              widget.controller.setColor(color);
              setState(() => _isColorPickerExpanded = false);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// ツールボタンのグループを構築する
  ///
  /// 複数のツールボタンをグループ化し、適切な間隔を設定する
  ///
  /// [children] グループ化するウィジェットのリスト
  Widget _buildToolGroup(List<Widget> children) {
    if (children.isEmpty) {
      return Container();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children.map((child) {
        final int index = children.indexOf(child);
        return Padding(
          padding: EdgeInsets.only(
            left: index == 0 ? 0 : 4,
            right: index == children.length - 1 ? 0 : 4,
          ),
          child: child,
        );
      }).toList(),
    );
  }

  /// ツールグループ間の縦線を構築する
  ///
  /// ツールグループを視覚的に区切るための装飾的な区切り線を提供する
  Widget _buildVerticalDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 24,
        child: VerticalDivider(
          thickness: 1,
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  /// カラーピッカーの表示状態を切り替える
  void _toggleColorPicker() {
    setState(() {
      _isColorPickerExpanded = !_isColorPickerExpanded;
    });
  }

  /// コントローラの状態変更をUIに反映する
  void _onControllerChanged() {
    setState(() {});
  }
}
