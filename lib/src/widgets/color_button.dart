import 'package:flutter/material.dart';

/// カラー選択ボタン
///
/// クリックするとオーバーレイでカラーパレットを表示し、色を
/// 選択することができます。
class ColorButton extends StatefulWidget {
  /// 現在選択されている色
  final Color color;

  /// 色が変更された時のコールバック
  final ValueChanged<Color> onColorChanged;

  /// 定義済みカラーパレット
  final List<Color> predefinedColors;

  const ColorButton({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.predefinedColors = const [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.brown,
    ],
  });

  @override
  State<ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<ColorButton> {
  /// オーバーレイエントリ
  OverlayEntry? _overlayEntry;

  /// ボタンのキー（位置特定用）
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Tooltip(
        message: '色を選択',
        child: Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: InkWell(
            onTap: _toggleOverlay,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// オーバーレイを切り替える
  void _toggleOverlay() {
    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  /// オーバーレイを表示する
  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// オーバーレイを削除する
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// オーバーレイエントリを作成する
  OverlayEntry _createOverlayEntry() {
    const overlayWidth = 240.0;
    const overlayHeight = 100.0;
    const padding = 8.0;

    // 画面サイズを取得
    final screenSize = MediaQuery.of(context).size;

    // ボタンの位置情報を取得
    final box = context.findRenderObject() as RenderBox;
    final buttonSize = box.size;
    final buttonPosition = box.localToGlobal(Offset.zero);

    // カラーパレットを表示する方向を決定（右端からの距離が overlayWidth の半分より小さい場合は左に表示）
    final showToLeft = (screenSize.width - buttonPosition.dx) < overlayWidth / 2;

    // オフセットを計算
    final double dx = showToLeft
        ? -(overlayWidth - buttonSize.width) // 左寄せ
        : -(overlayWidth - buttonSize.width) / 2; // 中央寄せ

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _removeOverlay,
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: buttonPosition.dx + dx,
                top: buttonPosition.dy - overlayHeight - padding,
                child: GestureDetector(
                  onTap: () {}, // バブリングを防止
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      width: overlayWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: widget.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '色を選択',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.predefinedColors.map((color) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () {
                                      widget.onColorChanged(color);
                                      _removeOverlay();
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
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
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
}
