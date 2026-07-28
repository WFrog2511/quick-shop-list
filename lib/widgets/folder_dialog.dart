import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../models/category.dart';

/// フォルダの新規作成 / 名前変更用ダイアログ
class FolderDialog extends StatefulWidget {
  final ShoppingCategory? folder; // nullなら新規作成

  const FolderDialog({super.key, this.folder});

  @override
  State<FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<FolderDialog> {
  late final TextEditingController _controller;

  bool get isEditing => widget.folder != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.folder?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'フォルダ名を変更' : '新しいフォルダ'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          hintText: '例: 食料品、日用品',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? '保存する' : '作成する'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<ShoppingProvider>();
    if (isEditing) {
      provider.renameFolder(widget.folder!.id, name);
    } else {
      provider.addFolder(name);
    }
    Navigator.pop(context);
  }
}
