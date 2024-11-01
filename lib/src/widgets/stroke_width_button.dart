import 'package:flutter/material.dart';

/// ストローク幅設定ボタン
class StrokeWidthButton extends StatefulWidget {
  final double strokeWidth;
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
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'ストロークの太さ',
      child: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: PopupMenuButton<double>(
          tooltip: '',
          offset: const Offset(0, 40),
          constraints: const BoxConstraints(maxWidth: 240),
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false, // タップでメニューが閉じないようにする
              height: 80, // スライダーの高さを確保
              child: SizedBox(
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.line_weight, size: 20),
                        const SizedBox(width: 8),
                        Text(_currentWidth.round().toString()),
                      ],
                    ),
                    Slider(
                      value: _currentWidth,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: _currentWidth.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _currentWidth = value;
                        });
                        widget.onChanged(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          child: Icon(
            Icons.line_weight,
            size: 20,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }
}
