import 'dart:async';
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

  // プレビュー表示までの待機時間（1秒）
  static const Duration _previewDelay = Duration(milliseconds: 1000);

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
      // 一定距離以上移動したらプレビューを消去して新しいタイマーを開始
      if (distance > _previewCancelDistance) {
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
}
