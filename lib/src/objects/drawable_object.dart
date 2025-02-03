import 'package:flutter/material.dart';

import '../serialization/object_serializer.dart';

/// 描画可能なオブジェクトの基底クラス
///
/// すべての描画可能なオブジェクト(パス、図形、画像)に共通する機能を提供します。
/// 移動、回転、スケール(拡大・縮小)、削除などの基本的な変換操作と、選択状態の管理を行います。
abstract class DrawableObject implements Serializable {
  /// オブジェクトが選択されているかどうか
  bool isSelected = false;

  /// グローバル座標系でのオブジェクトの中心点
  Offset globalCenter;

  /// 回転角度[rad]
  double rotation = 0.0;

  /// スケール
  double scale = 1.0;

  /// 変換行列のキャッシュ
  ///
  /// 変換行列の計算は比較的重いため、position/rotation/scaleが変更されるまでキャッシュします。
  /// これにより、同じ変換行列を何度も計算することを避けられます。
  Matrix4? _transformCache;

  /// 逆変換行列のキャッシュ
  ///
  /// 逆行列の計算は特に重い処理のため、変換行列が更新されるまでキャッシュします。
  /// これは主にグローバル座標からローカル座標への変換時に使用されます。
  Matrix4? _inverseTransformCache;

  DrawableObject({
    required this.globalCenter,
    this.rotation = 0.0,
    this.scale = 1.0,
  });

  /// オブジェクトの種類を表す文字列
  @override
  String get type;

  /// オブジェクト固有のシリアライザを取得します
  @override
  ObjectSerializer get serializer;

  /// オブジェクト自身のローカル座標系でのバウンディングボックスを取得する
  ///
  /// 位置(position)、回転(rotation)、スケール(scale)などの変換が適用される前の、オブジェクトの元々のサイズと形状を定義します。
  Rect get localBounds;

  /// 現在の変換を適用したバウンディングボックス(オブジェクトの矩形)を取得する
  ///
  /// 全ての変換(移動、回転、スケール)が適用された後の、キャンバス座標系での実際の矩形領域を表します。
  Rect get bounds {
    return MatrixUtils.transformRect(transform, localBounds);
  }

  /// オブジェクトの変換行列を取得する
  Matrix4 get transform {
    _transformCache ??= _createTransformMatrix();
    return _transformCache!;
  }

  /// 変換行列を生成する
  Matrix4 _createTransformMatrix() {
    final center = localBounds.center;
    return Matrix4.identity()
      ..translate(globalCenter.dx, globalCenter.dy) // グローバル位置への移動
      ..translate(center.dx, center.dy) // 中心を基準に回転・スケール
      ..rotateZ(rotation)
      ..scale(scale)
      ..translate(-center.dx, -center.dy); // 中心での変換を元に戻す
  }

  /// グローバル座標をローカル座標に変換する
  Offset globalToLocal(Offset globalPoint) {
    _inverseTransformCache ??= Matrix4.tryInvert(transform);
    if (_inverseTransformCache == null) {
      // 逆行列が存在しない場合のフォールバック
      return globalPoint - globalCenter;
    }
    return MatrixUtils.transformPoint(_inverseTransformCache!, globalPoint);
  }

  /// ローカル座標をグローバル座標に変換する
  Offset localToGlobal(Offset localPoint) {
    return MatrixUtils.transformPoint(transform, localPoint);
  }

  /// オブジェクトを描画する
  ///
  /// [canvas] 描画対象のキャンバス
  void draw(Canvas canvas) {
    canvas.save();
    canvas.transform(transform.storage);

    // オブジェクトの描画
    drawObject(canvas);

    canvas.restore();

    // 選択 UI の描画(変換を適用せず描画)
    if (isSelected) {
      _drawSelectionUI(canvas);
    }
  }

  /// オブジェクト固有の描画処理
  ///
  /// サブクラスでオーバーライドして実際の描画処理を実装します。
  void drawObject(Canvas canvas);

  /// 選択時の UI(枠線・各種ハンドル)の描画
  ///
  /// オブジェクト選択時に呼び出され、枠線と各種操作(移動、回転、削除、拡大・縮小)用のハンドルを描画します。
  void _drawSelectionUI(Canvas canvas) {
    // 変換済みのバウンディングボックスを取得
    final Rect rect = bounds;
    final Paint borderPaint = Paint()
      ..color = Colors.lightBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(rect, borderPaint);
  }

  /// 指定された線(Path)と交差するかどうか
  ///
  /// [other] 交差判定対象の線(Path)
  bool intersects(Path other) {
    // バウンディングボックスによる高速な判定
    if (!bounds.overlaps(other.getBounds())) {
      return false;
    }

    // 詳細な交差判定はサブクラスで実装
    return checkIntersection(other);
  }

  /// 詳細な交差判定
  ///
  /// サブクラスで実装必須
  /// [other] 交差判定対象の線(Path)
  bool checkIntersection(Path other);

  /// 指定された点がオブジェクト内に含まれるかどうか
  ///
  /// [point] 判定対象の点の座標
  bool containsPoint(Offset point) {
    // バウンディングボックスによる高速な判定
    if (!bounds.contains(point)) {
      return false;
    }

    // グローバル座標 → ローカル座標に変換
    Offset localPoint = globalToLocal(point);

    // 詳細な判定はサブクラスで実装
    return checkContainsPoint(localPoint);
  }

  /// 詳細な点包含判定
  ///
  /// サブクラスで実装必須
  bool checkContainsPoint(Offset localPoint);

  /// オブジェクトを移動する
  ///
  /// [delta] 変位
  void translate(Offset delta) {
    globalCenter += delta;
    _invalidateTransform();
  }

  /// オブジェクトを回転する
  ///
  /// [angle] 回転角度[rad]
  void rotate(double angle) {
    rotation += angle;
    _invalidateTransform();
  }

  /// オブジェクトをリサイズする
  ///
  /// [newScale] スケール値の変更量
  void resize(double newScale) {
    scale *= newScale;
    _invalidateTransform();
  }

  /// 変換行列のキャッシュを無効化する
  void _invalidateTransform() {
    _transformCache = null;
    _inverseTransformCache = null;
  }

  /// オブジェクトの深いコピーを作成する
  ///
  /// このメソッドは、オブジェクトの完全なコピーを作成します。
  /// 変換状態（位置、回転、スケール）も含めて複製されます。
  DrawableObject clone();
}
