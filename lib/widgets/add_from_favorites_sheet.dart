import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../models/favorite_item.dart';
import '../models/category.dart';
import '../theme.dart';
import '../screens/favorite_edit_screen.dart';

/// 「お気に入りから追加」ボトムシート
/// 買い物リスト画面から呼び出し、複数選択してまとめて追加できる(操作回数削減)
/// フォルダ(サブフォルダ含む)に入っている商品は、そのフォルダをタップして
/// 開くまで表示しない(見やすさ優先)。
class AddFromFavoritesSheet extends StatefulWidget {
  const AddFromFavoritesSheet({super.key});

  @override
  State<AddFromFavoritesSheet> createState() => _AddFromFavoritesSheetState();
}

class _AddFromFavoritesSheetState extends State<AddFromFavoritesSheet> {
  final Set<String> _selectedIds = {};
  final Set<String> _expandedFolderIds = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final favorites = provider.favorites;
    final topLevelFolders = provider.topLevelFolders;
    final unfiled = favorites
        .where(
          (f) =>
              f.categoryId == null || f.categoryId == uncategorizedCategoryId,
        )
        .toList();
    final colors = AppColors.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'お気に入りから追加',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FavoriteEditScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('新規'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: favorites.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'お気に入りがまだありません。\n右上の「新規」から登録できます。',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // フォルダ(サブフォルダ含む)は折りたたみ表示。
                          // タップして開くまで中の商品・サブフォルダは見えない。
                          ...topLevelFolders.map(
                            (folder) => _buildFolderSection(
                              provider: provider,
                              folder: folder,
                              colors: colors,
                              depth: 0,
                            ),
                          ),
                          // 未分類は常に表示(フォルダに入っていないためすぐ選べる)
                          if (unfiled.isNotEmpty) ...[
                            if (topLevelFolders.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 8,
                                  left: 4,
                                ),
                                child: Text(
                                  '未分類',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ...unfiled.map(
                              (fav) => _SelectableFavoriteTile(
                                favorite: fav,
                                selected: _selectedIds.contains(fav.id),
                                onTap: () => _toggleSelection(fav),
                                colors: colors,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () => _addSelected(context, favorites),
                    child: Text(
                      _selectedIds.isEmpty
                          ? '商品を選択してください'
                          : '${_selectedIds.length}件を買い物リストに追加',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// フォルダ1つ分のセクション(サブフォルダを含めて再帰的に構築)。
  /// このフォルダに直接属する商品数 + 選択中の件数を数え、
  /// 展開したときにサブフォルダ→直属の商品の順で表示する。
  Widget _buildFolderSection({
    required ShoppingProvider provider,
    required ShoppingCategory folder,
    required AppColors colors,
    required int depth,
  }) {
    final directItems = provider.favorites
        .where((f) => f.categoryId == folder.id)
        .toList();
    final subFolders = provider.subFoldersOf(folder.id);
    final totalCountInSubtree = _countFavoritesInSubtree(provider, folder.id);
    if (totalCountInSubtree == 0) return const SizedBox.shrink();

    final expanded = _expandedFolderIds.contains(folder.id);
    final selectedInSubtree = _countSelectedInSubtree(provider, folder.id);

    return Padding(
      padding: EdgeInsets.only(left: depth * 12.0),
      child: _FolderSection(
        label: folder.name,
        count: totalCountInSubtree,
        selectedCount: selectedInSubtree,
        expanded: expanded,
        colors: colors,
        onHeaderTap: () => setState(() {
          if (expanded) {
            _expandedFolderIds.remove(folder.id);
          } else {
            _expandedFolderIds.add(folder.id);
          }
        }),
        children: expanded
            ? [
                ...subFolders.map(
                  (sub) => _buildFolderSection(
                    provider: provider,
                    folder: sub,
                    colors: colors,
                    depth: depth + 1,
                  ),
                ),
                ...directItems.map(
                  (fav) => _SelectableFavoriteTile(
                    favorite: fav,
                    selected: _selectedIds.contains(fav.id),
                    onTap: () => _toggleSelection(fav),
                    colors: colors,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  /// フォルダとそのサブフォルダすべてに含まれるお気に入りの総数
  int _countFavoritesInSubtree(ShoppingProvider provider, String folderId) {
    var count = provider.favoriteCountInCategory(folderId);
    for (final sub in provider.subFoldersOf(folderId)) {
      count += _countFavoritesInSubtree(provider, sub.id);
    }
    return count;
  }

  /// フォルダとそのサブフォルダすべての中で選択済みの件数
  int _countSelectedInSubtree(ShoppingProvider provider, String folderId) {
    var count = provider.favorites
        .where((f) => f.categoryId == folderId && _selectedIds.contains(f.id))
        .length;
    for (final sub in provider.subFoldersOf(folderId)) {
      count += _countSelectedInSubtree(provider, sub.id);
    }
    return count;
  }

  void _toggleSelection(FavoriteItem fav) {
    setState(() {
      if (_selectedIds.contains(fav.id)) {
        _selectedIds.remove(fav.id);
      } else {
        _selectedIds.add(fav.id);
      }
    });
  }

  void _addSelected(BuildContext context, List<FavoriteItem> favorites) {
    final provider = context.read<ShoppingProvider>();
    final selected = favorites
        .where((f) => _selectedIds.contains(f.id))
        .toList();
    provider.addMultipleFromFavorites(selected);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selected.length}件を買い物リストに追加しました'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// フォルダ1つ分の折りたたみセクション。
/// ヘッダーをタップするまで内部(children: サブフォルダ・商品)を表示しない。
class _FolderSection extends StatelessWidget {
  final String label;
  final int count;
  final int selectedCount;
  final bool expanded;
  final AppColors colors;
  final VoidCallback onHeaderTap;
  final List<Widget> children;

  const _FolderSection({
    required this.label,
    required this.count,
    required this.selectedCount,
    required this.expanded,
    required this.colors,
    required this.onHeaderTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: selectedCount > 0
                ? colors.lightGreen
                : colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onHeaderTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedCount > 0
                        ? colors.primaryGreen
                        : colors.divider,
                    width: selectedCount > 0 ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.accentBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.folder,
                        color: colors.accentBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (selectedCount > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$selectedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      '$count件',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }
}

/// タップで選択/解除できるお気に入りタイル(複数選択対応)
class _SelectableFavoriteTile extends StatelessWidget {
  final FavoriteItem favorite;
  final bool selected;
  final VoidCallback onTap;
  final AppColors colors;

  const _SelectableFavoriteTile({
    required this.favorite,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? colors.lightGreen : colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? colors.primaryGreen : colors.divider,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? colors.primaryGreen : colors.checkedGray,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    favorite.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
