import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../theme.dart';

/// ChatGPTなどに作ってもらったMarkdown箇条書きのリストを貼り付けて、
/// まとめて買い物リストに追加できるボトムシート。
/// あわせて、ChatGPTにこの形式で出力してもらうためのサンプルプロンプトを
/// クリップボードにコピーする機能も提供する。
class PasteFromChatGptSheet extends StatefulWidget {
  const PasteFromChatGptSheet({super.key});

  @override
  State<PasteFromChatGptSheet> createState() => _PasteFromChatGptSheetState();
}

class _PasteFromChatGptSheetState extends State<PasteFromChatGptSheet> {
  static const String _samplePrompt =
      '買い物リストを作ってください。\n'
      '出力はMarkdownの箇条書き形式で、以下のルールを守ってください。\n'
      '- 各行の先頭に「- 」を付けて、商品名だけを1行に1つ書く\n'
      '- 見出しや説明文、カテゴリ分けの文章は書かない\n'
      '- 商品名以外の装飾(太字や番号)は付けない\n\n'
      '例:\n'
      '- 牛乳\n'
      '- 卵\n'
      '- にんじん\n\n'
      '【ここに買いたいものの条件を書いてください。例: 今週の献立に必要な食材、キャンプで使う消耗品 など】';

  final TextEditingController _controller = TextEditingController();
  List<String> _preview = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePreview);
    _controller.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final provider = context.read<ShoppingProvider>();
    setState(() {
      _preview = provider.parseMarkdownListItems(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
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
              'ChatGPTからリストを貼り付け',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ChatGPTなどが作った箇条書き(「- 商品名」形式)のリストを'
              '貼り付けると、まとめて買い物リストに追加できます。',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _copySamplePrompt,
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('ChatGPT用サンプルプロンプトをコピー'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 8,
              minLines: 4,
              decoration: const InputDecoration(
                hintText: '- 牛乳\n- 卵\n- にんじん\n...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 4),
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
            const SizedBox(height: 8),
            if (_controller.text.trim().isNotEmpty) ...[
              Text(
                _preview.isEmpty
                    ? '商品として認識できる行が見つかりませんでした'
                    : '認識した商品: ${_preview.length}件',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _preview.isEmpty
                      ? colors.textSecondary
                      : colors.primaryGreen,
                ),
              ),
              if (_preview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.lightGreen.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _preview
                          .map(
                            (name) => Chip(
                              label: Text(
                                name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _preview.isEmpty ? null : _addItems,
                icon: const Icon(Icons.playlist_add),
                label: Text(
                  _preview.isEmpty
                      ? '買い物リストに追加する'
                      : '買い物リストに${_preview.length}件追加',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copySamplePrompt() async {
    await Clipboard.setData(const ClipboardData(text: _samplePrompt));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('サンプルプロンプトをコピーしました。ChatGPTに貼り付けて使ってください'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!;
      _updatePreview();
    }
  }

  void _addItems() async {
    final provider = context.read<ShoppingProvider>();
    final count = await provider.addItemsFromMarkdownList(_controller.text);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('買い物リストに$count件追加しました'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
