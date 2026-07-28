// お気に入り商品モデル(よく買う商品を登録しておき、ワンタップで買い物リストへ追加するための元データ)
// categoryId は将来のカテゴリ階層機能のために最初から用意しておく。
class FavoriteItem {
  final String id;
  String name;
  String? categoryId; // 将来のカテゴリ紐付け用。MVPではnull(未分類)でも動作する
  int sortOrder;
  int useCount; // 追加された回数(将来「よく使う順」ソートに活用できる)
  final DateTime createdAt;

  FavoriteItem({
    required this.id,
    required this.name,
    this.categoryId,
    this.sortOrder = 0,
    this.useCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'sortOrder': sortOrder,
      'useCount': useCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FavoriteItem.fromMap(Map<dynamic, dynamic> map) {
    return FavoriteItem(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      categoryId: map['categoryId'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
      useCount: map['useCount'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  FavoriteItem copyWith({
    String? name,
    String? categoryId,
    int? sortOrder,
    int? useCount,
  }) {
    return FavoriteItem(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      useCount: useCount ?? this.useCount,
      createdAt: createdAt,
    );
  }
}
