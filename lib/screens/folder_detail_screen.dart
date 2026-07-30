import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../models/category.dart';
import '../theme.dart';
import '../widgets/favorite_tile.dart';
import '../widgets/folder_dialog.dart';
import '../widgets/move_folder_sheet.dart';
import 'favorite_edit_screen.dart';

/// フォルダ内の一覧画面。
/// サブフォルダ一覧 + このフォルダに直接属するお気に入り一覧を表示する。
class FolderDetailScreen extends StatelessWidget {
  final ShoppingCategory folder;

  const FolderDetailScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Consumer<ShoppingProvider>(
      builder: (context, provider, _) {
        // フォルダ名が変更された場合に追従するため、最新のフォルダ情報を取得
        final currentFolder = provider.categories.firstWhere(
          (c) => c.id == folder.id,
          orElse: () => folder,
        );
        final subFolders = provider.subFoldersOf(folder.id);
        final items = provider.favorites
            .where((f) => f.categoryId == folder.id)
            .toList();
        final isEmpty = subFolders.isEmpty && items.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              currentFolder.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: 'サブフォルダを作成',
                onPressed: () => _openCreateSubFolder(context),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') {
                    showDialog(
                      context: context,
                      builder: (_) => FolderDialog(folder: currentFolder),
                    );
                  } else if (value == 'move') {
                    showMoveFolderSheet(context, currentFolder);
                  } else if (value == 'delete') {
                    _confirmDeleteFolder(context, provider);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('フォルダ名を変更')),
                  PopupMenuItem(value: 'move', child: Text('別のフォルダに移動')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('フォルダを削除', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          body: isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'このフォルダにはまだ商品がありません。\n右下の「追加」からお気に入りを登録できます。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    if (subFolders.isNotEmpty) ...[
                      ...subFolders.map(
                        (sub) => _SubFolderTile(
                          folder: sub,
                          count: provider.favoriteCountInCategory(sub.id),
                          subFolderCount: provider.subFoldersOf(sub.id).length,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (items.isNotEmpty) ...[
                      if (subFolders.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 8,
                            left: 4,
                          ),
                          child: Text(
                            '商品',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ...items.map((item) => FavoriteTile(favorite: item)),
                    ],
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FavoriteEditScreen(initialCategoryId: folder.id),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('追加'),
          ),
        );
      },
    );
  }

  void _openCreateSubFolder(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => FolderDialog(parentFolderId: folder.id),
    );
  }

  void _confirmDeleteFolder(BuildContext context, ShoppingProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('フォルダを削除しますか?'),
        content: Text(
          '「${folder.name}」を削除します。中の商品は未分類に移動され、\nサブフォルダは最上位フォルダとして残ります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteFolder(folder.id);
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

/// サブフォルダ1件の行。タップでさらにそのフォルダ内へ遷移する(再帰的にネスト可能)。
class _SubFolderTile extends StatelessWidget {
  final ShoppingCategory folder;
  final int count;
  final int subFolderCount;
  final AppColors colors;

  const _SubFolderTile({
    required this.folder,
    required this.count,
    required this.subFolderCount,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.cardBackground,
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
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.folder, color: colors.accentBlue, size: 20),
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
                  subFolderCount > 0
                      ? '$count件・フォルダ$subFolderCount'
                      : '$count件',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: colors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
