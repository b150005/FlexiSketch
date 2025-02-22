import 'dart:io';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

import 'package:flexi_sketch/src/config/flexi_sketch_size_config.dart';
import 'package:flexi_sketch/src/extensions/matrix4_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'src/errors/flexi_sketch_error.dart';
import 'src/history/history_entry.dart';
import 'src/objects/drawable_object.dart';
import 'src/objects/image_object.dart';
import 'src/objects/path_object.dart';
import 'src/objects/shape_object.dart';
import 'src/objects/text_object.dart';
import 'src/serialization/serializers/drawable_object_serializer.dart';
import 'src/services/clipboard_service.dart';
import 'src/storage/sketch_data.dart';
import 'src/tools/drawing_tool.dart';
import 'src/tools/shape_tool.dart';
import 'src/utils/flexi_sketch_data_helper.dart';
import 'src/utils/flexi_sketch_size_helper.dart';
import 'src/widgets/icon_list_tile.dart';
import 'src/widgets/text_input_dialog.dart';

class FlexiSketchController extends ChangeNotifier {
  /// コンテキスト
  final BuildContext? context;

  /// 画像オブジェクトを消しゴムの対象外とするかどうか
  ///
  /// `true` の場合、 `ImageObject` は消しゴムによって削除されません。
  final bool preserveImages;

  /// コンストラクタ
  ///
  /// [preserveImages] 画像オブジェクトを消しゴムの対象外とするかどうか（デフォルト: `false`)
  FlexiSketchController({
    this.context,
    this.preserveImages = false,
  });

  /// 選択中の描画ツール
  DrawingTool? _currentTool;
  DrawingTool? get currentTool => _currentTool;

  /// キャンバス上の描画オブジェクトのリスト
  final List<DrawableObject> _objects = [];

  List<DrawableObject> get objects => _objects;

  set objects(List<DrawableObject> value) {
    _objects.clear();
    _objects.addAll(value);
  }

  /// 描画色
  Color _currentColor = Colors.black;
  Color get currentColor => _currentColor;

  /// 線の太さ
  double _currentStrokeWidth = 8.0;
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

  /// 読み込んだJSONデータ
  Map<String, dynamic>? _initialJson;

  /// 変形開始時の状態
  DrawableObject? _transformStartState;

  /// エラー通知用のコールバック関数
  void Function(String message)? onError;

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
    if (hasSelection) {
      // 選択中のオブジェクトがある場合は、そのオブジェクトの色を変更
      _updateSelectedObjectColor(color);
    }

    // 現在の描画色を更新（新規オブジェクト用）
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

    // 現在の状態を Redo スタックに保存（深いコピーを作成）
    _redoStack.add(HistoryEntry(
      objects: _objects.map((obj) => obj.clone()).toList(),
      type: entry.type,
    ));

    // 選択状態をクリア
    clearSelection();

    // オブジェクトを履歴の状態に置き換え（各オブジェクトは既にclone済み）
    _objects.clear();
    _objects.addAll(entry.objects);

    notifyListeners();
  }

  /// やり直す
  void redo() {
    if (!canRedo) return;

    final entry = _redoStack.removeLast();

    // 現在の状態を Undo スタックに保存（深いコピーを作成）
    _undoStack.add(HistoryEntry(
      objects: _objects.map((obj) => obj.clone()).toList(),
      type: entry.type,
    ));

    // 選択状態をクリア
    clearSelection();

    // オブジェクトを履歴の状態に置き換え（各オブジェクトは既にclone済み）
    _objects.clear();
    _objects.addAll(entry.objects);

    notifyListeners();
  }

  /// 履歴に操作を追加する
  ///
  /// [type] 履歴エントリの種類
  void _addToHistory(
    HistoryEntryType type, {
    bool clearRedoStack = true,
  }) {
    // 現在の状態を Undo スタックに保存（深いコピーを作成）
    _undoStack.add(HistoryEntry(
      objects: _objects.map((obj) => obj.clone()).toList(),
      type: type,
    ));

    if (clearRedoStack) {
      _redoStack.clear();
    }
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
      ..color = Colors.red.withValues(alpha: 0.3)
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
      final Offset localPoint = _currentPath!.globalToLocal(point);
      _currentPath!.addPoint(localPoint);

      // 変換済みのパスを使用して交差判定
      if (_objects.any((obj) =>
          // preserveImages が true の場合、 ImageObject は判定から除外
          (!preserveImages || obj is! ImageObject) && obj.intersects(_currentPath!.getTransformedPath()))) {
        _addToHistory(HistoryEntryType.erase);
        _objects.removeWhere(
            (obj) => (!preserveImages || obj is! ImageObject) && obj.intersects(_currentPath!.getTransformedPath()));
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

  /// テキスト入力を開始する
  void startText(Offset point) async {
    if (context == null) return;
    // テキスト入力ダイアログを表示
    final String? text = await showDialog<String>(
      context: context!,
      builder: (context) => const TextInputDialog(),
    );

    if (text != null && text.isNotEmpty) {
      final paint = Paint()
        ..color = _currentColor
        ..strokeWidth = _currentStrokeWidth
        ..style = PaintingStyle.fill;

      final textObject = TextObject(
        text: text,
        globalCenter: point,
        paint: paint,
        fontSize: _currentStrokeWidth * 10, // フォントサイズは線の太さに比例
      );

      // テキスト入力時は TextObject を選択状態にする
      selectObject(textObject);

      _addToHistory(HistoryEntryType.draw);
      _objects.add(textObject);

      // テキスト入力後はテキストツールの選択を解除する(内部で notifyListeners() が呼び出される)
      setTool(null);
    }
  }

  /// テキストオブジェクトを編集する
  Future<void> editText(TextObject textObject) async {
    if (context == null) return;

    // テキスト入力ダイアログを表示
    final String? newText = await showDialog<String>(
      context: context!,
      builder: (context) => TextInputDialog(
        initialText: textObject.text,
        submitLabel: '更新',
      ),
    );

    if (newText != null && newText.isNotEmpty && newText != textObject.text) {
      // 変更前の状態を履歴に追加
      _addToHistory(HistoryEntryType.transform);

      // テキストを更新
      textObject.text = newText;

      notifyListeners();
    }
  }

  /// 指定された点にある描画オブジェクトを取得する
  ///
  /// [point] 判定する点の座標
  /// Returns: 点が領域内にあるオブジェクト。領域内にオブジェクトがない場合は `null`
  DrawableObject? hitTest(Offset point) {
    // 最前面のオブジェクトから順に判定
    for (final object in _objects.reversed) {
      if (object.containsPoint(point)) {
        return object;
      }
    }
    return null;
  }

  /// オブジェクトを選択する
  void selectObjectAtPoint(Offset point) {
    // 選択済みオブジェクトがあればその選択状態を解除
    clearSelection();

    // ツール使用中は選択を無効化
    if (_currentTool != null) return;

    _selectedObject = hitTest(point);
    _selectedObject?.isSelected = true;

    notifyListeners();
  }

  /// オブジェクトを選択する
  void selectObject(DrawableObject object) {
    // 選択済みオブジェクトがあればその選択状態を解除
    clearSelection();

    _selectedObject = object;
    _selectedObject?.isSelected = true;

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
      if (_selectedObject is ImageObject && preserveImages) return;
      _addToHistory(HistoryEntryType.delete);
      _objects.remove(_selectedObject);
      _selectedObject = null;
      notifyListeners();
    }
  }

  /// 選択中のオブジェクトの色を変更する
  void _updateSelectedObjectColor(Color color) {
    if (_selectedObject == null) return;

    // 履歴に追加
    _addToHistory(HistoryEntryType.transform);

    if (_selectedObject is PathObject) {
      final pathObj = _selectedObject as PathObject;
      pathObj.paint.color = color;
    } else if (_selectedObject is ShapeObject) {
      final shapeObj = _selectedObject as ShapeObject;
      shapeObj.paint.color = color;
    } else if (_selectedObject is TextObject) {
      final textObj = _selectedObject as TextObject;
      textObj.paint.color = color;
    }

    notifyListeners();
  }

  /// 変形操作を開始する
  ///
  /// 現在選択中のオブジェクトの状態を保存します。
  void beginTransform() {
    if (_selectedObject != null) {
      _transformStartState = _selectedObject!.clone();
      // 実際に位置、回転、スケールのいずれかが変更されるかは保留し、現在の状態を Undo スタックに仮保存する
      // ただし、変更がない場合のことも考慮し Redo スタックは初期化しない
      _addToHistory(HistoryEntryType.transform, clearRedoStack: false);
    }
  }

  /// 変形操作を終了する
  ///
  /// 変形前後で状態が変化している場合のみ履歴に追加します。
  void endTransform() {
    if (_selectedObject != null && _transformStartState != null) {
      // 位置、回転、スケールのいずれも変化していない場合は Undo スタックに仮保存した操作開始時の状態を削除する
      if (_selectedObject!.globalCenter == _transformStartState!.globalCenter &&
          _selectedObject!.rotation == _transformStartState!.rotation &&
          _selectedObject!.scale == _transformStartState!.scale) {
        _undoStack.removeLast();
      }
      _transformStartState = null;
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
    onError?.call(message);
  }

  /// 画像を取得してキャンバスに追加する
  ///
  /// [source] 画像の取得方法（カメラ/ギャラリー）
  /// エラーが発生した場合は [_notifyError] を通じてエラーメッセージが通知される
  Future<void> pickAndAddImage([ImageSource? source]) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await (source != null
          ? picker.pickImage(
              source: source,
            )
          : picker.pickImage(source: ImageSource.gallery));

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        await addImageFromBytes(bytes);
      }
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        _notifyError('画像へのアクセス権限が必要です。\n設定からアプリの権限を変更することができます。');
      } else {
        _notifyError('画像の取得中にエラーが発生しました: ${e.message}');
      }
      rethrow;
    } catch (e) {
      _notifyError('画像の取得中にエラーが発生しました: $e');
      rethrow;
    }
  }

  /// 画像ピッカーを表示し、選択された画像をキャンバスに追加します
  ///
  /// モバイル端末(iOS/Android)の場合は、カメラ/ギャラリーの選択用ボトムシートを表示します。
  /// デスクトップ/Webの場合は、直接ファイル選択ダイアログを表示します。
  ///
  /// 権限エラーや画像の読み込みエラーが発生した場合は、[_notifyError]を通じてエラーメッセージが通知され、
  /// 例外がスローされます。
  ///
  /// [context] 画像ピッカーを表示するためのBuildContext
  void showImagePickerAndAddImage(BuildContext context) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // モバイル端末の場合はボトムシートを表示
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                IconListTile(
                  icon: Icons.photo_library,
                  title: 'カメラロールから選択',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                IconListTile(
                  icon: Icons.camera_alt,
                  title: 'カメラで撮影',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('キャンセル'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      try {
        await pickAndAddImage(source);
      } catch (e) {
        if (!context.mounted) return;

        // エラーダイアログを表示
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text('エラー'),
              content: Text(
                e.toString().contains('permission')
                    ? '画像へのアクセス権限が必要です。\n設定からアプリの権限を変更することができます。'
                    : '画像の取得中にエラーが発生しました。',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      // デスクトップまたはWebの場合は既存の処理を使用
      await pickAndAddImage();
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
  /// [config] サイズ調整の設定（省略時はデフォルト設定を使用）
  Future<void> addImageFromBytes(
    Uint8List imageData, {
    FlexiSketchSizeConfig config = FlexiSketchSizeConfig.defaultConfig,
    bool addHistory = true,
  }) async {
    try {
      // 画像をデコード
      final ui.Image decodedImage = await FlexiSketchDataHelper.decodeImageFromBytes(imageData);

      // 画像の元サイズを使用（リサイズしない）
      final Size imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );

      // キャンバスサイズの更新（必要に応じて）
      final Size effectiveCanvasSize = _canvasSize ??
          FlexiSketchSizeHelper.calculateCanvasSize(
            imageSize: imageSize,
            config: config,
          );

      // 画像オブジェクトを生成（元のサイズを維持）
      final ImageObject imageObject = FlexiSketchDataHelper.createImageObject(
        image: decodedImage,
        center: FlexiSketchDataHelper.getCanvasCenter(effectiveCanvasSize),
        size: imageSize, // 元のサイズを使用
      );

      // 履歴に追加して画像を配置
      if (addHistory) {
        _addToHistory(HistoryEntryType.paste);
      }
      _objects.add(imageObject);

      // InfiniteCanvasの初期ズームを設定するためのイベントを発火
      notifyListeners();
    } catch (e) {
      _notifyError('画像の追加中にエラーが発生しました: $e');
      developer.log('データの読み込みに失敗しました: $e');
      rethrow;
    }
  }

  /* 保存処理 */

  /// キャンバスの内容を JSON データとして生成します
  ///
  /// 画像データを含む場合は UI スレッドのブロッキングが発生します
  Future<Map<String, dynamic>> generateJsonData([
    SketchMetadata? metadata,
  ]) async {
    try {
      final int totalObjects = _objects.length;
      if (totalObjects == 0) {
        return {
          'metadata': metadata?.toJson() ?? SketchMetadata.create('Untitled Sketch').toJson(),
          'content': {
            'version': 1,
            'canvas': {
              'width': _canvasSize?.width ?? 0,
              'height': _canvasSize?.height ?? 0,
            },
            'objects': [],
          },
        };
      }

      // 各オブジェクトのシリアライズを個別に実行して進捗を監視
      final List<Map<String, dynamic>> serializedObjects = <Map<String, dynamic>>[];

      // オブジェクトごとに順次シリアライズ
      for (final DrawableObject object in _objects) {
        final Map<String, dynamic> json = await DrawableObjectSerializer.instance.toJson(object);
        serializedObjects.add(json);
      }

      final Map<String, Object> content = {
        'version': 1,
        'canvas': {
          'width': _canvasSize?.width ?? 0,
          'height': _canvasSize?.height ?? 0,
        },
        'objects': serializedObjects,
      };

      return {
        'metadata': metadata?.toJson() ?? SketchMetadata.create('Untitled Sketch').toJson(),
        'content': content,
      };
    } catch (e) {
      throw DataGenerationError('Failed to generate sketch data', e);
    }
  }

  /// キャンバスの内容を画像データとして生成します
  Future<Uint8List> generateImageData() async {
    // オブジェクトの選択状態を解除
    clearSelection();

    try {
      // コンテンツの範囲を計算（マージン付き）
      final Rect contentBounds = _calculateContentBounds();

      // 描画用のPictureRecorderを作成
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // 背景を描画（白色）
      canvas.drawRect(
        Offset.zero & contentBounds.size,
        Paint()..color = Colors.white,
      );

      // コンテンツの位置を調整
      canvas.translate(-contentBounds.left, -contentBounds.top);

      // すべてのオブジェクトを描画
      for (final object in _objects) {
        object.draw(canvas);
      }

      // 描画中のオブジェクトがあれば描画
      if (_currentPath != null) {
        _currentPath!.draw(canvas);
      }
      if (_currentShape != null) {
        _currentShape!.draw(canvas);
      }

      // Pictureを完成させる
      final ui.Picture picture = recorder.endRecording();

      // より高解像度の画像に変換
      final ui.Image image = await picture.toImage(contentBounds.width.round(), contentBounds.height.round());

      // PNG形式でエンコード（可能な限り高品質に設定）
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw const ImageGenerationError('Failed to convert image to byte data');
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      throw ImageGenerationError('Failed to generate image data', e);
    }
  }

  /// キャンバスのバウンディングボックスを計算する
  ///
  /// すべての描画オブジェクトを含む最小の矩形を計算します。
  /// マージンを指定することで、オブジェクトの周囲に余白を設けることができます。
  Rect _calculateContentBounds([double margin = 0]) {
    if (_objects.isEmpty) {
      // オブジェクトがない場合はキャンバスサイズを基準に
      return Rect.fromLTWH(
        0,
        0,
        _canvasSize?.width ?? 800,
        _canvasSize?.height ?? 600,
      );
    }

    // 全オブジェクトのバウンディングボックスを統合
    Rect bounds = _objects.first.bounds;
    for (final DrawableObject object in _objects.skip(1)) {
      bounds = bounds.expandToInclude(object.bounds);
    }

    // 描画中のオブジェクトがあれば含める
    if (_currentPath != null) {
      bounds = bounds.expandToInclude(_currentPath!.bounds);
    }
    if (_currentShape != null) {
      bounds = bounds.expandToInclude(_currentShape!.bounds);
    }

    // マージンを追加
    return Rect.fromLTWH(
      bounds.left - margin,
      bounds.top - margin,
      bounds.width + margin * 2,
      bounds.height + margin * 2,
    );
  }

  /// JSONデータからスケッチを読み込む
  ///
  /// [json] 読み込むJSONデータ。キャンバス情報とオブジェクト情報を含む
  ///
  /// エラーが発生した場合は [_notifyError] を通じてエラーメッセージが通知される
  Future<void> loadFromJson(Map<String, dynamic> json) async {
    try {
      _objects.clear();

      // JSONデータを保存（calculateInitialTransformで使用）
      _initialJson = json;

      // キャンバスサイズの復元
      final Map<String, dynamic> canvas = json['canvas'] as Map<String, dynamic>;
      _canvasSize = Size(
        (canvas['width'] as num).toDouble(),
        (canvas['height'] as num).toDouble(),
      );

      // オブジェクトの復元
      final List<dynamic> serializedObjects = json['objects'] as List<dynamic>;
      final List<DrawableObject> deserializedObjects = await Future.wait(
        serializedObjects.map((obj) => DrawableObjectSerializer.instance.fromJson(obj as Map<String, dynamic>)),
      );

      // 復元したオブジェクトを追加
      _objects.addAll(deserializedObjects);

      // 選択状態をリセット
      clearSelection();

      notifyListeners();
    } catch (e) {
      developer.log('データの読み込みに失敗しました: $e');
      _notifyError('データの読み込みに失敗しました: $e');
      rethrow;
    }
  }

  /// JSONデータ読み込み時の初期変換行列を計算する
  Matrix4? calculateInitialTransform(Size viewportSize) {
    if (_objects.isEmpty || _canvasSize == null) return null;

    // 初期変換情報がある場合はそれを使用
    if (_initialJson != null &&
        _initialJson!['content'] is Map<String, dynamic> &&
        _initialJson!['content']['initialTransform'] is Map<String, dynamic>) {
      final transform = _initialJson!['content']['initialTransform'] as Map<String, dynamic>;

      final double scale = transform['scale'] as double;
      final double centerX = transform['centerX'] as double;
      final double centerY = transform['centerY'] as double;

      // 変換行列を作成
      final Matrix4 result = Matrix4.identity();
      result.translate(centerX, centerY);
      result.scale(scale);
      result.translate(-centerX, -centerY);

      return result;
    }

    // 全オブジェクトのバウンディングボックスを計算
    Rect contentBounds = _objects.first.bounds;
    for (final DrawableObject object in _objects.skip(1)) {
      contentBounds = contentBounds.expandToInclude(object.bounds);
    }

    // コンテンツと画面の両方のアスペクト比を計算
    final double contentAspectRatio = contentBounds.width / contentBounds.height;
    final double viewportAspectRatio = viewportSize.width / viewportSize.height;

    // スケールを計算（幅と高さの両方に20pxのパディングを考慮）
    final double scaleX = (viewportSize.width - 40) / contentBounds.width;
    final double scaleY = (viewportSize.height - 40) / contentBounds.height;

    // アスペクト比を維持しながら、最適なスケールを選択
    final double scaleFactor = contentAspectRatio > viewportAspectRatio ? scaleX : scaleY;

    // 変換行列を作成
    final Matrix4 result = Matrix4.identity();
    result.setScaleAndCenter(scaleFactor, contentBounds.center, viewportSize);

    return result;
  }
}
