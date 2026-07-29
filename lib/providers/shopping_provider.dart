import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/favorite_item.dart';
import '../models/shopping_list_item.dart';
import '../services/storage_service.dart';

/// アプリ全体の状態を管理するProvider
/// 買い物リスト・お気に入り・カテゴリ(将来拡張用)をまとめて扱う
class ShoppingProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  List<ShoppingListItem> _shoppingList = [];
  List<FavoriteItem> _favorites = [];
  List<ShoppingCategory> _categories = [];

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    await _storage.init();
    _shoppingList = _storage.loadShoppingList();
    _favorites = _storage.loadFavorites();
    _categories = _storage.loadCategories();
    _themeMode = _themeModeFromName(_storage.loadThemeMode());
    _sortShoppingList();
    _sortFavorites();
    _sortCategories();
    _isLoaded = true;
    notifyListeners();
  }

  // ============ テーマ(ダークモード切り替え) ============

  ThemeMode _themeModeFromName(String? name) {
    switch (name) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  String _themeModeToName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// ライト⇔ダークをワンタップで切り替える(設定画面を挟まないシンプル操作)
  Future<void> toggleDarkMode() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await _storage.saveThemeMode(_themeModeToName(_themeMode));
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.saveThemeMode(_themeModeToName(mode));
    notifyListeners();
  }

  // ============ 買い物リスト ============

  /// 未チェックを上、チェック済みを下に。それぞれsortOrderで並べる
  void _sortShoppingList() {
    _shoppingList.sort((a, b) {
      if (a.isChecked != b.isChecked) {
        return a.isChecked ? 1 : -1;
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });
  }

  List<ShoppingListItem> get shoppingList => _shoppingList;

  List<ShoppingListItem> get uncheckedItems =>
      _shoppingList.where((e) => !e.isChecked).toList();

  List<ShoppingListItem> get checkedItems =>
      _shoppingList.where((e) => e.isChecked).toList();

  int get totalCount => _shoppingList.length;
  int get uncheckedCount => uncheckedItems.length;

  /// 商品名を直接入力して買い物リストに追加
  Future<void> addShoppingItemByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final item = ShoppingListItem(
      id: _uuid.v4(),
      name: trimmed,
      sortOrder: _nextShoppingSortOrder(),
    );
    _shoppingList.add(item);
    await _storage.saveShoppingItem(item);
    _sortShoppingList();
    notifyListeners();
  }

  /// お気に入りから買い物リストへワンタップ追加
  Future<void> addShoppingItemFromFavorite(FavoriteItem favorite) async {
    // すでに未チェックで同じ名前のアイテムがリストにあれば追加しない(重複防止)
    final alreadyExists = _shoppingList.any(
      (e) => !e.isChecked && e.name == favorite.name,
    );
    if (alreadyExists) return;

    final item = ShoppingListItem(
      id: _uuid.v4(),
      name: favorite.name,
      favoriteItemId: favorite.id,
      sortOrder: _nextShoppingSortOrder(),
    );
    _shoppingList.add(item);
    await _storage.saveShoppingItem(item);

    // 使用回数をカウント(将来「よく使う順」ソートに活用)
    final favIndex = _favorites.indexWhere((f) => f.id == favorite.id);
    if (favIndex != -1) {
      _favorites[favIndex] = _favorites[favIndex].copyWith(
        useCount: _favorites[favIndex].useCount + 1,
      );
      await _storage.saveFavorite(_favorites[favIndex]);
    }

    _sortShoppingList();
    notifyListeners();
  }

  /// 複数のお気に入りを一括追加(お気に入り一覧からの複数選択用)
  Future<void> addMultipleFromFavorites(List<FavoriteItem> favorites) async {
    for (final fav in favorites) {
      await addShoppingItemFromFavorite(fav);
    }
  }

  int _nextShoppingSortOrder() {
    if (_shoppingList.isEmpty) return 0;
    return _shoppingList
            .map((e) => e.sortOrder)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  /// チェック / 未チェックの切り替え(最優先操作)
  Future<void> toggleChecked(String id) async {
    final index = _shoppingList.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _shoppingList[index] = _shoppingList[index].copyWith(
      isChecked: !_shoppingList[index].isChecked,
    );
    await _storage.saveShoppingItem(_shoppingList[index]);
    _sortShoppingList();
    notifyListeners();
  }

  Future<void> deleteShoppingItem(String id) async {
    _shoppingList.removeWhere((e) => e.id == id);
    await _storage.deleteShoppingItem(id);
    notifyListeners();
  }

  /// チェック済みアイテムを一括削除(「買い物完了」操作用)
  Future<void> clearCheckedItems() async {
    final checkedIds = checkedItems.map((e) => e.id).toList();
    _shoppingList.removeWhere((e) => e.isChecked);
    await _storage.clearCheckedShoppingItems(checkedIds);
    notifyListeners();
  }

  // ============ お気に入り ============

  void _sortFavorites() {
    _favorites.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<FavoriteItem> get favorites => _favorites;

  /// カテゴリ別グループ化(将来の階層化画面でそのまま使える形)
  Map<String?, List<FavoriteItem>> get favoritesByCategory {
    final map = <String?, List<FavoriteItem>>{};
    for (final fav in _favorites) {
      map.putIfAbsent(fav.categoryId, () => []).add(fav);
    }
    return map;
  }

  Future<FavoriteItem> addFavorite(String name, {String? categoryId}) async {
    final trimmed = name.trim();
    final item = FavoriteItem(
      id: _uuid.v4(),
      name: trimmed,
      categoryId: categoryId,
      sortOrder: _favorites.isEmpty
          ? 0
          : _favorites.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) +
                1,
    );
    _favorites.add(item);
    await _storage.saveFavorite(item);
    _sortFavorites();
    notifyListeners();
    return item;
  }

  Future<void> updateFavorite(
    String id, {
    String? name,
    String? categoryId,
  }) async {
    final index = _favorites.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _favorites[index] = _favorites[index].copyWith(
      name: name,
      categoryId: categoryId,
    );
    await _storage.saveFavorite(_favorites[index]);
    notifyListeners();
  }

  Future<void> deleteFavorite(String id) async {
    _favorites.removeWhere((e) => e.id == id);
    await _storage.deleteFavorite(id);
    notifyListeners();
  }

  // ============ カテゴリ(お気に入りのフォルダ分け) ============
  // MVPでは1階層のフォルダとして利用。parentCategoryIdは将来のサブフォルダ拡張用に保持。

  void _sortCategories() {
    _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// 「未分類」を含む全カテゴリ(フォルダ)
  List<ShoppingCategory> get categories => _categories;

  /// 「未分類」以外のユーザー作成フォルダ
  List<ShoppingCategory> get userFolders =>
      _categories.where((c) => c.id != uncategorizedCategoryId).toList();

  /// 指定カテゴリに属するお気に入りの件数
  int favoriteCountInCategory(String categoryId) {
    return _favorites
        .where((f) => (f.categoryId ?? uncategorizedCategoryId) == categoryId)
        .length;
  }

  /// 新しいフォルダを作成
  Future<ShoppingCategory> addFolder(String name) async {
    final trimmed = name.trim();
    final category = ShoppingCategory(
      id: _uuid.v4(),
      name: trimmed,
      sortOrder: _categories.isEmpty
          ? 1
          : _categories
                    .map((e) => e.sortOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1,
    );
    _categories.add(category);
    await _storage.saveCategory(category);
    _sortCategories();
    notifyListeners();
    return category;
  }

  /// フォルダ名を変更
  Future<void> renameFolder(String id, String name) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _categories[index] = _categories[index].copyWith(name: name.trim());
    await _storage.saveCategory(_categories[index]);
    notifyListeners();
  }

  /// フォルダを削除。中に入っていたお気に入りは「未分類」に移動する
  Future<void> deleteFolder(String id) async {
    if (id == uncategorizedCategoryId) return; // 未分類は削除不可

    // フォルダ内のお気に入りを未分類へ移動
    for (final fav in _favorites.where((f) => f.categoryId == id).toList()) {
      final index = _favorites.indexWhere((f) => f.id == fav.id);
      _favorites[index] = _favorites[index].copyWith(
        categoryId: uncategorizedCategoryId,
      );
      await _storage.saveFavorite(_favorites[index]);
    }

    _categories.removeWhere((c) => c.id == id);
    await _storage.deleteCategory(id);
    notifyListeners();
  }

  // ============ お気に入りのエクスポート / インポート ============
  // メモ帳などにコピーして保存・復元できるよう、シンプルなテキスト形式で書き出す。
  // 形式:
  //   #QuickShopList:Favorites:v1
  //   [フォルダ名]
  //   商品名
  //   商品名
  //
  //   [未分類]
  //   商品名
  static const String _exportHeader = '#QuickShopList:Favorites:v1';

  /// お気に入り全体をテキスト形式に書き出す
  String exportFavoritesAsText() {
    final buffer = StringBuffer();
    buffer.writeln(_exportHeader);

    final Map<String, List<FavoriteItem>> grouped = {};
    for (final fav in _favorites) {
      final catId = fav.categoryId ?? uncategorizedCategoryId;
      grouped.putIfAbsent(catId, () => []).add(fav);
    }

    for (final folder in userFolders) {
      final items = grouped[folder.id];
      if (items == null || items.isEmpty) continue;
      buffer.writeln();
      buffer.writeln('[${folder.name}]');
      for (final item in items) {
        buffer.writeln(item.name);
      }
    }

    final unfiled = grouped[uncategorizedCategoryId];
    if (unfiled != null && unfiled.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('[未分類]');
      for (final item in unfiled) {
        buffer.writeln(item.name);
      }
    }

    return buffer.toString().trim();
  }

  /// テキストからお気に入りを読み込む(既存データとマージ、重複はスキップ)
  /// 戻り値: (追加したフォルダ数, 追加した商品数, 重複でスキップした数)
  Future<(int, int, int)> importFavoritesFromText(String text) async {
    final lines = text.split('\n');
    String? currentFolderName;
    int addedFolders = 0;
    int addedItems = 0;
    int skipped = 0;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue; // ヘッダー行はスキップ

      if (line.startsWith('[') && line.endsWith(']')) {
        currentFolderName = line.substring(1, line.length - 1).trim();
        continue;
      }

      // 商品名の行
      final itemName = line;
      String? categoryId;

      if (currentFolderName != null && currentFolderName != '未分類') {
        // フォルダ名から既存フォルダを検索、なければ新規作成
        ShoppingCategory? folder;
        for (final c in _categories) {
          if (c.name == currentFolderName && c.id != uncategorizedCategoryId) {
            folder = c;
            break;
          }
        }
        if (folder == null) {
          folder = await addFolder(currentFolderName);
          addedFolders++;
        }
        categoryId = folder.id;
      }

      // 同じフォルダ内に同名の商品がすでにあればスキップ(重複防止)
      final targetCategoryId = categoryId ?? uncategorizedCategoryId;
      final duplicate = _favorites.any(
        (f) =>
            f.name == itemName &&
            (f.categoryId ?? uncategorizedCategoryId) == targetCategoryId,
      );
      if (duplicate) {
        skipped++;
        continue;
      }

      await addFavorite(itemName, categoryId: categoryId);
      addedItems++;
    }

    return (addedFolders, addedItems, skipped);
  }
}
