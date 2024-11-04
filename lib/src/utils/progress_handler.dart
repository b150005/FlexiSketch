import 'package:flutter/material.dart';

import '../widgets/progress_overlay.dart';

/// 保存・読み込み時のプログレス管理用のMixin
mixin ProgressHandler {
  OverlayEntry? _overlayEntry;

  /// プログレス表示を開始する
  void showProgress(BuildContext context, String message) {
    _hideProgress();
    _overlayEntry = OverlayEntry(
      builder: (context) => ProgressOverlay(message: message),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// エラーを表示する
  void showError(BuildContext context, String message, {VoidCallback? onRetry}) {
    _hideProgress();
    _overlayEntry = OverlayEntry(
      builder: (context) => ProgressOverlay(
        message: message,
        isError: true,
        onRetry: onRetry,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// プログレス表示を終了する
  void hideProgress() {
    _hideProgress();
  }

  void _hideProgress() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// リソースの解放
  void disposeProgress() {
    _hideProgress();
  }
}
