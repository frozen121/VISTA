class BookingModel {
  int id;
  int userId;
  int roomId;
  String roomName;
  String roomCategory;
  DateTime checkIn;
  DateTime checkOut;
  String status; // 'pending' | 'confirmed' | 'cancelled' | 'completed'
  double totalPrice;
  int pointsEarned;
  String? paymentMethod; // 'card' | 'cash'
  String? notes;
  DateTime createdAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.roomName,
    required this.roomCategory,
    required this.checkIn,
    required this.checkOut,
    this.status = 'pending',
    required this.totalPrice,
    this.pointsEarned = 0,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  int get nights => checkOut.difference(checkIn).inDays;

  BookingModel copyWith({String? status, String? notes, int? pointsEarned, String? paymentMethod}) {
    return BookingModel(
      id: id,
      userId: userId,
      roomId: roomId,
      roomName: roomName,
      roomCategory: roomCategory,
      checkIn: checkIn,
      checkOut: checkOut,
      status: status ?? this.status,
      totalPrice: totalPrice,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'roomId': roomId,
    'roomName': roomName,
    'roomCategory': roomCategory,
    'checkIn': checkIn.millisecondsSinceEpoch,
    'checkOut': checkOut.millisecondsSinceEpoch,
    'status': status,
    'totalPrice': totalPrice,
    'pointsEarned': pointsEarned,
    'paymentMethod': paymentMethod,
    'notes': notes,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory BookingModel.fromMap(Map<dynamic, dynamic> map) => BookingModel(
    id: map['id'] as int,
    userId: map['userId'] as int,
    roomId: map['roomId'] as int,
    roomName: map['roomName'] as String,
    roomCategory: map['roomCategory'] as String,
    checkIn: DateTime.fromMillisecondsSinceEpoch(map['checkIn'] as int),
    checkOut: DateTime.fromMillisecondsSinceEpoch(map['checkOut'] as int),
    status: map['status'] as String? ?? 'pending',
    totalPrice: (map['totalPrice'] as num).toDouble(),
    pointsEarned: map['pointsEarned'] as int? ?? 0,
    paymentMethod: map['paymentMethod'] as String?,
    notes: map['notes'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
  );
}
