import '../database/hive_service.dart';
import '../models/loyalty_transaction_model.dart';
import 'user_repository.dart';

class LoyaltyRepository {
  final UserRepository _userRepo;

  LoyaltyRepository(this._userRepo);

  List<LoyaltyTransactionModel> getAll() {
    return HiveService.loyalty.values
        .map((e) => LoyaltyTransactionModel.fromMap(e as Map))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<LoyaltyTransactionModel> getByUser(int userId) {
    return getAll().where((t) => t.userId == userId).toList();
  }

  Future<void> addTransaction({
    required int userId,
    required int points,
    required String type,
    required String description,
    int? bookingId,
  }) async {
    final tx = LoyaltyTransactionModel(
      id: HiveService.nextLoyaltyId(),
      userId: userId,
      points: points,
      type: type,
      description: description,
      bookingId: bookingId,
      createdAt: DateTime.now(),
    );
    await HiveService.loyalty.put(tx.id, tx.toMap());

    // Update user's balance
    final user = _userRepo.getById(userId);
    if (user != null) {
      final newBalance = (user.loyaltyPoints + points).clamp(0, 999999);
      await _userRepo.updatePoints(userId, newBalance);
    }
  }

  Future<void> earnPoints({
    required int userId,
    required int points,
    required String description,
    int? bookingId,
  }) async {
    await addTransaction(
      userId: userId,
      points: points,
      type: 'earn',
      description: description,
      bookingId: bookingId,
    );
  }

  Future<void> spendPoints({
    required int userId,
    required int points,
    required String description,
    int? bookingId,
  }) async {
    final user = _userRepo.getById(userId);
    if (user == null || user.loyaltyPoints < points) {
      throw Exception('Недостаточно баллов лояльности');
    }
    await addTransaction(
      userId: userId,
      points: -points,
      type: 'spend',
      description: description,
      bookingId: bookingId,
    );
  }

  Future<void> adminAdjust({
    required int userId,
    required int points,
    required String description,
  }) async {
    final type = points >= 0 ? 'manual_add' : 'manual_deduct';
    await addTransaction(
      userId: userId,
      points: points,
      type: type,
      description: description,
    );
  }

  int getUserBalance(int userId) {
    return _userRepo.getById(userId)?.loyaltyPoints ?? 0;
  }
}
