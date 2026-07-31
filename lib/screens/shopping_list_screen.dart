import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../models/shopping_list_item.dart';
import '../theme.dart';
import '../widgets/add_from_favorites_sheet.dart';
import '../widgets/quick_add_dialog.dart';

/// 今日の買い物リスト画面(メイン画面)
/// - チェックだけで完結する操作を最優先
/// - 下部固定ボタンで「お気に入りから追加」「新しい商品」をすぐ押せる
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Consumer<ShoppingProvider>(
      builder: (context, provider, _) {
        final unchecked = provider.uncheckedItems;
        final checked = provider.checkedItems;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text(
                  '今日の買い物リスト',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(width: 8),
                if (provider.totalCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.lightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.uncheckedCount}',
                      style: TextStyle(
                        color: colors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  provider.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                tooltip: provider.isDarkMode ? 'ライトモードに切替' : 'ダークモードに切替',
                onPressed: () => provider.toggleDarkMode(),
              ),
            ],
          ),
          body: provider.totalCount == 0
              ? _EmptyState(
                  colors: colors,
                  onAddFromFavorites: () => _openAddFromFavorites(context),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    ...unchecked.map(
                      (item) => _ShoppingItemTile(item: item, colors: colors),
                    ),
                    if (checked.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                          bottom: 8,
                          left: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '購入済み (${checked.length})',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _confirmClearChecked(context, provider),
                              icon: const Icon(
                                Icons.delete_sweep_outlined,
                                size: 18,
                              ),
                              label: const Text('まとめて削除'),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.textSecondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...checked.map(
                        (item) => _ShoppingItemTile(item: item, colors: colors),
                      ),
                    ],
                  ],
                ),
          bottomNavigationBar: null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomSheet: _BottomActionBar(
            colors: colors,
            onAddFromFavorites: () => _openAddFromFavorites(context),
            onAddNew: () => _openQuickAdd(context),
          ),
        );
      },
    );
  }

  void _openAddFromFavorites(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFromFavoritesSheet(),
    );
  }

  void _openQuickAdd(BuildContext context) {
    showDialog(context: context, builder: (_) => const QuickAddDialog());
  }

  void _confirmClearChecked(BuildContext context, ShoppingProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('購入済みを削除しますか?'),
        content: const Text('チェック済みの商品をリストから削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              provider.clearCheckedItems();
              Navigator.pop(ctx);
            },
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }
}

/// 買い物リストの1行。タップ範囲を広くしてワンタップでチェック切り替え。
class _ShoppingItemTile extends StatelessWidget {
  final ShoppingListItem item;
  final AppColors colors;

  const _ShoppingItemTile({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ShoppingProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: item.isChecked
            ? colors.lightGreen.withValues(alpha: 0.3)
            : colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => provider.toggleChecked(item.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: item.isChecked,
                  onChanged: (_) => provider.toggleChecked(item.id),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 17,
                          color: item.isChecked
                              ? colors.checkedGray
                              : colors.textPrimary,
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.note != null && item.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.note!,
                            style: TextStyle(
                              fontSize: 13,
                              color: item.isChecked
                                  ? colors.checkedGray
                                  : colors.textSecondary,
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                  onPressed: () => _openEditItemDialog(context, provider, item),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                  onPressed: () => provider.deleteShoppingItem(item.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditItemDialog(
    BuildContext context,
    ShoppingProvider provider,
    ShoppingListItem item,
  ) {
    showDialog(
      context: context,
      builder: (_) => _EditShoppingItemDialog(provider: provider, item: item),
    );
  }
}

/// 買い物リストの商品名とメモ(その時々の情報)を編集するダイアログ
class _EditShoppingItemDialog extends StatefulWidget {
  final ShoppingProvider provider;
  final ShoppingListItem item;

  const _EditShoppingItemDialog({required this.provider, required this.item});

  @override
  State<_EditShoppingItemDialog> createState() =>
      _EditShoppingItemDialogState();
}

class _EditShoppingItemDialogState extends State<_EditShoppingItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _noteController = TextEditingController(text: widget.item.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('商品を編集'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '商品名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'メモ(任意)',
              hintText: '例: Sサイズ、特売品でOK、赤色',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            widget.provider.updateShoppingItem(
              widget.item.id,
              name: _nameController.text,
              note: _noteController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 下部固定の操作バー(片手操作を意識し大きめボタン)
class _BottomActionBar extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onAddFromFavorites;
  final VoidCallback onAddNew;

  const _BottomActionBar({
    required this.colors,
    required this.onAddFromFavorites,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: onAddFromFavorites,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              icon: const Icon(Icons.star, size: 20),
              label: const Text(
                'お気に入りから追加',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: onAddNew,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                '新しい商品',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onAddFromFavorites;

  const _EmptyState({required this.colors, required this.onAddFromFavorites});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 72,
              color: colors.checkedGray,
            ),
            const SizedBox(height: 16),
            Text(
              '買い物リストは空です',
              style: TextStyle(
                fontSize: 17,
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '下のボタンからお気に入りを追加しましょう',
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
