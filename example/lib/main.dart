import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flexi_sketch/flexi_sketch.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'src/services/file_handler.dart';
import 'src/services/file_handler_factory.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlexiSketch Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  Map<String, dynamic>? _currentData;

  late final FlexiSketchController _controller;
  late final FileHandler _fileHandler;

  @override
  void initState() {
    super.initState();

    _controller = FlexiSketchController(context: context, preserveImages: false);
    _fileHandler = FileHandlerFactory.create(context);

    _loadInitialImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FlexiSketch Demo"),
        actions: [
          // JSON読み込みボタン
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'JSONを読み込む',
            onPressed: _loadJsonData,
          ),
          // 画像読み込みボタン
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: '画像を読み込んでキャンバスを上書き',
            onPressed: () => _pickAndLoadImage(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // キャンバス
              Expanded(
                flex: 2,
                child: FlexiSketchWidget(
                  controller: _controller,
                  data: _currentData?['content'],

                  // DEBUG: 画像として保存
                  onSaveAsImage: (context, imageData) async {
                    _handleSaveImage(context, imageData);
                  },

                  // DEBUG: JSONとして保存
                  onSaveAsData: (context, jsonData, imageData) async {
                    if (jsonData == null || imageData == null) {
                      return;
                    }

                    _handleSaveData(context, jsonData, imageData);
                  },
                  onError: (message) {
                    developer.log(message);
                  },
                  // hideUndoRedo: true,
                  // hideClear: true,
                  // hideUpload: true,
                  // hideImagePaste: true,
                  // hideShapeDrawing: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadInitialImage() async {
    // Assets を ByteData として読み込む
    final ByteData data = await rootBundle.load('assets/pic_01_l.jpg');
    final Uint8List imageData = data.buffer.asUint8List();

    _controller.addImageFromBytes(imageData, addHistory: false);
  }

  /// 画像として保存するボタン押下時の処理
  Future<void> _handleSaveImage(BuildContext context, Uint8List imageData) async {
    try {
      final fileName = 'sketch_${DateTime.now().millisecondsSinceEpoch}.png';
      await _fileHandler.saveImageFile(imageData, fileName);
    } catch (e) {
      developer.log('画像の保存エラー: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の保存に失敗しました: $e')),
      );
    }
  }

  /// JSON ファイルとして保存するボタン押下時の処理
  Future<void> _handleSaveData(
    BuildContext context,
    Map<String, dynamic>? jsonData,
    Uint8List? imageData,
  ) async {
    if (jsonData == null || imageData == null) return;

    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      final fileName = 'sketch_${DateTime.now().millisecondsSinceEpoch}.json';
      await _fileHandler.saveJsonFile(jsonString, fileName);
    } catch (e) {
      developer.log('JSONデータの保存エラー: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSONデータの保存に失敗しました: $e')),
      );
    }
  }

  /// JSON ファイルを選択してキャンバスを読み込む
  Future<void> _loadJsonData() async {
    try {
      final jsonString = await _fileHandler.loadJsonFile();
      if (jsonString == null) return;

      final jsonData = json.decode(jsonString);
      setState(() {
        _currentData = jsonData;
      });
    } catch (e) {
      developer.log('JSONデータの読み込みエラー: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSONデータの読み込みに失敗しました: $e')),
      );
    }
  }

  /// 画像を選択してFlexiSketchに読み込む
  Future<void> _pickAndLoadImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        // 現在のキャンバスサイズを取得
        if (!context.mounted) return;
        final mediaQuery = MediaQuery.of(context);
        final screenSize = mediaQuery.size;
        final appBarHeight = AppBar().preferredSize.height + mediaQuery.padding.top;
        final availableHeight = screenSize.height - appBarHeight;

        // キャンバス領域は Row > Expanded(flex: 2) で配置されているため、利用可能な幅の 2/3 がキャンバスの幅となる
        final canvasSize = Size(
          screenSize.width * 2 / 3,
          availableHeight,
        );

        // 画像データを FlexiSketch に読み込み
        final jsonData = await FlexiSketchDataHelper.createInitialDataFromImage(
          bytes,
          width: canvasSize.width,
          height: canvasSize.height,
        );

        setState(() {
          _currentData = jsonData;
        });
      }
    } catch (e) {
      developer.log(e.toString());
    }
  }
}
