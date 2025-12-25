class CategoryModel {
  final String id;
  final String name;
  final String type; // "Income" atau "Expense"
  final String? userId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.userId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
      userId: json['user_id'],
    );
  }
}
