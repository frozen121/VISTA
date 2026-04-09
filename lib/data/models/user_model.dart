class UserModel {
  int id;
  String email;
  String passwordHash;
  String name;
  String? phone;
  String? photoPath;
  String role; // 'user' | 'admin'
  int loyaltyPoints;
  bool isBlocked;
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    this.phone,
    this.photoPath,
    this.role = 'user',
    this.loyaltyPoints = 0,
    this.isBlocked = false,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? email,
    String? passwordHash,
    String? name,
    String? phone,
    String? photoPath,
    String? role,
    int? loyaltyPoints,
    bool? isBlocked,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoPath: photoPath ?? this.photoPath,
      role: role ?? this.role,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'passwordHash': passwordHash,
    'name': name,
    'phone': phone,
    'photoPath': photoPath,
    'role': role,
    'loyaltyPoints': loyaltyPoints,
    'isBlocked': isBlocked,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory UserModel.fromMap(Map<dynamic, dynamic> map) => UserModel(
    id: map['id'] as int,
    email: map['email'] as String,
    passwordHash: map['passwordHash'] as String,
    name: map['name'] as String,
    phone: map['phone'] as String?,
    photoPath: map['photoPath'] as String?,
    role: map['role'] as String? ?? 'user',
    loyaltyPoints: map['loyaltyPoints'] as int? ?? 0,
    isBlocked: map['isBlocked'] as bool? ?? false,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
  );
}
