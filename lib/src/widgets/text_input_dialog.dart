import 'package:flutter/material.dart';

class TextInputDialog extends StatefulWidget {
  final String? initialText;
  final String? submitLabel;

  const TextInputDialog({
    super.key,
    this.initialText,
    this.submitLabel,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);

    // テキストを全選択状態にする
    if (widget.initialText != null) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.initialText!.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('テキストを入力'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'ここに入力してください',
        ),
        autofocus: true,
        maxLines: null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.submitLabel ?? '追加'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
