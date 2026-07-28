import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../models/favorite_item.dart';
import '../theme.dart';
import '../screens/favorite_edit_screen.dart';

/// 「お気に入りから追加」ボトムシート
/// 買い物リスト画面から呼び出し、複数選択してまとめて追加できる(操作回数削減)
class AddFromFavoritesSheet extends StatefulWidget {
  const AddFromFavoritesSheet({super.key});

  @override
  State<AddFromFavoritesSheet> createState() => _AddFromFavoritesSheetState();
}

class _AddFromFavoritesSheetState extends State<AddFromFavoritesSheet> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final favorites = provider.favorites;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
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
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'お気に入りがまだありません。\n右上の「新規」から登録できます。',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final fav = favorites[index];
                          final selected = _selectedIds.contains(fav.id);
                          return _SelectableFavoriteTile(
                            favorite: fav,
                            selected: selected,
                            onTap: () => _toggleSelection(fav),
                          );
                        },
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

/// タップで選択/解除できるお気に入りタイル(複数選択対応)
class _SelectableFavoriteTile extends StatelessWidget {
  final FavoriteItem favorite;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableFavoriteTile({
    required this.favorite,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.lightGreen : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primaryGreen : AppColors.divider,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected
                      ? AppColors.primaryGreen
                      : AppColors.checkedGray,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    favorite.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
