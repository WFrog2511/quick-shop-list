import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../models/category.dart';
import '../theme.dart';
import '../widgets/favorite_tile.dart';
import '../widgets/folder_dialog.dart';
import 'favorite_edit_screen.dart';

/// フォルダ内のお気に入り一覧画面
class FolderDetailScreen extends StatelessWidget {
  final ShoppingCategory folder;

  const FolderDetailScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShoppingProvider>(
      builder: (context, provider, _) {
        // フォルダ名が変更された場合に追従するため、最新のフォルダ情報を取得
        final currentFolder = provider.categories.firstWhere(
          (c) => c.id == folder.id,
          orElse: () => folder,
        );
        final items = provider.favorites
            .where((f) => f.categoryId == folder.id)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              currentFolder.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') {
                    showDialog(
                      context: context,
                      builder: (_) => FolderDialog(folder: currentFolder),
                    );
                  } else if (value == 'delete') {
                    _confirmDeleteFolder(context, provider);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('フォルダ名を変更')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('フォルダを削除', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          body: items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'このフォルダにはまだ商品がありません。\n右下の「追加」からお気に入りを登録できます。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      FavoriteTile(favorite: items[index]),
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

  void _confirmDeleteFolder(BuildContext context, ShoppingProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('フォルダを削除しますか?'),
        content: Text('「${folder.name}」を削除します。中の商品は未分類に移動されます。'),
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
