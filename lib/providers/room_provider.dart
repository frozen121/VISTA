import 'package:flutter/foundation.dart';
import '../data/models/room_model.dart';
import '../data/repositories/room_repository.dart';
import '../data/repositories/booking_repository.dart';

class RoomProvider extends ChangeNotifier {
  final RoomRepository _repo;
  final BookingRepository _bookingRepo;

  List<RoomModel> _rooms = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _availableOnly = false;
  double? _minPrice;
  double? _maxPrice;
  List<String> _selectedAmenities = [];
  int? _guestCount;
  DateTime? _checkIn;
  DateTime? _checkOut;
  bool _loading = false;

  static const Map<String, String> _amenityTranslations = {
    'Air Conditioning': 'Кондиционер',
    'King Bed': 'Кровать King Size',
    'Queen Bed': 'Кровать Queen Size',
    'Balcony': 'Балкон',
    'Butler': 'Дворецкий',
    'Butler Service': 'Обслуживание дворецким',
    'Chef Service': 'Обслуживание шеф-поваром',
    'City View': 'Вид на город',
    'Garden View': 'Вид на сад',
    'Home Cinema': 'Домашний кинотеатр',
    'Jacuzzi': 'Джакузи',
    'Kids Amenities': 'Детские удобства',
    'Living Area': 'Гостиная',
    'Master Bedroom': 'Главная спальня',
    '2 Bedrooms': '2 спальни',
    'Private Terrace': 'Частная терраса',
    'Outdoor Shower': 'Уличный душ',
    'Pool': 'Бассейн',
    'Parking': 'Парковка',
    'Mini-Bar': 'Мини-бар',
    'Mini bar': 'Мини-бар',
  };

  RoomProvider(this._repo, this._bookingRepo) {
    load();
  }

  List<RoomModel> get allRooms => _rooms;
  String get selectedCategory => _selectedCategory;
  bool get loading => _loading;

  List<RoomModel> get filteredRooms {
    var list = _rooms;
    if (_selectedCategory != 'all') {
      list = list.where((r) => r.category == _selectedCategory).toList();
    }
    if (_availableOnly) {
      list = list.where((r) => r.isAvailable).toList();
    }
    if (_minPrice != null) {
      list = list.where((r) => r.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      list = list.where((r) => r.price <= _maxPrice!).toList();
    }
    if (_selectedAmenities.isNotEmpty) {
      list = list.where((r) => _selectedAmenities.every((a) => r.amenities.contains(a))).toList();
    }
      if (_checkIn != null && _checkOut != null) {
      list = list.where((r) => _bookingRepo.isRoomAvailable(r.id, _checkIn!, _checkOut!)).toList();
    }
    if (_guestCount != null) {
      list = list.where((r) => r.capacity >= _guestCount!).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((r) =>
              r.name.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<RoomModel> get availableRooms =>
      _rooms.where((r) => r.isAvailable).toList();

  bool get availableOnly => _availableOnly;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  List<String> get selectedAmenities => _selectedAmenities;
  int? get guestCount => _guestCount;
  DateTime? get checkIn => _checkIn;
  DateTime? get checkOut => _checkOut;

  // Get all unique amenities from rooms
  List<String> get allAmenities {
    final Set<String> amenities = {};
    for (final room in _rooms) {
      amenities.addAll(room.amenities);
    }
    return amenities.toList()..sort();
  }

  void load() {
    _rooms = _repo.getAll().map((room) {
      final translatedAmenities = room.amenities
          .map((amenity) => _amenityTranslations[amenity] ?? amenity)
          .toList();
      return room.copyWith(amenities: translatedAmenities);
    }).toList();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setAvailableOnly(bool value) {
    _availableOnly = value;
    notifyListeners();
  }

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
  }

  void setSelectedAmenities(List<String> amenities) {
    _selectedAmenities = amenities;
    notifyListeners();
  }

  void setDateRange(DateTime? checkIn, DateTime? checkOut) {
    _checkIn = checkIn;
    _checkOut = checkOut;
    notifyListeners();
  }

  void setGuestCount(int? guests) {
    _guestCount = guests;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<RoomModel> createRoom({
    required String name,
    required String category,
    required double price,
    required String description,
    List<String> imagePaths = const [],
    List<String> amenities = const [],
    int capacity = 2,
  }) async {
    final room = await _repo.create(
      name: name,
      category: category,
      price: price,
      description: description,
      imagePaths: imagePaths,
      amenities: amenities,
      capacity: capacity,
    );
    load();
    return room;
  }

  Future<void> updateRoom(RoomModel room) async {
    await _repo.update(room);
    load();
  }

  Future<void> deleteRoom(int id) async {
    await _repo.delete(id);
    load();
  }

  Future<void> toggleAvailability(int id) async {
    await _repo.toggleAvailability(id);
    load();
  }

  RoomModel? getById(int id) => _repo.getById(id);
}
