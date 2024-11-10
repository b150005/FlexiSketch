import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';
import '../errors/flexi_sketch_error.dart';

/// ファイル操作メニューを提供するボタン
class FileMenuButton extends StatefulWidget {
  final FlexiSketchController controller;
  final void Function(String message)? onError;

  const FileMenuButton({
    super.key,
    required this.controller,
    this.onError,
  });

  @override
  State<FileMenuButton> createState() => _FileMenuButtonState();
}

class _FileMenuButtonState extends State<FileMenuButton> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      icon: const Icon(Icons.menu),
      onSelected: (callback) => callback(),
      itemBuilder: (context) => [
        if (widget.controller.canSaveAsImage)
          PopupMenuItem(
            enabled: !_isSaving,
            value: () => _handleSave(asImage: true),
            child: const _MenuItemContent(
              icon: Icons.image,
              label: '画像として保存',
            ),
          ),
        if (widget.controller.canSaveAsData)
          PopupMenuItem(
            enabled: !_isSaving,
            value: () => _handleSave(asImage: false),
            child: const _MenuItemContent(
              icon: Icons.data_object,
              label: 'データとして保存',
            ),
          ),
      ],
    );
  }

  Future<void> _handleSave({required bool asImage}) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // StorageFeatures mixinのsaveSketchを使用
      await widget.controller.saveSketch(asImage: asImage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました')),
        );
      }
    } on SaveHandlerNotSetError catch (e) {
      widget.onError?.call(e.message);
    } on FlexiSketchError catch (e) {
      widget.onError?.call(e.message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _MenuItemContent extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItemContent({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
