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
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.uncheckedCount}',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          body: provider.totalCount == 0
              ? _EmptyState(
                  onAddFromFavorites: () => _openAddFromFavorites(context),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    ...unchecked.map((item) => _ShoppingItemTile(item: item)),
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
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
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
                                foregroundColor: AppColors.textSecondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...checked.map((item) => _ShoppingItemTile(item: item)),
                    ],
                  ],
                ),
          bottomNavigationBar: null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomSheet: _BottomActionBar(
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

  const _ShoppingItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ShoppingProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: item.isChecked
            ? AppColors.lightGreen.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => provider.toggleChecked(item.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: item.isChecked,
                  onChanged: (_) => provider.toggleChecked(item.id),
                ),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 17,
                      color: item.isChecked
                          ? AppColors.checkedGray
                          : AppColors.textPrimary,
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.textSecondary,
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
}

/// 下部固定の操作バー(片手操作を意識し大きめボタン)
class _BottomActionBar extends StatelessWidget {
  final VoidCallback onAddFromFavorites;
  final VoidCallback onAddNew;

  const _BottomActionBar({
    required this.onAddFromFavorites,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
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
  final VoidCallback onAddFromFavorites;

  const _EmptyState({required this.onAddFromFavorites});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 72,
              color: AppColors.checkedGray,
            ),
            const SizedBox(height: 16),
            const Text(
              '買い物リストは空です',
              style: TextStyle(
                fontSize: 17,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '下のボタンからお気に入りを追加しましょう',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
