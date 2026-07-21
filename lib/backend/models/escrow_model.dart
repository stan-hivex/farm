class EscrowModel {
  final String id;
  final double amount;
  final String status;
  final DateTime createdAt;
  final String? buyerId;
  final String? buyerUsername;
  final String? buyerName;
  final String? sellerId;
  final String? sellerUsername;
  final String? sellerName;

  EscrowModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.buyerId,
    this.buyerUsername,
    this.buyerName,
    this.sellerId,
    this.sellerUsername,
    this.sellerName,
  });

  bool isBuyer(String userId) => buyerId != null && buyerId == userId;
  bool isSeller(String userId) => sellerId != null && sellerId == userId;

  String getRoleForUser(String userId) {
    if (isBuyer(userId)) return 'Buyer';
    if (isSeller(userId)) return 'Seller';
    return 'Buyer';
  }

  String getCounterpartyDisplayName(String userId) {
    if (isBuyer(userId)) {
      final displayName = sellerUsername?.trim().replaceFirst(RegExp(r'^@'), '');
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
      return sellerName ?? 'Seller';
    }

    final displayName = buyerUsername?.trim().replaceFirst(RegExp(r'^@'), '');
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return buyerName ?? 'Buyer';
  }

  factory EscrowModel.fromJson(Map<String, dynamic> json) {
    final buyerData = (json['buyer'] is Map ? json['buyer'] as Map : null) ??
        (json['users_escrow_contracts_buyer_idTousers'] is Map
            ? json['users_escrow_contracts_buyer_idTousers'] as Map
            : null);
    final sellerData = (json['seller'] is Map ? json['seller'] as Map : null) ??
        (json['users_escrow_contracts_seller_idTousers'] is Map
            ? json['users_escrow_contracts_seller_idTousers'] as Map
            : null);

    final buyerId = buyerData?['id']?.toString() ?? json['buyer_id']?.toString();
    final sellerId = sellerData?['id']?.toString() ?? json['seller_id']?.toString();

    final buyerFirstName = buyerData?['first_name']?.toString();
    final buyerLastName = buyerData?['last_name']?.toString();
    final buyerFullName = buyerData?['name']?.toString() ??
        buyerData?['full_name']?.toString() ??
        buyerData?['display_name']?.toString() ??
        json['buyer_name']?.toString() ??
        json['buyer_full_name']?.toString();
    final buyerUsername = buyerData?['username']?.toString() ??
        buyerData?['user_name']?.toString() ??
        json['buyer_username']?.toString();

    final sellerFirstName = sellerData?['first_name']?.toString();
    final sellerLastName = sellerData?['last_name']?.toString();
    final sellerFullName = sellerData?['name']?.toString() ??
        sellerData?['full_name']?.toString() ??
        sellerData?['display_name']?.toString() ??
        json['seller_name']?.toString() ??
        json['seller_full_name']?.toString();
    final sellerUsername = sellerData?['username']?.toString() ??
        sellerData?['user_name']?.toString() ??
        json['seller_username']?.toString();

    final derivedBuyerName = (buyerFullName?.trim().isNotEmpty == true)
        ? buyerFullName!.trim()
        : ((buyerFirstName?.trim().isNotEmpty == true || buyerLastName?.trim().isNotEmpty == true)
            ? '${buyerFirstName ?? ''} ${buyerLastName ?? ''}'.trim()
            : null);
    final derivedSellerName = (sellerFullName?.trim().isNotEmpty == true)
        ? sellerFullName!.trim()
        : ((sellerFirstName?.trim().isNotEmpty == true || sellerLastName?.trim().isNotEmpty == true)
            ? '${sellerFirstName ?? ''} ${sellerLastName ?? ''}'.trim()
            : null);

    return EscrowModel(
      id: json['id'].toString(),
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      buyerId: buyerId,
      buyerUsername: buyerUsername,
      buyerName: derivedBuyerName,
      sellerId: sellerId,
      sellerUsername: sellerUsername,
      sellerName: derivedSellerName,
    );
  }
}