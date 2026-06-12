class EscrowModel {
  final String id;
  final double amount;
  final String status;
  final DateTime createdAt;
  final String? sellerUsername;

  EscrowModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.sellerUsername,
  });

  factory EscrowModel.fromJson(Map<String, dynamic> json) {
    return EscrowModel(
      id: json['id'].toString(),
      amount: double.parse(json['amount'].toString()),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt']),
      sellerUsername: json['seller']?['username'],
    );
  }
}