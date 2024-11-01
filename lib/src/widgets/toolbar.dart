import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
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

  const Toolbar({super.key, required this.controller});

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> with SingleTickerProviderStateMixin {
  /// ツールバーの表示アニメーションを制御するコントローラ
  late AnimationController _controller;

  /// フェードインアニメーションの定義
  late Animation<double> _fadeAnimation;

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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 上段：描画ツール、図形ツール、画像ツール、カラーピッカー
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 描画ツール群
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
                // 図形ツール群
                _buildToolGroup([
                  ToolButton(
                    icon: Icons.crop_square,
                    tooltip: '四角形',
                    isSelected: widget.controller.isSpecificToolSelected(ShapeTool(shapeType: ShapeType.rectangle)),
                    onPressed: () => widget.controller.toggleTool(ShapeTool(shapeType: ShapeType.rectangle)),
                  ),
                  ToolButton(
                    icon: Icons.circle_outlined,
                    tooltip: '円',
                    isSelected: widget.controller.isSpecificToolSelected(ShapeTool(shapeType: ShapeType.circle)),
                    onPressed: () => widget.controller.toggleTool(ShapeTool(shapeType: ShapeType.circle)),
                  ),
                ]),
                _buildVerticalDivider(),
                // 画像ツール群
                _buildToolGroup([
                  ToolButton(
                    icon: Icons.upload_file,
                    tooltip: '画像をアップロード',
                    onPressed: widget.controller.pickAndAddImage,
                  ),
                  ToolButton(
                    icon: Icons.paste,
                    tooltip: '画像を貼り付け',
                    onPressed: widget.controller.pasteImageFromClipboard,
                  ),
                ]),
                _buildVerticalDivider(),
                // カラーピッカーとストローク幅
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
            // カラーピッカー（展開時のみ表示）
            if (_isColorPickerExpanded) ...[
              const SizedBox(height: 8),
              _buildColorPalette(),
            ],
            const SizedBox(height: 8),
            // 下段：編集操作
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                _buildVerticalDivider(),
                _buildToolGroup([
                  ToolButton(
                    icon: Icons.delete_outline,
                    tooltip: '全て消去',
                    onPressed: widget.controller.clear,
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// カラーパレットを構築する
  Widget _buildColorPalette() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _predefinedColors.map((color) {
        return InkWell(
          onTap: () {
            widget.controller.setColor(color);
            setState(() => _isColorPickerExpanded = false);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// ツールグループを構築する
  Widget _buildToolGroup(List<Widget> children) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children.map((child) {
        final index = children.indexOf(child);
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

  /// 区切り線を構築する
  Widget _buildVerticalDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 24,
        child: VerticalDivider(
          thickness: 1,
          color: Colors.grey.withOpacity(0.3),
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

  void _onControllerChanged() {
    setState(() {});
  }
}
