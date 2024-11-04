import 'package:flutter/material.dart';

/// 保存・読み込み時のプログレス表示用のオーバーレイ
class ProgressOverlay extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  const ProgressOverlay({
    super.key,
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isError) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: isError ? Theme.of(context).colorScheme.error : null,
                  ),
                ),
                if (isError && onRetry != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('再試行'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
