// 買い物リストの1アイテム
// favoriteItemId を保持することで、お気に入り由来かどうかを追跡できる(将来の履歴分析等に活用可能)
class ShoppingListItem {
  final String id;
  String name;
  bool isChecked;
  String? favoriteItemId; // お気に入りから追加された場合の元IDを保持
  int sortOrder;
  String? note; // その時々のメモ(特売品を選ぶ、サイズ指定など、買うたびに変わる情報)
  final DateTime addedAt;

  ShoppingListItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.favoriteItemId,
    this.sortOrder = 0,
    this.note,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isChecked': isChecked,
      'favoriteItemId': favoriteItemId,
      'sortOrder': sortOrder,
      'note': note,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory ShoppingListItem.fromMap(Map<dynamic, dynamic> map) {
    return ShoppingListItem(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      isChecked: map['isChecked'] as bool? ?? false,
      favoriteItemId: map['favoriteItemId'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
      note: map['note'] as String?,
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// 通常の項目更新用(noteは常に現在の値を維持する)。
  /// noteの変更・クリアはShoppingProvider側で直接インスタンスを組み立てて行う。
  ShoppingListItem copyWith({
    String? name,
    bool? isChecked,
    String? favoriteItemId,
    int? sortOrder,
  }) {
    return ShoppingListItem(
      id: id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      favoriteItemId: favoriteItemId ?? this.favoriteItemId,
      sortOrder: sortOrder ?? this.sortOrder,
      note: note,
      addedAt: addedAt,
    );
  }
}
