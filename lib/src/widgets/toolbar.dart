import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import '../tools/drawing_tool.dart';
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
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
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

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToolButton(PenTool()),
        _buildToolButton(EraserTool()),
        _buildToolButton(ShapeTool(shapeType: ShapeType.rectangle)),
        _buildToolButton(ShapeTool(shapeType: ShapeType.circle)),
        ElevatedButton(
          onPressed: widget.controller.clear,
          child: const Icon(Icons.clear),
        ),
      ],
    );
  }

  Widget _buildToolButton(DrawingTool tool) {
  return ElevatedButton(
    onPressed: () => widget.controller.toggleTool(tool),
    style: ElevatedButton.styleFrom(
      backgroundColor: widget.controller.isSpecificToolSelected(tool) ? Colors.blue : null,
    ),
    child: Icon(_getIconForTool(tool)),
  );
}

  IconData _getIconForTool(DrawingTool tool) {
    if (tool is PenTool) return Icons.edit;
    if (tool is EraserTool) return Icons.auto_fix_high;
    if (tool is ShapeTool) {
      switch (tool.shapeType) {
        case ShapeType.rectangle:
          return Icons.crop_square;
        case ShapeType.circle:
          return Icons.circle_outlined;
      }
    }
    return Icons.error;
  }
}