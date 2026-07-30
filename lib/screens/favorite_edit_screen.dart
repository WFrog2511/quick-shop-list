import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../models/favorite_item.dart';
import '../models/category.dart';
import '../theme.dart';
import '../widgets/folder_dialog.dart';

/// お気に入り登録/編集画面
/// このアプリで文字入力が必要になるのは「初回登録」のときだけ。
/// 一度登録すればお気に入り一覧からタップだけで再利用できる。
/// フォルダ(カテゴリ)を選んで整理することもできる。
class FavoriteEditScreen extends StatefulWidget {
  final FavoriteItem? favorite; // nullなら新規登録、値があれば編集
  final String? initialCategoryId; // フォルダ内から新規作成した場合の初期フォルダ

  const FavoriteEditScreen({super.key, this.favorite, this.initialCategoryId});

  @override
  State<FavoriteEditScreen> createState() => _FavoriteEditScreenState();
}

class _FavoriteEditScreenState extends State<FavoriteEditScreen> {
  late final TextEditingController _nameController;
  String? _selectedCategoryId;

  bool get isEditing => widget.favorite != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.favorite?.name ?? '');
    _selectedCategoryId =
        widget.favorite?.categoryId ?? widget.initialCategoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final folderTree = provider.buildFolderTree();
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'お気に入りを編集' : 'お気に入りに登録')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '商品名',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: !isEditing,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: '例: 牛乳、卵、洗剤',
                filled: true,
                fillColor: colors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.divider),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 20),
            Text(
              'フォルダ',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FolderChip(
                  label: '未分類',
                  selected:
                      _selectedCategoryId == null ||
                      _selectedCategoryId == uncategorizedCategoryId,
                  onTap: () => setState(() => _selectedCategoryId = null),
                  colors: colors,
                ),
                ...folderTree.map(
                  (entry) => _FolderChip(
                    label: entry.depth > 0
                        ? '${'　' * entry.depth}└ ${entry.folder.name}'
                        : entry.folder.name,
                    selected: _selectedCategoryId == entry.folder.id,
                    onTap: () =>
                        setState(() => _selectedCategoryId = entry.folder.id),
                    colors: colors,
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('新規フォルダ'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const FolderDialog(),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                if (isEditing)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        '削除',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                if (isEditing) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(isEditing ? '保存する' : '登録する'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<ShoppingProvider>();
    if (isEditing) {
      provider.updateFavorite(
        widget.favorite!.id,
        name: name,
        categoryId: _selectedCategoryId ?? uncategorizedCategoryId,
      );
    } else {
      provider.addFavorite(name, categoryId: _selectedCategoryId);
    }
    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか?'),
        content: Text('「${widget.favorite!.name}」をお気に入りから削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<ShoppingProvider>().deleteFavorite(
                widget.favorite!.id,
              );
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColors colors;

  const _FolderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colors.lightGreen,
      labelStyle: TextStyle(
        color: selected ? colors.primaryGreen : colors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: selected ? colors.primaryGreen : colors.divider),
    );
  }
}
