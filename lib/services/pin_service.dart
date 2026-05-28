import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PinService {
  static const pinLength = 4;

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  static bool isValidPinFormat(String pin) {
    return RegExp(r'^\d{4}$').hasMatch(pin);
  }

  static bool verifyPin({
    required String pin,
    required String salt,
    required String storedHash,
  }) {
    if (!isValidPinFormat(pin)) return false;
    return hashPin(pin, salt) == storedHash;
  }
}
