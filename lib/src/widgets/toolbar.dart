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

  /// ツールバーの表示状態
  final bool isVisible;

  /// ツールバーの表示状態を変更するコールバック
  final ValueChanged<bool>? onVisibilityChanged;

  /// 保存ボタンが押されたときのコールバック
  final VoidCallback? onSave;

  /// 開くボタンが押されたときのコールバック
  final VoidCallback? onOpen;

  const Toolbar({
    super.key,
    required this.controller,
    this.isVisible = true,
    this.onVisibilityChanged,
    this.onSave,
    this.onOpen,
  });

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
    if (widget.isVisible) {
      _controller.forward();
    }
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(Toolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 100 * (1 - _fadeAnimation.value)),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // ジェスチャーをここで止める
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: MediaQuery.of(context).size.height > 600 ? 16 : 8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
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
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarHandle() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          widget.onVisibilityChanged?.call(false);
        }
      },
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildFileTools() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolGroup([
            ToolButton(
              icon: Icons.save,
              tooltip: '保存',
              onPressed: widget.onSave,
            ),
            ToolButton(
              icon: Icons.folder_open,
              tooltip: '開く',
              onPressed: widget.onOpen,
            ),
          ]),
          _buildVerticalDivider(),
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
        ],
      ),
    );
  }

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

  Widget _buildEditingTools() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
    );
  }

  Widget _buildColorPalette() {
    return SizedBox(
      height: 36, // ToolButtonと同じ高さ
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
            borderRadius: BorderRadius.circular(6), // ToolButtonと同じ角丸
            child: Container(
              width: 36, // ToolButtonと同じ幅
              height: 36, // ToolButtonと同じ高さ
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6), // ToolButtonと同じ角丸
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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

  Widget _buildVerticalDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 24, // ToolButtonの高さの2/3程度
        child: VerticalDivider(
          thickness: 1,
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
    );
  }

  void _toggleColorPicker() {
    setState(() {
      _isColorPickerExpanded = !_isColorPickerExpanded;
    });
  }

  void _onControllerChanged() {
    setState(() {});
  }
}
