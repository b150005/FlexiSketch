import 'dart:ui' as ui;

import 'package:flexi_sketch/src/services/clipboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'src/history/history_entry.dart';
import 'src/objects/drawable_object.dart';
import 'src/objects/image_object.dart';
import 'src/objects/path_object.dart';
import 'src/objects/shape_object.dart';
import 'src/tools/drawing_tool.dart';
import 'src/tools/shape_tool.dart';

class FlexiSketchController extends ChangeNotifier {
  /// 選択中の描画ツール
  DrawingTool? _currentTool;
  DrawingTool? get currentTool => _currentTool;

  /// キャンバス上の描画オブジェクトのリスト
  final List<DrawableObject> _objects = [];
  List<DrawableObject> get objects => _objects;

  /// 描画色
  Color _currentColor = Colors.black;
  Color get currentColor => _currentColor;

  /// 線の太さ
  double _currentStrokeWidth = 2.0;
  double get currentStrokeWidth => _currentStrokeWidth;

  /// 描画中のパス(線)
  PathObject? _currentPath;
  PathObject? get currentPath => _currentPath;

  /// 描画中の図形
  ShapeObject? _currentShape;
  ShapeObject? get currentShape => _currentShape;

  /// 描画ツールが選択されているかどうか
  bool get isToolSelected => _currentTool != null;

  /// 元に戻すスタック
  final List<HistoryEntry> _undoStack = [];
  bool get canUndo => _undoStack.isNotEmpty;

  /// やり直すスタック
  final List<HistoryEntry> _redoStack = [];
  bool get canRedo => _redoStack.isNotEmpty;

  /// 現在選択中のオブジェクト
  DrawableObject? _selectedObject;
  DrawableObject? get selectedObject => _selectedObject;

  /// 選択中のオブジェクトが存在するかどうか
  bool get hasSelection => _selectedObject != null;

  /// 選択中のオブジェクトが画像かどうか
  bool get isImageSelected => _selectedObject is ImageObject;

  /// エラー通知用のコールバック関数
  void Function(String message)? _onError;

  /// エラーハンドラを設定する
  set onError(void Function(String message)? handler) {
    _onError = handler;
  }

  /// キャンバスのサイズ
  Size? _canvasSize;

  /// キャンバスサイズを更新する
  ///
  /// [size] 新しいキャンバスサイズ
  void updateCanvasSize(Size size) {
    _canvasSize = size;
  }

  /// 描画を開始する
  ///
  /// [point] 描画開始位置
  void startDrawing(Offset point) {
    _currentTool?.startDrawing(point, this);
    notifyListeners();
  }

  /// 描画を続ける
  ///
  /// [point] 描画位置
  void addPoint(Offset point) {
    _currentTool?.continueDrawing(point, this);
    notifyListeners();
  }

  /// 描画を終了する
  void endDrawing() {
    _currentTool?.endDrawing(this);
    notifyListeners();
  }

  /// 描画色を設定する
  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  /// 線の太さを設定する
  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    notifyListeners();
  }

  /// 元に戻す
  void undo() {
    if (!canUndo) return;

    final entry = _undoStack.removeLast();
    _redoStack.add(HistoryEntry(
      objects: List.from(_objects),
      type: entry.type,
    ));

    _objects.clear();
    _objects.addAll(List.from(entry.objects));
    notifyListeners();
  }

  /// やり直す
  void redo() {
    if (!canRedo) return;

    final entry = _redoStack.removeLast();
    _undoStack.add(HistoryEntry(
      objects: List.from(_objects),
      type: entry.type,
    ));

    _objects.clear();
    _objects.addAll(List.from(entry.objects));
    notifyListeners();
  }

  /// 履歴に操作を追加する
  ///
  /// [type] 履歴エントリの種類
  void _addToHistory(HistoryEntryType type) {
    _undoStack.add(HistoryEntry(
      objects: List.from(_objects),
      type: type,
    ));
    _redoStack.clear();
    notifyListeners();
  }

  /// キャンバスをクリアする
  void clear() {
    if (_objects.isNotEmpty) {
      _addToHistory(HistoryEntryType.clear);
      _objects.clear();
      notifyListeners();
    }
  }

  /// 描画ツールを設定・変更する
  ///
  /// [tool] 設定する描画対象ツール。 `null` を指定すると選択モードになる
  void setTool(DrawingTool? tool) {
    _currentTool = tool;

    // 描画ツールを変更する場合はオブジェクトの選択を解除
    if (tool != null) {
      clearSelection();
    }

    notifyListeners();
  }

  /// 描画ツールを切り替える
  void toggleTool(DrawingTool tool) {
    if (isSpecificToolSelected(tool)) {
      setTool(null);
    } else {
      setTool(tool);
    }
  }

  /// 現在の描画ツールが指定したツールかどうか
  ///
  /// [tool] 判定対象の描画ツール
  ///
  /// 図形ツールの場合は図形の種類まで一致するかどうかを判定します。
  bool isSpecificToolSelected(DrawingTool tool) {
    if (_currentTool == null || _currentTool.runtimeType != tool.runtimeType) {
      return false;
    }
    if (_currentTool is ShapeTool && tool is ShapeTool) {
      return (_currentTool as ShapeTool).shapeType == tool.shapeType;
    }
    return true;
  }

  /// パス(線)の描画を開始する
  void startPath(Offset point, {BlendMode blendMode = BlendMode.srcOver}) {
    final path = Path()..moveTo(0, 0); // 原点から開始
    final paint = _currentTool?.createPaint(_currentColor, _currentStrokeWidth);
    _currentPath = PathObject(inputPath: path, paint: paint ?? Paint());
    _currentPath?.translate(point); // 開始点に移動
  }

  /// パス(線)を描画する
  void addPointToPath(Offset point) {
    if (_currentPath != null) {
      // グローバル座標をローカル座標に変換
      final localPoint = _currentPath!.globalToLocal(point);
      _currentPath!.addPoint(localPoint);
      notifyListeners();
    }
  }

  /// パス(線)の描画を終了する
  void endPath() {
    if (_currentPath != null) {
      _addToHistory(HistoryEntryType.draw);
      _objects.add(_currentPath!);
      _currentPath = null;
      notifyListeners();
    }
  }

  /// 消しゴムを開始する
  void startErasing(Offset point) {
    // final path = Path()..moveTo(point.dx, point.dy);
    final path = Path()..moveTo(0, 0);
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..strokeWidth = _currentStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _currentPath = PathObject(inputPath: path, paint: paint);
    _currentPath?.translate(point); // 開始点に移動
    notifyListeners();
  }

  /// 消しゴムを実行する
  void continueErasing(Offset point) {
    if (_currentPath != null) {
      final localPoint = _currentPath!.globalToLocal(point);
      _currentPath!.addPoint(localPoint);

      // 変換済みのパスを使用して交差判定
      if (_objects.any((obj) => obj.intersects(_currentPath!.getTransformedPath()))) {
        _addToHistory(HistoryEntryType.erase);
        _objects.removeWhere((obj) => obj.intersects(_currentPath!.getTransformedPath()));
      }
      notifyListeners();
    }
  }

  /// 消しゴムを終了する
  void endErasing() {
    _currentPath = null;
    notifyListeners();
  }

  /// 図形の描画を開始する
  void startShape(Offset point, ShapeType shapeType) {
    final paint = Paint()
      ..color = _currentColor
      ..strokeWidth = _currentStrokeWidth
      ..style = PaintingStyle.stroke;

    _currentShape = ShapeObject(
      startPoint: point,
      endPoint: point, // 初期状態では開始点・終了点は同じ
      shapeType: shapeType,
      paint: paint,
    );

    notifyListeners();
  }

  /// 図形を描画する
  void updateShape(Offset point) {
    if (_currentShape != null) {
      _currentShape!.updateShape(point);
      notifyListeners();
    }
  }

  /// 図形の描画を終了する
  void endShape() {
    if (_currentShape != null) {
      // 開始点と終了点が同じ（クリックのみで図形が作られていない）場合は
      // 最小サイズの図形を作成するなどの処理を追加することもできます
      if (_currentShape!.startPoint != _currentShape!.endPoint) {
        _addToHistory(HistoryEntryType.draw);
        _objects.add(_currentShape!);
      }
      _currentShape = null;
      notifyListeners();
    }
  }

  /// オブジェクトを選択する
  void selectObject(Offset point) {
    // ツール使用中は選択を無効化
    if (_currentTool != null) return;

    // 選択済みオブジェクトがあればその選択状態を解除
    if (_selectedObject != null) {
      _selectedObject!.isSelected = false;
    }

    _selectedObject = null;

    // 最前面のオブジェクトから順に判定
    for (final object in _objects.reversed) {
      if (object.containsPoint(point)) {
        _selectedObject = object;
        object.isSelected = true;
        break;
      }
    }

    notifyListeners();
  }

  /// オブジェクトの選択を解除する
  void clearSelection() {
    if (_selectedObject != null) {
      _selectedObject!.isSelected = false;
      _selectedObject = null;
      notifyListeners();
    }
  }

  /// 選択中のオブジェクトを削除する
  void deleteSelectedObject() {
    if (_selectedObject != null) {
      _addToHistory(HistoryEntryType.delete);
      _objects.remove(_selectedObject);
      _selectedObject = null;
      notifyListeners();
    }
  }

  /// 選択中のオブジェクトを移動する
  void moveSelectedObject(Offset delta) {
    if (_selectedObject != null) {
      _selectedObject!.translate(delta);
      notifyListeners();
    }
  }

  /// 選択中のオブジェクトを回転する
  ///
  /// [angle] 回転角度[rad]
  void rotateSelectedObject(double angle) {
    if (_selectedObject != null) {
      _selectedObject!.rotate(angle);
      notifyListeners();
    }
  }

  /// 選択中のオブジェクトをリサイズする
  ///
  /// [scale] スケール値の変更量
  void resizeSelectedObject(double scale) {
    if (_selectedObject != null) {
      _selectedObject!.resize(scale);
      notifyListeners();
    }
  }

  /// エラーメッセージを通知する
  void _notifyError(String message) {
    _onError?.call(message);
  }

  /// 画像ファイルを選択してキャンバスに追加する
  ///
  /// ファイル選択ダイアログを表示し、選択された画像をキャンバスに追加します。
  Future<void> pickAndAddImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        await addImageFromBytes(bytes);
      }
    } catch (e) {
      _notifyError('画像の選択中にエラーが発生しました: $e');
    }
  }

  /// クリップボードからキャンバスに画像を貼り付ける
  Future<void> pasteImageFromClipboard() async {
    try {
      final imageBytes = await ClipboardService.getImageFromClipboard();
      if (imageBytes != null) {
        await addImageFromBytes(imageBytes);
      } else {
        _notifyError('クリップボードに画像がありません');
      }
    } on ClipboardException catch (e) {
      _notifyError(e.toString());
    } catch (e) {
      _notifyError('画像の貼り付け中にエラーが発生しました: $e');
    }
  }

  /// バイトデータから画像を追加する
  ///
  /// [imageData] 画像のバイトデータ
  Future<void> addImageFromBytes(Uint8List imageData) async {
    try {
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final imageObject = ImageObject(image: image, globalCenter: _getCanvasCenter());

      _addToHistory(HistoryEntryType.paste);
      _objects.add(imageObject);
      notifyListeners();
    } catch (e) {
      _notifyError('画像の追加中にエラーが発生しました: $e');
      rethrow;
    }
  }

  /// キャンバスの中心座標を取得する
  Offset _getCanvasCenter() {
    if (_canvasSize == null) {
      return const Offset(0, 0);
    }

    return Offset(_canvasSize!.width / 2, _canvasSize!.height / 2);
  }
}
