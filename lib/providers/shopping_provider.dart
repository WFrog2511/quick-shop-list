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

  // ---------- ChatGPT等のMarkdown箇条書きから一括追加 ----------
  // ChatGPTに「- 商品名」形式で出力してもらい、それを貼り付けるとまとめて
  // 買い物リストに追加できる機能。対応する箇条書き記法:
  //   - 商品名 / * 商品名 / + 商品名
  //   - [ ] 商品名 / - [x] 商品名 (チェックボックス形式)
  //   1. 商品名 / 1) 商品名 (番号付きリスト)
  // 見出し(# ...)、空行、区切り線(---など)は無視する。
  static final RegExp _checkboxLinePattern = RegExp(
    r'^[-*+]\s+\[[ xX]\]\s*(.*)$',
  );
  static final RegExp _bulletLinePattern = RegExp(r'^[-*+]\s+(.*)$');
  static final RegExp _numberedLinePattern = RegExp(r'^\d+[.)]\s+(.*)$');
  static final RegExp _dividerLinePattern = RegExp(r'^[-=*_]{3,}$');
  static final RegExp _boldMarkdownPattern = RegExp(r'\*\*(.*?)\*\*');
  static final RegExp _codeMarkdownPattern = RegExp(r'`([^`]+)`');

  /// テキストからMarkdown箇条書きの商品名だけを抽出する(追加は行わない)。
  List<String> parseMarkdownListItems(String text) {
    final results = <String>[];

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue; // 見出しは無視
      if (_dividerLinePattern.hasMatch(line)) continue; // 区切り線は無視

      String? content;
      final checkboxMatch = _checkboxLinePattern.firstMatch(line);
      if (checkboxMatch != null) {
        content = checkboxMatch.group(1);
      } else {
        final bulletMatch = _bulletLinePattern.firstMatch(line);
        if (bulletMatch != null) {
          content = bulletMatch.group(1);
        } else {
          final numberedMatch = _numberedLinePattern.firstMatch(line);
          if (numberedMatch != null) {
            content = numberedMatch.group(1);
          }
        }
      }

      if (content == null) continue;

      // **太字** や `コード` などの簡易的なMarkdown装飾を取り除く
      content = content.replaceAllMapped(
        _boldMarkdownPattern,
        (m) => m.group(1) ?? '',
      );
      content = content.replaceAllMapped(
        _codeMarkdownPattern,
        (m) => m.group(1) ?? '',
      );
      content = content.trim();

      if (content.isNotEmpty) {
        results.add(content);
      }
    }
    return results;
  }

  /// Markdown箇条書きのテキストを解析し、買い物リストへまとめて追加する。
  /// 戻り値: 追加した商品数
  Future<int> addItemsFromMarkdownList(String text) async {
    final names = parseMarkdownListItems(text);
    for (final name in names) {
      await addShoppingItemByName(name);
    }
    return names.length;
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

  /// 商品名とその時々のメモ(サイズ・色・特売情報など)を編集する。
  /// note に null を渡すとメモを削除できるよう、copyWithを使わず直接組み立てる。
  Future<void> updateShoppingItem(
    String id, {
    String? name,
    String? note,
  }) async {
    final index = _shoppingList.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final current = _shoppingList[index];
    final trimmedNote = note?.trim();
    final updated = ShoppingListItem(
      id: current.id,
      name: (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : current.name,
      isChecked: current.isChecked,
      favoriteItemId: current.favoriteItemId,
      sortOrder: current.sortOrder,
      note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
      addedAt: current.addedAt,
    );
    _shoppingList[index] = updated;
    await _storage.saveShoppingItem(updated);
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

  /// お気に入りを別のフォルダへ移動する(folderIdがnullまたは未分類IDなら未分類に移動)
  /// FavoriteItem.copyWithはnull=「変更なし」の意味を持つため、ここでは直接
  /// 新しいインスタンスを組み立てて確実にcategoryIdを上書きする。
  Future<void> moveFavoriteToFolder(String favoriteId, String? folderId) async {
    final index = _favorites.indexWhere((e) => e.id == favoriteId);
    if (index == -1) return;
    final current = _favorites[index];
    final targetId = folderId ?? uncategorizedCategoryId;
    if (current.categoryId == targetId) return; // 変更なし

    final moved = FavoriteItem(
      id: current.id,
      name: current.name,
      categoryId: targetId,
      sortOrder: current.sortOrder,
      useCount: current.useCount,
      createdAt: current.createdAt,
    );
    _favorites[index] = moved;
    await _storage.saveFavorite(moved);
    notifyListeners();
  }

  // ============ カテゴリ(お気に入りのフォルダ分け) ============
  // parentCategoryIdを使ってフォルダの中にサブフォルダを持てる(階層構造)。

  void _sortCategories() {
    _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// 「未分類」を含む全カテゴリ(フォルダ)
  List<ShoppingCategory> get categories => _categories;

  /// 「未分類」以外のユーザー作成フォルダ(全階層含む)
  List<ShoppingCategory> get userFolders =>
      _categories.where((c) => c.id != uncategorizedCategoryId).toList();

  /// 最上位(親を持たない)のユーザーフォルダ。お気に入りトップ画面の表示に使う。
  List<ShoppingCategory> get topLevelFolders =>
      userFolders.where((c) => c.parentCategoryId == null).toList();

  /// 指定フォルダの直下にあるサブフォルダ一覧
  List<ShoppingCategory> subFoldersOf(String parentId) =>
      userFolders.where((c) => c.parentCategoryId == parentId).toList();

  /// 指定カテゴリに直接属するお気に入りの件数(サブフォルダ内は含まない)
  int favoriteCountInCategory(String categoryId) {
    return _favorites
        .where((f) => (f.categoryId ?? uncategorizedCategoryId) == categoryId)
        .length;
  }

  /// フォルダ選択UI用の表示名(サブフォルダは「親名 / 子名」の形式にする)
  String folderDisplayPath(String folderId) {
    final names = <String>[];
    String? currentId = folderId;
    var guard = 0; // 循環参照があっても無限ループしないための安全策
    while (currentId != null && guard < 10) {
      final folder = _categories.firstWhere(
        (c) => c.id == currentId,
        orElse: () => ShoppingCategory(id: '', name: ''),
      );
      if (folder.id.isEmpty) break;
      names.insert(0, folder.name);
      currentId = folder.parentCategoryId;
      guard++;
    }
    return names.join(' / ');
  }

  /// targetIdがfolderId自身、またはfolderIdの子孫(サブフォルダのさらに下)かどうか判定。
  /// フォルダを自分自身や自分の子の中に移動してしまう循環参照を防ぐために使う。
  bool _isSameOrDescendant(String folderId, String targetId) {
    if (folderId == targetId) return true;
    final children = _categories.where((c) => c.parentCategoryId == folderId);
    for (final child in children) {
      if (_isSameOrDescendant(child.id, targetId)) return true;
    }
    return false;
  }

  /// 新しいフォルダを作成。parentFolderIdを指定するとサブフォルダとして作成される。
  Future<ShoppingCategory> addFolder(
    String name, {
    String? parentFolderId,
  }) async {
    final trimmed = name.trim();
    final category = ShoppingCategory(
      id: _uuid.v4(),
      name: trimmed,
      parentCategoryId: parentFolderId,
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

  /// フォルダを別のフォルダの中に移動する(newParentIdがnullなら最上位に移動)。
  /// 自分自身や自分の子フォルダの中への移動は無視する(循環参照防止)。
  Future<void> moveFolderToParent(String folderId, String? newParentId) async {
    if (folderId == uncategorizedCategoryId) return; // 未分類は移動不可
    if (newParentId != null && _isSameOrDescendant(folderId, newParentId)) {
      return; // 自分自身や子孫フォルダの中には移動できない
    }
    final index = _categories.indexWhere((c) => c.id == folderId);
    if (index == -1) return;
    final current = _categories[index];
    if (current.parentCategoryId == newParentId) return; // 変更なし

    final moved = ShoppingCategory(
      id: current.id,
      name: current.name,
      parentCategoryId: newParentId,
      sortOrder: current.sortOrder,
    );
    _categories[index] = moved;
    await _storage.saveCategory(moved);
    notifyListeners();
  }

  /// フォルダ階層をツリー順(親の直後に子が並ぶ順)でフラット化したリストを返す。
  /// depthは表示時のインデント段数に使う。excludeSubtreeOfを指定すると、
  /// そのフォルダ自身と子孫フォルダを除外する(フォルダ移動時に自分の中へ移動できないようにするため)。
  List<({ShoppingCategory folder, int depth})> buildFolderTree({
    String? excludeSubtreeOf,
  }) {
    final result = <({ShoppingCategory folder, int depth})>[];

    void addChildren(String? parentId, int depth) {
      final children = userFolders
          .where((c) => c.parentCategoryId == parentId)
          .toList();
      for (final child in children) {
        if (excludeSubtreeOf != null &&
            _isSameOrDescendant(excludeSubtreeOf, child.id)) {
          continue;
        }
        result.add((folder: child, depth: depth));
        addChildren(child.id, depth + 1);
      }
    }

    addChildren(null, 0);
    return result;
  }

  /// フォルダを削除。
  /// - 中に入っていたお気に入りは「未分類」に移動する
  /// - 直下のサブフォルダは削除せず、最上位(親なし)に上げる
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

    // 直下のサブフォルダは削除せず最上位に上げる(データを失わないため)
    for (final child in subFoldersOf(id)) {
      final index = _categories.indexWhere((c) => c.id == child.id);
      final promoted = ShoppingCategory(
        id: child.id,
        name: child.name,
        parentCategoryId: null,
        sortOrder: child.sortOrder,
      );
      _categories[index] = promoted;
      await _storage.saveCategory(promoted);
    }

    _categories.removeWhere((c) => c.id == id);
    await _storage.deleteCategory(id);
    notifyListeners();
  }

  // ============ お気に入りのエクスポート / インポート ============
  // メモ帳などにコピーして保存・復元できるよう、シンプルなテキスト形式で書き出す。
  // v2形式: フォルダ階層は「親 / 子 / 孫」のパス形式で1行に記録することで、
  // サブフォルダの構造も含めて復元できるようにする。
  // 形式:
  //   #QuickShopList:Favorites:v2
  //   [フォルダ名]
  //   商品名
  //   商品名
  //
  //   [親フォルダ名 / 子フォルダ名]
  //   商品名
  //
  //   [未分類]
  //   商品名
  static const String _exportHeader = '#QuickShopList:Favorites:v2';
  static const String _folderPathSeparator = ' / ';

  /// お気に入り全体をテキスト形式に書き出す(フォルダ階層情報を含む)
  String exportFavoritesAsText() {
    final buffer = StringBuffer();
    buffer.writeln(_exportHeader);

    final Map<String, List<FavoriteItem>> grouped = {};
    for (final fav in _favorites) {
      final catId = fav.categoryId ?? uncategorizedCategoryId;
      grouped.putIfAbsent(catId, () => []).add(fav);
    }

    // buildFolderTree()は親フォルダの直後に子フォルダが続く順で返すため、
    // 階層をそのままパス表記で書き出すことができる。
    // アイテムが1件もない空フォルダも、階層構造を保持するために出力する。
    for (final entry in buildFolderTree()) {
      final folder = entry.folder;
      final items = grouped[folder.id] ?? const [];
      buffer.writeln();
      buffer.writeln('[${folderDisplayPath(folder.id)}]');
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
  /// フォルダ見出しは「親 / 子 / 孫」のパス形式(v2)にも、単一フォルダ名のみ
  /// (旧v1形式)にも対応する。パスの各階層を順にたどり、既存フォルダがあれば
  /// それを使い、なければ同じ親の下に新規作成する。
  /// 戻り値: (追加したフォルダ数, 追加した商品数, 重複でスキップした数)
  Future<(int, int, int)> importFavoritesFromText(String text) async {
    final lines = text.split('\n');
    String? currentCategoryId; // nullなら未分類
    int addedFolders = 0;
    int addedItems = 0;
    int skipped = 0;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue; // ヘッダー行はスキップ

      if (line.startsWith('[') && line.endsWith(']')) {
        final pathText = line.substring(1, line.length - 1).trim();
        if (pathText == '未分類') {
          currentCategoryId = null;
          continue;
        }

        // 「親 / 子 / 孫」のパスを1階層ずつ解決(なければ作成)する
        final segments = pathText
            .split(_folderPathSeparator)
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        String? parentId;
        for (final segment in segments) {
          ShoppingCategory? folder;
          for (final c in _categories) {
            if (c.name == segment &&
                c.id != uncategorizedCategoryId &&
                c.parentCategoryId == parentId) {
              folder = c;
              break;
            }
          }
          if (folder == null) {
            folder = await addFolder(segment, parentFolderId: parentId);
            addedFolders++;
          }
          parentId = folder.id;
        }
        currentCategoryId = parentId;
        continue;
      }

      // 商品名の行
      final itemName = line;
      final categoryId = currentCategoryId;

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
