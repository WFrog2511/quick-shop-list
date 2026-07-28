// カテゴリモデル
// 将来の「お気に入り階層化」に対応するため、最初から自己参照構造(parentCategoryId)を持つ。
// MVPでは「未分類」の1件のみ使用するが、将来的に食料品>野菜のような階層を追加しやすい。
class ShoppingCategory {
  final String id;
  String name;
  String? parentCategoryId; // 親カテゴリID。nullなら最上位(またはカテゴリなし)
  int sortOrder;

  ShoppingCategory({
    required this.id,
    required this.name,
    this.parentCategoryId,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentCategoryId': parentCategoryId,
      'sortOrder': sortOrder,
    };
  }

  factory ShoppingCategory.fromMap(Map<dynamic, dynamic> map) {
    return ShoppingCategory(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      parentCategoryId: map['parentCategoryId'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  ShoppingCategory copyWith({
    String? name,
    String? parentCategoryId,
    int? sortOrder,
  }) {
    return ShoppingCategory(
      id: id,
      name: name ?? this.name,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// デフォルトの「未分類」カテゴリID
const String uncategorizedCategoryId = 'uncategorized';
