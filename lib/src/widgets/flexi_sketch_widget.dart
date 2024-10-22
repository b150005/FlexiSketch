import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import '../canvas/infinite_canvas.dart';
import 'color_palette.dart';
import 'stroke_width_slider.dart';
import 'toolbar.dart';

class FlexiSketchWidget extends StatelessWidget {
  final FlexiSketchController controller;

  const FlexiSketchWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            InfiniteCanvas(controller: controller),
            Positioned(
              left: 16,
              top: 16,
              child: Column(
                children: [
                  ColorPalette(controller: controller),
                  const SizedBox(height: 16),
                  StrokeWidthSlider(controller: controller),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Toolbar(controller: controller),
              ),
            )
          ],
        ),
      ),
    );
  }
}
