import 'package:flutter/material.dart';

import 'src/history/history_entry.dart';
import 'src/objects/drawable_object.dart';
import 'src/tools/drawing_tool.dart';
import 'src/tools/shape_tool.dart';

class FlexiSketchController extends ChangeNotifier {
  DrawingTool? _currentTool;
  DrawingTool? get currentTool => _currentTool;

  final List<DrawableObject> _objects = [];
  List<DrawableObject> get objects => _objects;

  Color _currentColor = Colors.black;
  Color get currentColor => _currentColor;

  double _currentStrokeWidth = 2.0;
  double get currentStrokeWidth => _currentStrokeWidth;

  PathObject? _currentPath;
  PathObject? get currentPath => _currentPath;

  ShapeObject? _currentShape;
  ShapeObject? get currentShape => _currentShape;

  bool get isToolSelected => _currentTool != null;

  final List<HistoryEntry> _undoStack = [];
  bool get canUndo => _undoStack.isNotEmpty;

  final List<HistoryEntry> _redoStack = [];
  bool get canRedo => _redoStack.isNotEmpty;

  void startDrawing(Offset point) {
    _currentTool?.startDrawing(point, this);
    notifyListeners();
  }

  void addPoint(Offset point) {
    _currentTool?.continueDrawing(point, this);
    notifyListeners();
  }

  void endDrawing() {
    _currentTool?.endDrawing(this);
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    notifyListeners();
  }

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

  void _addToHistory(HistoryEntryType type) {
    _undoStack.add(HistoryEntry(
      objects: List.from(_objects),
      type: type,
    ));
    _redoStack.clear();
    notifyListeners();
  }

  void clear() {
    if (_objects.isNotEmpty) {
      _addToHistory(HistoryEntryType.clear);
      _objects.clear();
      notifyListeners();
    }
  }

  void setTool(DrawingTool? tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void toggleTool(DrawingTool tool) {
    if (isSpecificToolSelected(tool)) {
      setTool(null);
    } else {
      setTool(tool);
    }
  }

  bool isSpecificToolSelected(DrawingTool tool) {
    if (_currentTool == null || _currentTool.runtimeType != tool.runtimeType) {
      return false;
    }
    if (_currentTool is ShapeTool && tool is ShapeTool) {
      return (_currentTool as ShapeTool).shapeType == tool.shapeType;
    }
    return true;
  }

  void startPath(Offset point, {BlendMode blendMode = BlendMode.srcOver}) {
    final path = Path()..moveTo(point.dx, point.dy);
    final paint = _currentTool?.createPaint(_currentColor, _currentStrokeWidth);
    _currentPath = PathObject(path: path, paint: paint ?? Paint());
  }

  void addPointToPath(Offset point) {
    _currentPath?.path.lineTo(point.dx, point.dy);
    notifyListeners();
  }

  void endPath() {
    if (_currentPath != null) {
      _addToHistory(HistoryEntryType.draw);
      _objects.add(_currentPath!);
      _currentPath = null;
      notifyListeners();
    }
  }

  void startErasing(Offset point) {
    final path = Path()..moveTo(point.dx, point.dy);
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..strokeWidth = _currentStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _currentPath = PathObject(path: path, paint: paint);
    notifyListeners();
  }

  void continueErasing(Offset point) {
    if (_currentPath != null) {
      _currentPath!.path.lineTo(point.dx, point.dy);
      if (_objects.any((obj) => obj.intersects(_currentPath!.path))) {
        _addToHistory(HistoryEntryType.erase);
        _objects.removeWhere((obj) => obj.intersects(_currentPath!.path));
      }
      notifyListeners();
    }
  }

  void endErasing() {
    _currentPath = null;
    notifyListeners();
  }

  void startShape(Offset point, ShapeType shapeType) {
    final paint = Paint()
      ..color = _currentColor
      ..strokeWidth = _currentStrokeWidth
      ..style = PaintingStyle.stroke;
    _currentShape = ShapeObject(
      startPoint: point,
      endPoint: point,
      shapeType: shapeType,
      paint: paint,
    );
    notifyListeners();
  }

  void updateShape(Offset point) {
    if (_currentShape != null) {
      _currentShape!.endPoint = point;
      notifyListeners();
    }
  }

  void endShape() {
    if (_currentShape != null) {
      _addToHistory(HistoryEntryType.draw);
      _objects.add(_currentShape!);
      _currentShape = null;
      notifyListeners();
    }
  }
}
