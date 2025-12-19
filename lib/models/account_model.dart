class AccountModel {
  final String id;
  final String name;
  final double currentBalance;
  final bool isDefault; // Tambahan field

  AccountModel({
    required this.id,
    required this.name,
    required this.currentBalance,
    required this.isDefault,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['_id'],
      name: json['name'],
      currentBalance: (json['current_balance'] as num).toDouble(),
      isDefault: json['isDefault'] ?? false, // Handle null safety
    );
  }
}
