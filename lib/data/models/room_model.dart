class RoomModel {
  int id;
  String name;
  String category; // 'standard' | 'deluxe' | 'suite' | 'presidential'
  double price; // per night
  String description;
  List<String> imagePaths;
  List<String> amenities;
  int capacity;
  bool isAvailable;
  DateTime createdAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.imagePaths = const [],
    this.amenities = const [],
    this.capacity = 2,
    this.isAvailable = true,
    required this.createdAt,
  });

  RoomModel copyWith({
    String? name,
    String? category,
    double? price,
    String? description,
    List<String>? imagePaths,
    List<String>? amenities,
    int? capacity,
    bool? isAvailable,
  }) {
    return RoomModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
      amenities: amenities ?? this.amenities,
      capacity: capacity ?? this.capacity,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
    );
  }

  String get categoryLabel {
    switch (category) {
      case 'standard': return 'Standard';
      case 'deluxe': return 'Deluxe';
      case 'suite': return 'Suite';
      case 'presidential': return 'Presidential';
      default: return category;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'description': description,
    'imagePaths': imagePaths,
    'amenities': amenities,
    'capacity': capacity,
    'isAvailable': isAvailable,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory RoomModel.fromMap(Map<dynamic, dynamic> map) => RoomModel(
    id: map['id'] as int,
    name: map['name'] as String,
    category: map['category'] as String,
    price: (map['price'] as num).toDouble(),
    description: map['description'] as String,
    imagePaths: List<String>.from(map['imagePaths'] as List? ?? []),
    amenities: List<String>.from(map['amenities'] as List? ?? []),
    capacity: map['capacity'] as int? ?? 2,
    isAvailable: map['isAvailable'] as bool? ?? true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
  );
}
