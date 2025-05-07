import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import 'drawing_tool.dart';

class PenTool implements DrawingTool {
  // 直線プレビュー関連のプロパティ
  bool _isPreviewActive = false;
  bool _isTimerActive = false;
  Timer? _previewTimer;
  Offset _startPoint = Offset.zero;
  Offset _lastPoint = Offset.zero;

  /// 前回の方向ベクトル
  Offset? _prevDirection;

  // プレビュー表示までの待機時間（1秒）
  static const Duration _previewDelay = Duration(milliseconds: 1500);

  // プレビュー消去の距離の閾値（10ピクセル）
  static const double _previewCancelDistance = 10.0;

  @override
  void startDrawing(Offset point, FlexiSketchController controller) {
    // 元々の処理
    controller.startPath(point);

    // プレビュー関連の状態をリセット
    _isPreviewActive = false;
    _isTimerActive = false;
    _cancelTimer();
    _prevDirection = null;

    // 開始点を保存
    _startPoint = point;
    _lastPoint = point;

    // プレビュータイマーを開始
    _startPreviewTimer(controller);
  }

  @override
  void continueDrawing(Offset point, FlexiSketchController controller) {
    // 元々の処理
    controller.addPointToPath(point);

    // 移動距離を計算
    final double distance = (point - _lastPoint).distance;

    // 始点からの累積移動距離も計算（プレビュー中に重要）
    final double distanceFromStart = (point - _startPoint).distance;

    // 方向ベクトルを計算
    final Offset direction = point - _lastPoint;
    final double directionChange = _calculateDirectionChange(direction);

    _lastPoint = point;

    // タイマーが動作中の場合
    if (_isTimerActive) {
      // 一定距離以上移動したらタイマーをリセット
      if (distance > _previewCancelDistance) {
        _cancelTimer();
        _startPreviewTimer(controller);
      }
    }
    // プレビュー表示中の場合
    else if (_isPreviewActive) {
      // 一定距離以上移動したり、方向が大きく変わったりした場合にプレビューを消去して新しいタイマーを開始
      if (distance > _previewCancelDistance ||
          directionChange > 0.5 || // 方向変化の閾値（ラジアン）
          distanceFromStart > 50) {
        // 始点からの最大距離（画面サイズや用途に応じて調整）
        _isPreviewActive = false;
        controller.clearLinePreview();
        _startPreviewTimer(controller);
      } else {
        // プレビューを更新
        controller.updateLinePreview(_startPoint, point);
      }
    }
  }

  @override
  void endDrawing(FlexiSketchController controller) {
    _cancelTimer();

    // プレビュー表示中の場合
    if (_isPreviewActive) {
      // プレビューの直線を確定
      controller.confirmLinePreview();
    } else {
      // 通常の線を確定
      controller.endPath();
    }

    // プレビュー状態をリセット
    _isPreviewActive = false;
    _isTimerActive = false;
  }

  @override
  Paint createPaint(Color color, double strokeWidth) {
    return Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  // プレビュータイマーを開始
  void _startPreviewTimer(FlexiSketchController controller) {
    _isTimerActive = true;
    _previewTimer = Timer(_previewDelay, () {
      _isTimerActive = false;
      _isPreviewActive = true;
      // プレビュー表示
      controller.showLinePreview(_startPoint, _lastPoint);
    });
  }

  // タイマーをキャンセル
  void _cancelTimer() {
    _previewTimer?.cancel();
    _previewTimer = null;
    _isTimerActive = false;
  }

  /// 方向の変化量を計算する
  double _calculateDirectionChange(Offset newDirection) {
    if (_prevDirection == null) {
      _prevDirection = newDirection;
      return 0.0;
    }

    // 方向ベクトルが非常に小さい場合は変化なしとする
    if (newDirection.distance < 0.001 || _prevDirection!.distance < 0.001) {
      return 0.0;
    }

    // 正規化された方向ベクトル間の角度を計算
    final double dotProduct = (newDirection.dx * _prevDirection!.dx + newDirection.dy * _prevDirection!.dy) /
        (newDirection.distance * _prevDirection!.distance);

    // 内積を[-1, 1]の範囲にクランプし、角度を計算
    final double clampedDot = dotProduct.clamp(-1.0, 1.0);
    final double angle = math.acos(clampedDot);

    _prevDirection = newDirection;
    return angle;
  }
}
