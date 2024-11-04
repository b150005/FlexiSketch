import 'package:flutter/material.dart';

/// 保存ダイアログ
class SaveDialog extends StatefulWidget {
  const SaveDialog({super.key});

  @override
  State<SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<SaveDialog> {
  final _titleController = TextEditingController(text: '無題のスケッチ');
  bool _saveAsImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('スケッチを保存'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'タイトル',
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('画像として保存'),
            value: _saveAsImage,
            onChanged: (value) {
              setState(() {
                _saveAsImage = value ?? false;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'title': _titleController.text,
              'asImage': _saveAsImage,
            });
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
