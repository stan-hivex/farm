class EscrowMessageModel {
  final String id;
  final String escrowId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  EscrowMessageModel({
    required this.id,
    required this.escrowId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory EscrowMessageModel.fromJson(Map<String, dynamic> json) {
    return EscrowMessageModel(
      id: json['id'],
      escrowId: json['escrow_id'],
      senderId: json['sender_id'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}