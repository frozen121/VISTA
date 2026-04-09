import '../database/hive_service.dart';
import '../models/room_model.dart';

class RoomRepository {
  List<RoomModel> getAll() {
    return HiveService.rooms.values
        .map((e) => RoomModel.fromMap(e as Map))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<RoomModel> getAvailable() {
    return getAll().where((r) => r.isAvailable).toList();
  }

  List<RoomModel> getByCategory(String category) {
    return getAll().where((r) => r.category == category).toList();
  }

  RoomModel? getById(int id) {
    final data = HiveService.rooms.get(id);
    return data != null ? RoomModel.fromMap(data as Map) : null;
  }

  Future<RoomModel> create({
    required String name,
    required String category,
    required double price,
    required String description,
    List<String> imagePaths = const [],
    List<String> amenities = const [],
    int capacity = 2,
  }) async {
    final room = RoomModel(
      id: HiveService.nextRoomId(),
      name: name,
      category: category,
      price: price,
      description: description,
      imagePaths: imagePaths,
      amenities: amenities,
      capacity: capacity,
      isAvailable: true,
      createdAt: DateTime.now(),
    );
    await HiveService.rooms.put(room.id, room.toMap());
    return room;
  }

  Future<void> update(RoomModel room) async {
    await HiveService.rooms.put(room.id, room.toMap());
  }

  Future<void> delete(int id) async {
    await HiveService.rooms.delete(id);
  }

  Future<void> toggleAvailability(int id) async {
    final room = getById(id);
    if (room != null) {
      await update(room.copyWith(isAvailable: !room.isAvailable));
    }
  }

  List<RoomModel> search(String query) {
    final q = query.toLowerCase();
    return getAll().where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
    }).toList();
  }

  Map<int, int> getBookingCounts(List<dynamic> bookings) {
    final counts = <int, int>{};
    for (final b in bookings) {
      counts[b.roomId] = (counts[b.roomId] ?? 0) + 1;
    }
    return counts;
  }
}
