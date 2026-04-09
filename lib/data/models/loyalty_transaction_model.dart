class LoyaltyTransactionModel {
  int id;
  int userId;
  int points; // positive = earned, negative = spent
  String type; // 'earn' | 'spend' | 'manual_add' | 'manual_deduct'
  String description;
  int? bookingId;
  DateTime createdAt;

  LoyaltyTransactionModel({
    required this.id,
    required this.userId,
    required this.points,
    required this.type,
    required this.description,
    this.bookingId,
    required this.createdAt,
  });

  bool get isPositive => points > 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'points': points,
    'type': type,
    'description': description,
    'bookingId': bookingId,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory LoyaltyTransactionModel.fromMap(Map<dynamic, dynamic> map) =>
      LoyaltyTransactionModel(
        id: map['id'] as int,
        userId: map['userId'] as int,
        points: map['points'] as int,
        type: map['type'] as String,
        description: map['description'] as String,
        bookingId: map['bookingId'] as int?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}
