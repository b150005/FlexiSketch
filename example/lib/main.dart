import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flexi_sketch/flexi_sketch.dart';
import 'package:flutter/services.dart';

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
  Image? _generatedImage;
  Map<String, dynamic>? _currentData;
  String? _errorMessage;
  final TextEditingController _jsonController = TextEditingController();
  Map<String, dynamic>? _pendingData;

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
    _jsonController.dispose();
    super.dispose();
  }

  /// JSONの解析を行う
  void _parseJson() {
    if (_jsonController.text.isEmpty) {
      setState(() {
        _pendingData = null;
        _errorMessage = null;
      });
      return;
    }

    try {
      final data = json.decode(_jsonController.text) as Map<String, dynamic>;
      setState(() {
        _pendingData = data;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _pendingData = null;
        _errorMessage = 'JSONの解析に失敗しました: $e';
      });
    }
  }

  /// キャンバスにJSONデータを反映する
  void _applyJsonToCanvas() {
    if (_pendingData != null) {
      setState(() {
        _currentData = _pendingData;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // キャンバス
          Expanded(
            flex: 2,
            child: FlexiSketchWidget(
              data: _currentData?['content'],
              onSaveAsImage: (imageData) async {
                setState(() {
                  _generatedImage = Image.memory(imageData);
                  _errorMessage = null;
                });
              },
              onSaveAsData: (jsonData, imageData) async {
                final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
                setState(() {
                  _currentData = jsonData;
                  _pendingData = jsonData; // 保存時は pending も更新
                  _jsonController.text = jsonString;
                });
                await Clipboard.setData(ClipboardData(text: jsonString));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('JSONをクリップボードにコピーしました'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              onError: (message) {
                setState(() {
                  _errorMessage = message;
                });
              },
            ),
          ),
          // プレビュー部分
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  // 画像プレビュー
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            '画像プレビュー',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Expanded(
                          child: _generatedImage != null
                              ? SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _generatedImage,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Text(
                                    '画像を保存すると\nここにプレビューが表示されます',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  // JSONプレビュー
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                'JSONプレビュー',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              // JSONの構文チェックと反映ボタン
                              TextButton.icon(
                                icon: const Icon(Icons.play_arrow, size: 20),
                                label: const Text('反映'),
                                onPressed: _isTextEmpty
                                    ? null
                                    : () {
                                        _parseJson();
                                        if (_errorMessage == null) {
                                          _applyJsonToCanvas();
                                        }
                                      },
                              ),
                              const SizedBox(width: 8),
                              // コピーボタン
                              TextButton.icon(
                                icon: const Icon(Icons.copy, size: 20),
                                label: const Text('コピー'),
                                onPressed: _isTextEmpty
                                    ? null
                                    : () {
                                        Clipboard.setData(
                                          ClipboardData(text: _jsonController.text),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('JSONをクリップボードにコピーしました'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: _jsonController,
                                maxLines: null,
                                expands: true,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'JSONを入力して「反映」ボタンを押すとキャンバスに反映されます',
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
