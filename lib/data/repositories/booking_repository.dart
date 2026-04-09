import '../database/hive_service.dart';
import '../models/booking_model.dart';
import '../models/room_model.dart';
import '../../core/utils/date_util.dart';

class BookingRepository {
  List<BookingModel> getAll() {
    return HiveService.bookings.values
        .map((e) => BookingModel.fromMap(e as Map))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<BookingModel> getByUser(int userId) {
    return getAll().where((b) => b.userId == userId).toList();
  }

  List<BookingModel> getByStatus(String status) {
    return getAll().where((b) => b.status == status).toList();
  }

  List<BookingModel> getByRoom(int roomId) {
    return getAll().where((b) => b.roomId == roomId).toList();
  }

  BookingModel? getById(int id) {
    final data = HiveService.bookings.get(id);
    return data != null ? BookingModel.fromMap(data as Map) : null;
  }

  /// Check if a room is available for the given date range
  bool isRoomAvailable(int roomId, DateTime checkIn, DateTime checkOut, {int? excludeBookingId}) {
    final existing = getByRoom(roomId).where((b) {
      if (b.status == 'cancelled') return false;
      if (excludeBookingId != null && b.id == excludeBookingId) return false;
      return true;
    });

    for (final b in existing) {
      if (DateUtil.isOverlapping(checkIn, checkOut, b.checkIn, b.checkOut)) {
        return false;
      }
    }
    return true;
  }

  Future<BookingModel> create({
    required int userId,
    required RoomModel room,
    required DateTime checkIn,
    required DateTime checkOut,
    String? paymentMethod,
    String? notes,
  }) async {
    if (!isRoomAvailable(room.id, checkIn, checkOut)) {
      throw Exception('Номер недоступен на выбранные даты');
    }

    final nights = DateUtil.nightsBetween(checkIn, checkOut);
    final totalPrice = room.price * nights;
    final pointsEarned = (totalPrice / 10).round(); // 1 point per $10

    final booking = BookingModel(
      id: HiveService.nextBookingId(),
      userId: userId,
      roomId: room.id,
      roomName: room.name,
      roomCategory: room.category,
      checkIn: checkIn,
      checkOut: checkOut,
      status: 'pending',
      totalPrice: totalPrice,
      pointsEarned: pointsEarned,
      paymentMethod: paymentMethod,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await HiveService.bookings.put(booking.id, booking.toMap());
    return booking;
  }

  Future<void> updateStatus(int bookingId, String status) async {
    final booking = getById(bookingId);
    if (booking != null) {
      await HiveService.bookings.put(
        bookingId,
        booking.copyWith(status: status).toMap(),
      );
    }
  }

  Future<void> delete(int id) async {
    await HiveService.bookings.delete(id);
  }

  double getTotalRevenue() {
    return getAll()
        .where((b) => b.status != 'cancelled')
        .fold(0.0, (sum, b) => sum + b.totalPrice);
  }

  List<BookingModel> filterByDate(DateTime? from, DateTime? to) {
    return getAll().where((b) {
      if (from != null && b.checkIn.isBefore(from)) return false;
      if (to != null && b.checkIn.isAfter(to)) return false;
      return true;
    }).toList();
  }
}
