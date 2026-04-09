import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtil {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password + '_hotel_vista_salt');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}
