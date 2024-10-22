import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';

class ZoomControls extends StatefulWidget {
  final FlexiSketchController controller;

  const ZoomControls({super.key, required this.controller});

  @override
  State<ZoomControls> createState() => _ZoomControlsState();
}

class _ZoomControlsState extends State<ZoomControls> with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(_animation),
      child: Container(
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
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () => widget.controller.zoomIn(),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () => widget.controller.zoomOut(),
            ),
          ],
        ),
      ),
    );
  }
}
