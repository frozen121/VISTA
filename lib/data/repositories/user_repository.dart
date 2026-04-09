import '../database/hive_service.dart';
import '../models/user_model.dart';

class UserRepository {
  List<UserModel> getAll() {
    return HiveService.users.values
        .map((e) => UserModel.fromMap(e as Map))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  UserModel? getById(int id) {
    final data = HiveService.users.get(id);
    return data != null ? UserModel.fromMap(data as Map) : null;
  }

  UserModel? getByEmail(String email) {
    final all = getAll();
    try {
      return all.firstWhere((u) => u.email.toLowerCase() == email.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<void> save(UserModel user) async {
    await HiveService.users.put(user.id, user.toMap());
  }

  Future<UserModel> create({
    required String email,
    required String passwordHash,
    required String name,
    String? phone,
    String role = 'user',
  }) async {
    final user = UserModel(
      id: HiveService.nextUserId(),
      email: email,
      passwordHash: passwordHash,
      name: name,
      phone: phone,
      role: role,
      loyaltyPoints: 0,
      createdAt: DateTime.now(),
    );
    await save(user);
    return user;
  }

  Future<void> updatePoints(int userId, int newPoints) async {
    final user = getById(userId);
    if (user != null) {
      await save(user.copyWith(loyaltyPoints: newPoints));
    }
  }

  Future<void> delete(int id) async {
    await HiveService.users.delete(id);
  }

  bool emailExists(String email) {
    return getByEmail(email) != null;
  }
}
