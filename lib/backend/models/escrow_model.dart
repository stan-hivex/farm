class EscrowModel {
  final String id;
  final double amount;
  final String status;
  final DateTime createdAt;
  final String? sellerUsername;
  final String? sellerName;

  EscrowModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.sellerUsername,
    this.sellerName,
  });

  factory EscrowModel.fromJson(Map<String, dynamic> json) {
    final sellerData = (json['seller'] is Map ? json['seller'] as Map : null) ??
        (json['users_escrow_contracts_seller_idTousers'] is Map
            ? json['users_escrow_contracts_seller_idTousers'] as Map
            : null);
    final firstName = sellerData?['first_name']?.toString();
    final lastName = sellerData?['last_name']?.toString();
    final fullName = sellerData?['name']?.toString() ??
        sellerData?['full_name']?.toString() ??
        sellerData?['display_name']?.toString() ??
        json['seller_name']?.toString() ??
        json['seller_full_name']?.toString();
    final sellerUsername = sellerData?['username']?.toString() ??
        sellerData?['user_name']?.toString() ??
        json['seller_username']?.toString();

    final derivedSellerName = (fullName?.trim().isNotEmpty == true)
        ? fullName!.trim()
        : ((firstName?.trim().isNotEmpty == true || lastName?.trim().isNotEmpty == true)
            ? '${firstName ?? ''} ${lastName ?? ''}'.trim()
            : null);

    return EscrowModel(
      id: json['id'].toString(),
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      sellerUsername: sellerUsername,
      sellerName: derivedSellerName,
    );
  }
}