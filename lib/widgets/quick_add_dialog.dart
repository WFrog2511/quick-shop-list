import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';

/// 「新しい商品」を買い物リストに直接追加するダイアログ
/// お気に入りにない一時的な商品を追加したいときに使う(文字入力あり)
/// 追加後に「お気に入りにも登録しますか?」を提案し、次回から文字入力なしで使えるよう促す
class QuickAddDialog extends StatefulWidget {
  const QuickAddDialog({super.key});

  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  final TextEditingController _controller = TextEditingController();
  // デフォルトはOFF: お気に入りは「よく買う商品を選んで登録する場所」であり、
  // 買い物リストに追加しただけの商品を自動で履歴的に溜め込まないようにする
  bool _saveToFavorites = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新しい商品を追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: '商品名を入力',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _saveToFavorites,
            onChanged: (v) => setState(() => _saveToFavorites = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('お気に入りにも登録する', style: TextStyle(fontSize: 14)),
            subtitle: const Text(
              'よく買う商品の場合のみチェックしてください',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _submit, child: const Text('追加する')),
      ],
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<ShoppingProvider>();
    provider.addShoppingItemByName(name);
    if (_saveToFavorites) {
      provider.addFavorite(name);
    }
    Navigator.pop(context);
  }
}
