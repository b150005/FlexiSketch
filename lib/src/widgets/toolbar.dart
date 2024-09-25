import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../flexi_sketch_controller.dart';
import '../tools/drawing_tool.dart';
import '../tools/eraser_tool.dart';
import '../tools/marker_tool.dart';
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
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_animation),
      child: Container(
        height: 56,
        color: Colors.grey[200],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildToolButton(Icons.edit, PenTool()),
            _buildToolButton(Icons.brush, MarkerTool()),
            _buildToolButton(Icons.crop_square, ShapeTool(ShapeType.rectangle)),
            _buildToolButton(Icons.circle_outlined, ShapeTool(ShapeType.circle)),
            _buildToolButton(Icons.delete, EraserTool()),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(IconData icon, DrawingTool tool) {
    final isSelected = widget.controller.isToolSelected(tool);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: () {
          widget.controller.setTool(tool);
          HapticFeedback.selectionClick();
        },
        color: isSelected ? Colors.blue : Colors.black,
      ),
    );
  }
}