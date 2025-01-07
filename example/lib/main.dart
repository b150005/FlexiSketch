import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flexi_sketch/flexi_sketch.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final TextEditingController _jsonController = TextEditingController();
  ImageLoadingState? _loadingState;

  final FlexiSketchController _controller = FlexiSketchController();

  // テキストが空かどうかの状態を管理
  bool _isTextEmpty = true;

  @override
  void initState() {
    super.initState();

    // テキストの変更を監視
    _jsonController.addListener(() {
      final isEmpty = _jsonController.text.isEmpty;
      if (isEmpty != _isTextEmpty) {
        setState(() {
          _isTextEmpty = isEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FlexiSketch Demo"),
        actions: [
          // 画像読み込みボタンを追加
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: '画像を読み込んでキャンバスを上書き',
            onPressed: _loadingState != null ? null : () => _pickAndLoadImage(context),
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
                    try {
                      // 一時ディレクトリを取得
                      final tempDir = await getTemporaryDirectory();
                      final timestamp = DateTime.now().millisecondsSinceEpoch;
                      final tempFile = File('${tempDir.path}/sketch_$timestamp.png');

                      // 画像データを一時ファイルとして保存
                      await tempFile.writeAsBytes(imageData);

                      if (!context.mounted) return;
                      final box = context.findRenderObject() as RenderBox?;

                      // 共有ダイアログを表示
                      await Share.shareXFiles(
                        [XFile(tempFile.path)],
                        subject: '画像データ',
                        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                      ).then((_) async {
                        // 共有完了後に一時ファイルを削除
                        if (await tempFile.exists()) {
                          await tempFile.delete();
                        }
                      });
                    } catch (e) {
                      developer.log('画像の共有エラー: $e');
                    }
                  },

                  // DEBUG: JSONとして保存
                  onSaveAsData: (context, jsonData, imageData, progress) async {
                    if (jsonData == null || imageData == null) {
                      return;
                    }

                    try {
                      // JSONデータを整形
                      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

                      // 一時ディレクトリを取得
                      final tempDir = await getTemporaryDirectory();
                      final timestamp = DateTime.now().millisecondsSinceEpoch;
                      final tempFile = File('${tempDir.path}/sketch_$timestamp.json');

                      // JSONデータを一時ファイルとして保存
                      await tempFile.writeAsString(jsonString);

                      if (!context.mounted) return;
                      final box = context.findRenderObject() as RenderBox?;

                      // 共有ダイアログを表示
                      await Share.shareXFiles(
                        [XFile(tempFile.path)],
                        subject: 'JSONデータ',
                        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                      ).then((_) async {
                        // 共有完了後に一時ファイルを削除
                        if (await tempFile.exists()) {
                          await tempFile.delete();
                        }
                      });
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('JSONデータの共有に失敗しました: $e')),
                      );
                      developer.log('JSONデータの共有エラー: $e');
                    }
                  },
                  onError: (message) {
                    setState(() {
                      _loadingState = null;
                    });
                  },
                ),
              ),
            ],
          ),
          // ローディングオーバーレイ
          if (_loadingState != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: _loadingState!.progress,
                        ),
                        const SizedBox(height: 16),
                        Text(_loadingState!.phase.message),
                        if (_loadingState!.progress > 0)
                          Text(
                            '${(_loadingState!.progress * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 画像を選択してFlexiSketchに読み込む
  Future<void> _pickAndLoadImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _loadingState = ImageLoadingState.initial;
        });

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
          onProgress: (state) {
            if (mounted) {
              setState(() {
                _loadingState = state;
              });
            }
          },
        );

        setState(() {
          _currentData = jsonData;
          _loadingState = null;
        });
      }
    } catch (e) {
      setState(() {
        _loadingState = null;
      });
    }
  }
}
