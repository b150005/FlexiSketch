import 'package:flutter/material.dart';

/// ストローク幅を設定するボタンウィジェット
///
/// クリックするとオーバーレイでスライダーを表示し、ストロークの太さを
/// 調整することができます。スライダーの操作中はリアルタイムで値が更新され、
/// 視覚的なフィードバックを提供します。
class StrokeWidthButton extends StatefulWidget {
  /// 現在のストローク幅
  final double strokeWidth;

  /// ストローク幅が変更された時のコールバック
  final ValueChanged<double> onChanged;

  const StrokeWidthButton({
    super.key,
    required this.strokeWidth,
    required this.onChanged,
  });

  @override
  State<StrokeWidthButton> createState() => _StrokeWidthButtonState();
}

class _StrokeWidthButtonState extends State<StrokeWidthButton> {
  /// オーバーレイエントリ
  OverlayEntry? _overlayEntry;

  /// ボタンのキー（位置特定用）
  final LayerLink _layerLink = LayerLink();

  /// 現在のストローク幅
  late double _currentWidth;

  @override
  void initState() {
    super.initState();
    _currentWidth = widget.strokeWidth;
  }

  @override
  void didUpdateWidget(StrokeWidthButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.strokeWidth != widget.strokeWidth) {
      _currentWidth = widget.strokeWidth;
    }
  }

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
        message: 'ストロークの太さ',
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
            child: Icon(
              Icons.line_weight,
              size: 20,
              color: Theme.of(context).iconTheme.color,
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

    // スライダーを表示する方向を決定（右端からの距離が overlayWidth の半分より小さい場合は左に表示）
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
                              const Icon(Icons.line_weight, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _currentWidth.round().toString(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          StatefulBuilder(
                            builder: (context, setStateSlider) {
                              return Slider(
                                value: _currentWidth,
                                min: 1,
                                max: 20,
                                divisions: 19,
                                label: _currentWidth.round().toString(),
                                onChanged: (value) {
                                  setStateSlider(() {
                                    _currentWidth = value;
                                  });
                                  widget.onChanged(value);
                                },
                              );
                            },
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
