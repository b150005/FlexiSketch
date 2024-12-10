import 'package:flutter/material.dart';

extension Matrix4Extensions on Matrix4 {
  /// スケールと中心位置を指定して変換行列を設定する
  ///
  /// [scaleFactor] スケール値
  /// [contentCenter] コンテンツの中心位置
  /// [viewportSize] ビューポートのサイズ
  void setScaleAndCenter(double scaleFactor, Offset contentCenter, Size viewportSize) {
    // ビューポートの中心を計算
    final viewportCenter = Offset(viewportSize.width / 2, viewportSize.height / 2);

    // コンテンツの中心をスケーリングして、ビューポートの中心との差分を計算
    final adjustment = viewportCenter - contentCenter * scaleFactor;

    setIdentity();
    translate(adjustment.dx, adjustment.dy);
    scale(scaleFactor);
  }
}
