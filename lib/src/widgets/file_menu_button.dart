import 'package:flutter/material.dart';

import '../../flexi_sketch_controller.dart';

/// ファイル操作メニューを提供するボタン
class FileMenuButton extends StatelessWidget {
  final FlexiSketchController controller;

  const FileMenuButton({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'save_objects',
          child: Row(
            children: [
              Icon(Icons.save),
              SizedBox(width: 8),
              Text('オブジェクトとして保存'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'save_image',
          child: Row(
            children: [
              Icon(Icons.image),
              SizedBox(width: 8),
              Text('画像として保存'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'save_objects':
            try {
              await controller.saveSketch();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('保存に失敗しました: $e')),
                );
              }
            }
            break;
          case 'save_image':
            try {
              await controller.saveSketch(asImage: true);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('保存に失敗しました: $e')),
                );
              }
            }
            break;
        }
      },
    );
  }
}
