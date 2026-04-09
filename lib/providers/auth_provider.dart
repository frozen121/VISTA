import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';
import '../core/utils/hash_util.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _userRepo;

  UserModel? _currentUser;
  String? _error;
  bool _loading = false;

  AuthProvider(this._userRepo) {
    _ensureAdminExists();
  }

  UserModel? get currentUser => _currentUser;
  String? get error => _error;
  bool get loading => _loading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<void> _ensureAdminExists() async {
    final existingAdmin = _userRepo.getByEmail('admin@hotel.com');
    if (existingAdmin == null) {
      await _userRepo.create(
        email: 'admin@hotel.com',
        passwordHash: HashUtil.hashPassword('admin123'),
        name: 'Admin',
        phone: '+7 (999) 999-99-99',
        role: 'admin',
      );
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    await Future.delayed(const Duration(milliseconds: 300)); // UX delay

    final user = _userRepo.getByEmail(email.trim());
    if (user == null) {
      _error = 'Пользователь не найден';
      _setLoading(false);
      return false;
    }

    if (user.isBlocked) {
      _error = 'Ваш аккаунт заблокирован';
      _setLoading(false);
      return false;
    }

    if (!HashUtil.verifyPassword(password, user.passwordHash)) {
      _error = 'Неверный пароль';
      _setLoading(false);
      return false;
    }

    _currentUser = user;
    _setLoading(false);
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _setLoading(true);
    _error = null;
    await Future.delayed(const Duration(milliseconds: 300));

    if (_userRepo.emailExists(email.trim())) {
      _error = 'Email уже зарегистрирован';
      _setLoading(false);
      return false;
    }

    if (password.length < 6) {
      _error = 'Password must be at least 6 characters';
      _setLoading(false);
      return false;
    }

    final user = await _userRepo.create(
      email: email.trim(),
      passwordHash: HashUtil.hashPassword(password),
      name: name.trim(),
      phone: phone?.trim(),
    );
    _currentUser = user;
    _setLoading(false);
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser != null) {
      final refreshed = _userRepo.getById(_currentUser!.id);
      // If user is blocked, logout automatically
      if (refreshed != null && refreshed.isBlocked) {
        logout();
        _error = 'Ваш аккаунт заблокирован';
      } else {
        _currentUser = refreshed;
        notifyListeners();
      }
    }
  }

  Future<bool> updateProfile({String? name, String? phone, String? photoPath, String? email}) async {
    if (_currentUser == null) return false;
    _error = null;

    final currentEmail = _currentUser!.email;
    final newEmail = email?.trim();
    if (newEmail != null && newEmail.isNotEmpty && newEmail.toLowerCase() != currentEmail.toLowerCase()) {
      if (_userRepo.emailExists(newEmail)) {
        _error = 'Email уже зарегистрирован';
        return false;
      }
    }

    final updated = _currentUser!.copyWith(
      name: name,
      phone: phone,
      photoPath: photoPath,
      email: newEmail?.isNotEmpty == true ? newEmail : null,
    );
    await _userRepo.save(updated);
    _currentUser = updated;
    notifyListeners();
    return true;
  }
}
