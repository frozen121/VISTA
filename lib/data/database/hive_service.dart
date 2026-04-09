import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';
import '../models/loyalty_transaction_model.dart';
import '../../core/utils/hash_util.dart';

class HiveService {
  static const String _usersBox = 'users';
  static const String _roomsBox = 'rooms';
  static const String _bookingsBox = 'bookings';
  static const String _loyaltyBox = 'loyalty_transactions';
  static const String _settingsBox = 'settings';

  static Box? _users;
  static Box? _rooms;
  static Box? _bookings;
  static Box? _loyalty;
  static Box? _settings;

  static Box get users => _users!;
  static Box get rooms => _rooms!;
  static Box get bookings => _bookings!;
  static Box get loyalty => _loyalty!;
  static Box get settings => _settings!;

  static Future<void> init() async {
    await Hive.initFlutter();
    _users = await Hive.openBox(_usersBox);
    _rooms = await Hive.openBox(_roomsBox);
    _bookings = await Hive.openBox(_bookingsBox);
    _loyalty = await Hive.openBox(_loyaltyBox);
    _settings = await Hive.openBox(_settingsBox);
    await _seedInitialData();
    await _translateExistingRoomData();
  }

  static Future<void> _translateExistingRoomData() async {
    final roomNameTranslations = {
      'Deluxe Ocean View': 'Делюкс с видом на океан',
      'Executive Suite': 'Люкс для руководителей',
      'Standard Comfort': 'Стандартный комфорт',
      'Presidential Suite': 'Президентский люкс',
      'Garden Villa': 'Вилла в саду',
      'Family Room': 'Семейный номер',
      'Standard Room': 'Стандартный номер',
    };

    final amenityTranslations = {
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
      'WiFi': 'WiFi',
    };

    for (final key in rooms.keys.cast<int>()) {
      final data = rooms.get(key);
      if (data is Map) {
        final roomMap = Map<String, dynamic>.from(data);
        var changed = false;

        if (roomMap['name'] is String) {
          final name = roomMap['name'] as String;
          if (roomNameTranslations.containsKey(name)) {
            roomMap['name'] = roomNameTranslations[name]!;
            changed = true;
          }
        }

        if (roomMap['amenities'] is List) {
          final originalAmenities = List.from(roomMap['amenities'] as List);
          final translatedAmenities = originalAmenities.map((amenity) {
            if (amenity is String && amenityTranslations.containsKey(amenity)) {
              return amenityTranslations[amenity]!;
            }
            return amenity;
          }).toList();

          if (translatedAmenities.length == originalAmenities.length) {
            for (var i = 0; i < originalAmenities.length; i++) {
              if (translatedAmenities[i] != originalAmenities[i]) {
                changed = true;
                break;
              }
            }
          }

          if (changed) {
            roomMap['amenities'] = translatedAmenities;
          }
        }

        if (changed) {
          await rooms.put(key, roomMap);
        }
      }
    }
  }

  static Future<void> _seedInitialData() async {
    final isSeeded = settings.get('seeded', defaultValue: false) as bool;
    if (isSeeded) return;

    // Create sample user
    final userId = _nextId('user');
    final user = UserModel(
      id: userId,
      email: 'user@hotel.com',
      passwordHash: HashUtil.hashPassword('user123'),
      name: 'John Smith',
      phone: '+7 (999) 123-45-67',
      role: 'user',
      loyaltyPoints: 250,
      createdAt: DateTime.now(),
    );
    await users.put(userId, user.toMap());

    // Create admin user
    final adminId = _nextId('user');
    final admin = UserModel(
      id: adminId,
      email: 'admin@hotel.com',
      passwordHash: HashUtil.hashPassword('admin123'),
      name: 'Admin',
      phone: '+7 (999) 999-99-99',
      role: 'admin',
      loyaltyPoints: 0,
      createdAt: DateTime.now(),
    );
    await users.put(adminId, admin.toMap());

    // Create sample rooms
    final sampleRooms = [
      RoomModel(
        id: _nextId('room'),
        name: 'Делюкс с видом на океан',
        category: 'deluxe',
        price: 250.0,
        description:
            'Просторный номер делюкс с захватывающим панорамным видом на океан. Включает кровать king-size, мраморную ванную комнату с дождевым душем и частный балкон.',
        amenities: ['Кровать King Size', 'Вид на океан', 'Балкон', 'Мини-бар', 'WiFi', 'Кондиционер'],
        capacity: 2,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      RoomModel(
        id: _nextId('room'),
        name: 'Люкс для руководителей',
        category: 'suite',
        price: 450.0,
        description:
            'Роскошный люкс с отдельной гостиной, премиальными удобствами и потрясающим видом на город. Идеально для бизнес-путешественников и особых случаев.',
        amenities: ['Кровать King Size', 'Гостиная', 'Вид на город', 'Джакузи', 'WiFi', 'Обслуживание дворецким', 'Мини-бар'],
        capacity: 2,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      RoomModel(
        id: _nextId('room'),
        name: 'Стандартный комфорт',
        category: 'standard',
        price: 120.0,
        description:
            'Комфортный и элегантно обставленный стандартный номер со всеми необходимыми удобствами для приятного пребывания.',
        amenities: ['Кровать Queen Size', 'WiFi', 'Кондиционер', 'Телевизор', 'Сейф'],
        capacity: 2,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      RoomModel(
        id: _nextId('room'),
        name: 'Президентский люкс',
        category: 'presidential',
        price: 1200.0,
        description:
            'Вершина роскоши — двухэтажный президентский люкс с частным бассейном, обслуживанием личного шеф-повара и панорамным видом на 360°.',
        amenities: ['Главная спальня', 'Частный бассейн', 'Обслуживание шеф-поваром', 'Дворецкий', 'Панорамный вид', 'Домашний кинотеатр'],
        capacity: 4,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      RoomModel(
        id: _nextId('room'),
        name: 'Вилла в саду',
        category: 'suite',
        price: 380.0,
        description:
            'Спокойная частная вилла, окруженная пышными садами. Включает частную террасу, уличный душ и прямой доступ к саду.',
        amenities: ['Кровать King Size', 'Вид на сад', 'Частная терраса', 'Уличный душ', 'WiFi'],
        capacity: 2,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      RoomModel(
        id: _nextId('room'),
        name: 'Семейный номер',
        category: 'deluxe',
        price: 320.0,
        description:
            'Просторный семейный номер с двумя спальнями, уютной гостиной и всем необходимым для незабываемого семейного отдыха.',
        amenities: ['2 спальни', 'Гостиная', 'WiFi', 'Кондиционер', 'Детские удобства'],
        capacity: 4,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
    ];

    for (final room in sampleRooms) {
      await rooms.put(room.id, room.toMap());
    }

    // Пример бронирования для демо-пользователя
    final bookingId = _nextId('booking');
    final checkIn = DateTime.now().subtract(const Duration(days: 5));
    final checkOut = checkIn.add(const Duration(days: 2));
    final booking = BookingModel(
      id: bookingId,
      userId: userId,
      roomId: sampleRooms[0].id,
      roomName: sampleRooms[0].name,
      roomCategory: sampleRooms[0].category,
      checkIn: checkIn,
      checkOut: checkOut,
      status: 'completed',
      totalPrice: 500.0,
      pointsEarned: 50,
      createdAt: checkIn,
    );
    await bookings.put(bookingId, booking.toMap());

    // Пример транзакции лояльности
    final loyaltyId = _nextId('loyalty');
    final tx = LoyaltyTransactionModel(
      id: loyaltyId,
      userId: userId,
      points: 250,
      type: 'earn',
      description: 'Бонус за приветствие',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    );
    await loyalty.put(loyaltyId, tx.toMap());

    await settings.put('seeded', true);
  }

  static int _nextId(String entity) {
    final key = '${entity}_counter';
    final current = settings.get(key, defaultValue: 0) as int;
    final next = current + 1;
    settings.put(key, next);
    return next;
  }

  static int nextUserId() => _nextId('user');
  static int nextRoomId() => _nextId('room');
  static int nextBookingId() => _nextId('booking');
  static int nextLoyaltyId() => _nextId('loyalty');
}
