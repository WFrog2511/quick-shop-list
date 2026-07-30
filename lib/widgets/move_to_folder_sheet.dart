import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../models/favorite_item.dart';
import '../models/category.dart';
import '../theme.dart';

/// お気に入りを別のフォルダへ移動するための選択シート。
/// 「未分類」+ 全ユーザーフォルダを一覧表示し、タップで即移動する。
void showMoveToFolderSheet(BuildContext context, FavoriteItem favorite) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.of(context).cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => MoveToFolderSheet(favorite: favorite),
  );
}

class MoveToFolderSheet extends StatelessWidget {
  final FavoriteItem favorite;

  const MoveToFolderSheet({super.key, required this.favorite});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final colors = AppColors.of(context);
    final tree = provider.buildFolderTree();
    final currentCategoryId = favorite.categoryId ?? uncategorizedCategoryId;

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
              margin: const EdgeInsets.only(bottom: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '「${favorite.name}」をフォルダに移動',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _FolderOptionTile(
                      icon: Icons.inbox_outlined,
                      iconColor: colors.textSecondary,
                      label: '未分類',
                      depth: 0,
                      selected: currentCategoryId == uncategorizedCategoryId,
                      colors: colors,
                      onTap: () => _move(context, null),
                    ),
                    ...tree.map(
                      (entry) => _FolderOptionTile(
                        icon: Icons.folder,
                        iconColor: colors.accentBlue,
                        label: entry.folder.name,
                        depth: entry.depth + 1,
                        selected: currentCategoryId == entry.folder.id,
                        colors: colors,
                        onTap: () => _move(context, entry.folder.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _move(BuildContext context, String? folderId) {
    context.read<ShoppingProvider>().moveFavoriteToFolder(
      favorite.id,
      folderId,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${favorite.name}」を移動しました'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FolderOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int depth;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  const _FolderOptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.depth,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, left: depth * 20.0),
      child: Material(
        color: selected ? colors.lightGreen : colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: selected ? null : onTap,
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
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check, color: colors.primaryGreen, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
