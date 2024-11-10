import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flexi_sketch/flexi_sketch.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

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
  final FlexiSketchController _controller = FlexiSketchController();
  String? _lastSavedJson;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    // インメモリストレージを設定
    _controller.setStorage(InMemoryTestStorage(
      onSave: (json) {
        setState(() {
          _lastSavedJson = json;
        });
      },
    ));

    // 画像として保存する機能を設定
    _controller.saveAsImage = (imageData) async {
      // 実際のアプリケーションでは、ここで画像の保存処理を実装します
      print('Image data size: ${imageData.length} bytes');
    };

    // データとして保存する機能を設定
    _controller.saveAsData = (data) async {
      // 実際のアプリケーションでは、ここでデータの保存処理を実装します
      print('Data saved: ${data.length} items');
    };

    // エラーハンドリング
    _controller.onError = (message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: FlexiSketchWidget(controller: _controller),
          ),
          if (_lastSavedJson != null) ...[
            const VerticalDivider(width: 1),
            SizedBox(
              width: 300,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      margin: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('保存されたJSON:'),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  tooltip: 'JSONをコピー',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                      text: const JsonEncoder.withIndent('  ').convert(json.decode(_lastSavedJson!)),
                                    ));
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
                          const Divider(height: 1),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(8.0),
                              child: SelectableText(
                                const JsonEncoder.withIndent('  ').convert(json.decode(_lastSavedJson!)),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          if (_controller.metadata != null) {
                            await _controller.loadSketch(_controller.metadata!.id);
                          }
                        } catch (e) {
                          _controller.onError?.call(e.toString());
                        }
                      },
                      child: const Text('最後に保存したデータを読み込む'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// インメモリストレージの実装
class InMemoryTestStorage implements SketchStorage {
  final void Function(String json)? onSave;
  final Map<String, String> _storage = {};

  InMemoryTestStorage({this.onSave});

  @override
  Future<SketchMetadata> saveSketch(SketchData data, {bool asImage = false}) async {
    final metadata = data.metadata.copyWith(updatedAt: DateTime.now());
    final id = metadata.id;

    // オブジェクトのシリアライズを待機する
    final serializedObjects =
        await Future.wait(data.objects.map((obj) => DrawableObjectSerializer.instance.toJson(obj)));

    final jsonData = {
      'metadata': metadata.toJson(),
      'objects': serializedObjects,
    };

    final jsonString = json.encode(jsonData);
    _storage[id] = jsonString;
    onSave?.call(jsonString);

    return metadata;
  }

  @override
  Future<SketchData> loadSketch(String id) async {
    final jsonString = _storage[id];
    if (jsonString == null) {
      throw Exception('Sketch not found: $id');
    }

    final jsonData = json.decode(jsonString);
    final metadata = SketchMetadata.fromJson(jsonData['metadata']);

    final objectsList = (jsonData['objects'] as List).map((obj) async {
      return await DrawableObjectSerializer.instance.fromJson(obj);
    }).toList();

    final objects = await Future.wait(objectsList);
    return SketchData(metadata: metadata, objects: objects);
  }

  @override
  Future<List<SketchMetadata>> listSketches() async => [];

  @override
  Future<void> deleteSketch(String id) async {
    _storage.remove(id);
  }
}

/// ローカルファイルシステムを使用したテスト用ストレージ
class LocalTestStorage implements SketchStorage {
  final void Function(String path, String json)? onSave;

  LocalTestStorage({this.onSave});

  @override
  Future<SketchMetadata> saveSketch(SketchData data, {bool asImage = false}) async {
    final directory = await getApplicationDocumentsDirectory();
    final baseDir = Directory('${directory.path}/flexi_sketch_test');
    await baseDir.create(recursive: true);

    final metadata = data.metadata.copyWith(updatedAt: DateTime.now());
    final id = metadata.id;

    if (asImage) {
      final imageFile = File('${baseDir.path}/$id.png');
      final imageBytes = await DefaultThumbnailGenerator().generatePreview(
        data.objects,
        const Size(800, 600),
      );
      await imageFile.writeAsBytes(imageBytes);
      onSave?.call(imageFile.path, '');
    } else {
      final jsonFile = File('${baseDir.path}/$id.json');
      final jsonData = {
        'metadata': metadata.toJson(),
        'objects': data.objects.map((obj) => DrawableObjectSerializer.instance.toJson(obj)).toList(),
      };
      final jsonString = json.encode(jsonData);
      await jsonFile.writeAsString(jsonString);
      onSave?.call(jsonFile.path, jsonString);
    }

    return metadata;
  }

  @override
  Future<SketchData> loadSketch(String id) async {
    final directory = await getApplicationDocumentsDirectory();
    final jsonFile = File('${directory.path}/flexi_sketch_test/$id.json');

    if (!await jsonFile.exists()) {
      throw Exception('File not found: ${jsonFile.path}');
    }

    final jsonString = await jsonFile.readAsString();
    onSave?.call(jsonFile.path, jsonString);

    final jsonData = json.decode(jsonString);
    final metadata = SketchMetadata.fromJson(jsonData['metadata']);

    final objectsList = (jsonData['objects'] as List).map((obj) async {
      final object = await DrawableObjectSerializer.instance.fromJson(obj);
      return object;
    }).toList();

    final objects = await Future.wait(objectsList);
    return SketchData(metadata: metadata, objects: objects);
  }

  @override
  Future<List<SketchMetadata>> listSketches() async => [];

  @override
  Future<void> deleteSketch(String id) async {}
}
