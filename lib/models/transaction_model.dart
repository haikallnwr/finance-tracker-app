class TransactionModel {
  final String id;
  final String type;
  final double amount;
  final String categoryName;
  final String accountName;
  final String description;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryName,
    required this.accountName,
    required this.description,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),

      categoryName: json['category_id'] != null
          ? json['category_id']['name']
          : 'Uncategorized',

      accountName: json['account_id'] != null
          ? json['account_id']['name']
          : 'Unknown Account',
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
    );
  }
}
