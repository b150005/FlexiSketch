import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import '../errors/flexi_sketch_error.dart';

/// 保存ダイアログ
/// スケッチの保存方法を選択するダイアログ
class SaveDialog extends StatefulWidget {
  /// スケッチの状態を管理するコントローラ
  final FlexiSketchController controller;

  const SaveDialog({
    super.key,
    required this.controller,
  });

  @override
  State<SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<SaveDialog> {
  bool _isSaving = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('保存'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          if (widget.controller.canSaveAsImage)
            _SaveOption(
              icon: Icons.image,
              label: '画像として保存',
              onTap: _isSaving ? null : () => _handleSave(true),
            ),
          if (widget.controller.canSaveAsImage && widget.controller.canSaveAsData) const SizedBox(height: 8),
          if (widget.controller.canSaveAsData)
            _SaveOption(
              icon: Icons.data_object,
              label: 'データとして保存',
              onTap: _isSaving ? null : () => _handleSave(false),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }

  Future<void> _handleSave(bool asImage) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (asImage) {
        await widget.controller.handleSaveAsImage();
      } else {
        await widget.controller.handleSaveAsData();
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on SaveHandlerNotSetError {
      // この時点で到達することは通常ないはず
      setState(() {
        _errorMessage = '保存方法が設定されていません';
      });
    } on FlexiSketchError catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

/// 保存オプションを表示するウィジェット
class _SaveOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SaveOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
