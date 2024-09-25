import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';

class StrokeWidthSlider extends StatefulWidget {
  final FlexiSketchController controller;

  const StrokeWidthSlider({super.key, required this.controller});

  @override
  State<StrokeWidthSlider> createState() => _StrokeWidthSliderState();
}

class _StrokeWidthSliderState extends State<StrokeWidthSlider> with SingleTickerProviderStateMixin {
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
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('Stroke Width'),
            Slider(
              value: widget.controller.currentStrokeWidth,
              min: 1,
              max: 20,
              divisions: 19,
              label: widget.controller.currentStrokeWidth.round().toString(),
              onChanged: (value) => widget.controller.setStrokeWidth(value),
            ),
          ],
        ),
      ),
    );
  }
}