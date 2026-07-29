import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/favorite_item.dart';
import '../models/shopping_list_item.dart';

/// Hiveを使ったローカル永続化サービス
/// Box(テーブルのようなもの)を3つ用意:
/// - shoppingList: 今日の買い物リスト
/// - favorites: お気に入り商品
/// - categories: カテゴリ(将来の階層化用、MVPでは「未分類」のみ)
class StorageService {
  static const String shoppingBoxName = 'shoppingList';
  static const String favoritesBoxName = 'favorites';
  static const String categoriesBoxName = 'categories';
  static const String settingsBoxName = 'settings';
  static const String themeModeKey = 'themeMode';

  late Box _shoppingBox;
  late Box _favoritesBox;
  late Box _categoriesBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _shoppingBox = await Hive.openBox(shoppingBoxName);
    _favoritesBox = await Hive.openBox(favoritesBoxName);
    _categoriesBox = await Hive.openBox(categoriesBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);

    // 初回起動時に「未分類」カテゴリを作成
    if (_categoriesBox.isEmpty) {
      final defaultCategory = ShoppingCategory(
        id: uncategorizedCategoryId,
        name: '未分類',
        sortOrder: 0,
      );
      await _categoriesBox.put(defaultCategory.id, defaultCategory.toMap());
    }
  }

  // ---------- 買い物リスト ----------
  List<ShoppingListItem> loadShoppingList() {
    return _shoppingBox.values
        .map((e) => ShoppingListItem.fromMap(e as Map))
        .toList();
  }

  Future<void> saveShoppingItem(ShoppingListItem item) async {
    await _shoppingBox.put(item.id, item.toMap());
  }

  Future<void> deleteShoppingItem(String id) async {
    await _shoppingBox.delete(id);
  }

  Future<void> clearCheckedShoppingItems(List<String> ids) async {
    await _shoppingBox.deleteAll(ids);
  }

  Future<void> clearAllShoppingItems() async {
    await _shoppingBox.clear();
  }

  // ---------- お気に入り ----------
  List<FavoriteItem> loadFavorites() {
    return _favoritesBox.values
        .map((e) => FavoriteItem.fromMap(e as Map))
        .toList();
  }

  Future<void> saveFavorite(FavoriteItem item) async {
    await _favoritesBox.put(item.id, item.toMap());
  }

  Future<void> deleteFavorite(String id) async {
    await _favoritesBox.delete(id);
  }

  // ---------- カテゴリ(将来拡張用) ----------
  List<ShoppingCategory> loadCategories() {
    return _categoriesBox.values
        .map((e) => ShoppingCategory.fromMap(e as Map))
        .toList();
  }

  Future<void> saveCategory(ShoppingCategory category) async {
    await _categoriesBox.put(category.id, category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _categoriesBox.delete(id);
  }

  // ---------- 設定(テーマなど) ----------
  /// 保存済みのテーマモード名('light'/'dark'/'system')を取得。未設定ならnull。
  String? loadThemeMode() {
    return _settingsBox.get(themeModeKey) as String?;
  }

  Future<void> saveThemeMode(String modeName) async {
    await _settingsBox.put(themeModeKey, modeName);
  }
}
