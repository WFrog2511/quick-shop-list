import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../models/category.dart';
import '../theme.dart';
import '../widgets/favorite_tile.dart';
import '../widgets/folder_dialog.dart';
import 'favorite_edit_screen.dart';
import 'folder_detail_screen.dart';

/// お気に入り一覧画面
/// フォルダ(カテゴリ)一覧 + 未分類のお気に入りを表示する。
/// タップで即買い物リストに追加(文字入力不要)、フォルダで整理して探しやすくする。
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShoppingProvider>(
      builder: (context, provider, _) {
        final folders = provider.userFolders;
        final unfiled = provider.favorites
            .where(
              (f) =>
                  f.categoryId == null ||
                  f.categoryId == uncategorizedCategoryId,
            )
            .toList();
        final isEmpty = folders.isEmpty && unfiled.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'お気に入り',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: 'フォルダを作成',
                onPressed: () => _openCreateFolder(context),
              ),
            ],
          ),
          body: isEmpty
              ? const _EmptyFavorites()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    if (folders.isNotEmpty) ...[
                      ...folders.map(
                        (folder) => _FolderTile(
                          folder: folder,
                          count: provider.favoriteCountInCategory(folder.id),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (unfiled.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 8,
                          left: 4,
                        ),
                        child: Text(
                          folders.isEmpty ? 'お気に入り一覧' : '未分類',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ...unfiled.map((fav) => FavoriteTile(favorite: fav)),
                    ],
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddFavorite(context),
            icon: const Icon(Icons.add),
            label: const Text('新規登録'),
          ),
        );
      },
    );
  }

  void _openAddFavorite(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoriteEditScreen()),
    );
  }

  void _openCreateFolder(BuildContext context) {
    showDialog(context: context, builder: (_) => const FolderDialog());
  }
}

/// フォルダ1件の行。タップでフォルダ内一覧へ遷移。
class _FolderTile extends StatelessWidget {
  final ShoppingCategory folder;
  final int count;

  const _FolderTile({required this.folder, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FolderDetailScreen(folder: folder),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.folder,
                    color: AppColors.accentBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    folder.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$count件',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_outline,
              size: 72,
              color: AppColors.checkedGray,
            ),
            const SizedBox(height: 16),
            const Text(
              'お気に入りはまだありません',
              style: TextStyle(
                fontSize: 17,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'よく買う商品を登録しておくと\n次回から文字入力なしで追加できます',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
