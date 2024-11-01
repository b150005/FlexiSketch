import 'package:flutter/material.dart';

/// 標準のツールボタン
class ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isSelected;

  const ToolButton({
    super.key,
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
