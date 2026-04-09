import 'package:flutter/foundation.dart';
import '../data/models/loyalty_transaction_model.dart';
import '../data/repositories/loyalty_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_model.dart';

class LoyaltyProvider extends ChangeNotifier {
  final LoyaltyRepository _repo;
  final UserRepository _userRepo;

  List<LoyaltyTransactionModel> _transactions = [];

  LoyaltyProvider(this._repo, this._userRepo) {
    load();
  }

  List<LoyaltyTransactionModel> get allTransactions => _transactions;

  void load() {
    _transactions = _repo.getAll();
    notifyListeners();
  }

  List<LoyaltyTransactionModel> getUserTransactions(int userId) =>
      _transactions.where((t) => t.userId == userId).toList();

  Future<void> adminAdjust({
    required int userId,
    required int points,
    required String description,
  }) async {
    await _repo.adminAdjust(
      userId: userId,
      points: points,
      description: description,
    );
    load();
  }

  int getUserBalance(int userId) => _repo.getUserBalance(userId);

  List<UserModel> getAllUsers() => _userRepo.getAll();

  UserModel? getUserById(int id) => _userRepo.getById(id);
}
