import 'package:flutter/material.dart';
import 'package:flexi_sketch/flexi_sketch.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlexiSketchController _controller = FlexiSketchController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlexiSketch Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: FlexiSketchWidget(controller: _controller),
      ),
    );
  }
}
