import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import '../tools/eraser_tool.dart';
import '../tools/pen_tool.dart';
import '../tools/shape_tool.dart';

class Toolbar extends StatefulWidget {
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
            // 上段：描画ツールと画像ツール
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 描画ツール群
                _buildToolGroup([
                  _ToolButton(
                    icon: Icons.edit,
                    tooltip: 'ペン',
                    isSelected: widget.controller.isSpecificToolSelected(PenTool()),
                    onPressed: () => widget.controller.toggleTool(PenTool()),
                  ),
                  _ToolButton(
                    icon: Icons.auto_fix_high,
                    tooltip: '消しゴム',
                    isSelected: widget.controller.isSpecificToolSelected(EraserTool()),
                    onPressed: () => widget.controller.toggleTool(EraserTool()),
                  ),
                ]),
                _buildVerticalDivider(),
                // 図形ツール群
                _buildToolGroup([
                  _ToolButton(
                    icon: Icons.crop_square,
                    tooltip: '四角形',
                    isSelected: widget.controller.isSpecificToolSelected(ShapeTool(shapeType: ShapeType.rectangle)),
                    onPressed: () => widget.controller.toggleTool(ShapeTool(shapeType: ShapeType.rectangle)),
                  ),
                  _ToolButton(
                    icon: Icons.circle_outlined,
                    tooltip: '円',
                    isSelected: widget.controller.isSpecificToolSelected(ShapeTool(shapeType: ShapeType.circle)),
                    onPressed: () => widget.controller.toggleTool(ShapeTool(shapeType: ShapeType.circle)),
                  ),
                ]),
                _buildVerticalDivider(),
                // 画像ツール群
                _buildToolGroup([
                  _ToolButton(
                    icon: Icons.upload_file,
                    tooltip: '画像をアップロード',
                    onPressed: widget.controller.pickAndAddImage,
                  ),
                  _ToolButton(
                    icon: Icons.paste,
                    tooltip: '画像を貼り付け',
                    onPressed: widget.controller.pasteImageFromClipboard,
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            // 下段：編集操作
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolGroup([
                  _ToolButton(
                    icon: Icons.undo,
                    tooltip: '元に戻す',
                    onPressed: widget.controller.canUndo ? widget.controller.undo : null,
                  ),
                  _ToolButton(
                    icon: Icons.redo,
                    tooltip: 'やり直す',
                    onPressed: widget.controller.canRedo ? widget.controller.redo : null,
                  ),
                ]),
                _buildVerticalDivider(),
                _buildToolGroup([
                  _ToolButton(
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

  /// コントローラの状態変更時に呼び出されるコールバック
  ///
  /// コントローラの状態が変更された際にウィジェットを再描画します。
  void _onControllerChanged() {
    setState(() {});
  }

  /// ツールボタンのグループを構築する
  ///
  /// 指定された [children] ウィジェットをグループ化し、適切な余白を設定します。
  /// グループ内の各ボタンには、位置に応じた余白が設定されます。
  ///
  /// [children] グループ化するウィジェットのリスト
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

  /// ツールグループ間の縦方向の区切り線を構築する
  ///
  /// グループ間の視覚的な区切りとして、薄いグレーの縦線を表示します。
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
}

/// ツールバーで使用する個々のツールボタン
///
/// アイコン、ツールチップ、タップ時の動作、選択状態などをカスタマイズ可能なボタンウィジェットを提供します。
/// ボタンは選択状態に応じて視覚的なフィードバックを提供します。
class _ToolButton extends StatelessWidget {
  /// ボタンに表示するアイコン
  final IconData icon;

  /// マウスホバー時に表示するツールチップのテキスト
  final String tooltip;

  /// ボタンタップ時のコールバック関数
  ///
  /// `null` の場合、ボタンは無効状態として表示されます。
  final VoidCallback? onPressed;

  /// ボタンの選択状態
  ///
  /// `true` の場合、ボタンは選択状態として強調表示されます。
  final bool isSelected;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
