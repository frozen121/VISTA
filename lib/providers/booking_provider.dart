import 'package:flutter/foundation.dart';
import '../data/models/booking_model.dart';
import '../data/models/room_model.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/loyalty_repository.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repo;
  final LoyaltyRepository _loyaltyRepo;

  List<BookingModel> _bookings = [];
  String? _statusFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  BookingProvider(this._repo, this._loyaltyRepo) {
    load();
  }

  List<BookingModel> get allBookings => _bookings;

  List<BookingModel> get filteredBookings {
    var list = _bookings;
    if (_statusFilter != null) {
      list = list.where((b) => b.status == _statusFilter).toList();
    }
    if (_dateFrom != null) {
      list = list.where((b) => !b.checkIn.isBefore(_dateFrom!)).toList();
    }
    if (_dateTo != null) {
      list = list.where((b) => !b.checkIn.isAfter(_dateTo!)).toList();
    }
    return list;
  }

  String? get statusFilter => _statusFilter;

  void load() {
    _bookings = _repo.getAll();
    notifyListeners();
  }

  List<BookingModel> getUserBookings(int userId) =>
      _bookings.where((b) => b.userId == userId).toList();

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setDateFilter(DateTime? from, DateTime? to) {
    _dateFrom = from;
    _dateTo = to;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _dateFrom = null;
    _dateTo = null;
    notifyListeners();
  }

  bool isRoomAvailable(int roomId, DateTime checkIn, DateTime checkOut, {int? excludeId}) {
    return _repo.isRoomAvailable(roomId, checkIn, checkOut, excludeBookingId: excludeId);
  }

  Future<BookingModel> createBooking({
    required int userId,
    required RoomModel room,
    required DateTime checkIn,
    required DateTime checkOut,
    String? paymentMethod,
    String? notes,
  }) async {
    final booking = await _repo.create(
      userId: userId,
      room: room,
      checkIn: checkIn,
      checkOut: checkOut,
      paymentMethod: paymentMethod,
      notes: notes,
    );

    // Award loyalty points
    if (booking.pointsEarned > 0) {
      await _loyaltyRepo.earnPoints(
        userId: userId,
        points: booking.pointsEarned,
        description: 'Бронирование: ${room.name}',
        bookingId: booking.id,
      );
    }

    load();
    return booking;
  }

  Future<void> updateStatus(int bookingId, String status) async {
    await _repo.updateStatus(bookingId, status);
    load();
  }

  Future<void> cancelBooking(int bookingId, int userId) async {
    final booking = _repo.getById(bookingId);
    if (booking != null && booking.userId == userId) {
      // Deduct loyalty points if earned (before status change)
      if (booking.pointsEarned > 0 && booking.status != 'cancelled') {
        try {
          await _loyaltyRepo.spendPoints(
            userId: userId,
            points: booking.pointsEarned,
            description: 'Возврат баллов лояльности при отмене бронирования: ${booking.roomName}',
            bookingId: bookingId,
          );
        } catch (_) {
          // Points may have been spent already, ignore
        }
      }
      
      // Now update status to cancelled
      await _repo.updateStatus(bookingId, 'cancelled');
      load();
    }
  }

  double get totalRevenue => _repo.getTotalRevenue();

  Map<String, int> getStatusCounts() {
    final counts = <String, int>{};
    for (final b in _bookings) {
      counts[b.status] = (counts[b.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Popular rooms by booking count
  List<MapEntry<int, int>> getPopularRoomIds({int limit = 5}) {
    final counts = <int, int>{};
    for (final b in _bookings) {
      if (b.status != 'cancelled') {
        counts[b.roomId] = (counts[b.roomId] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }
}
