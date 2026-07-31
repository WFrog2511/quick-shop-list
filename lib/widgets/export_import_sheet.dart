import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../theme.dart';

/// お気に入りのエクスポート(コピー)/ インポート(貼り付け)機能を提供するボトムシート
/// メモ帳などにテキストとして保存し、後で読み込んで復元できるようにする
class ExportImportSheet extends StatelessWidget {
  const ExportImportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'お気に入りのバックアップ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'テキストとしてコピーし、メモ帳などに保存できます。\n'
              'フォルダ・サブフォルダの階層情報も含めて保存されます。\n'
              '同じ形式のテキストを貼り付けて復元することもできます。',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _copyToClipboard(context),
                icon: const Icon(Icons.copy),
                label: const Text('お気に入りをコピーする'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openImportDialog(context),
                icon: const Icon(Icons.paste_outlined),
                label: const Text('テキストから読み込む'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) async {
    final provider = context.read<ShoppingProvider>();
    final text = provider.exportFavoritesAsText();

    if (text.trim() == '#QuickShopList:Favorites:v2' || text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('お気に入りが登録されていません')));
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('お気に入りをコピーしました。メモ帳などに貼り付けて保存してください'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openImportDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(context: context, builder: (_) => const _ImportTextDialog());
  }
}

/// インポート用のテキスト貼り付けダイアログ
class _ImportTextDialog extends StatefulWidget {
  const _ImportTextDialog();

  @override
  State<_ImportTextDialog> createState() => _ImportTextDialogState();
}

class _ImportTextDialogState extends State<_ImportTextDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      title: const Text('お気に入りを読み込む'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'コピーしたテキストを下に貼り付けてください',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 8,
            minLines: 4,
            decoration: const InputDecoration(
              hintText:
                  '#QuickShopList:Favorites:v2\n[食料品]\n牛乳\n卵\n\n[食料品 / 野菜]\nにんじん\n...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste, size: 18),
                label: const Text('クリップボードから貼り付け'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _submit, child: const Text('読み込む')),
      ],
    );
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _controller.text = data!.text!;
      });
    }
  }

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<ShoppingProvider>();
    final (addedFolders, addedItems, skipped) = await provider
        .importFavoritesFromText(text);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '読み込み完了: 商品$addedItems件・フォルダ$addedFolders件を追加'
            '${skipped > 0 ? '(重複$skipped件はスキップ)' : ''}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
