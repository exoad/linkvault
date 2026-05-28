import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/services/pin_service.dart';

void main() {
  test('validates 4 digit pin format', () {
    expect(PinService.isValidPinFormat('1234'), isTrue);
    expect(PinService.isValidPinFormat('123'), isFalse);
    expect(PinService.isValidPinFormat('12ab'), isFalse);
  });

  test('hash and verify pin', () {
    const pin = '5678';
    final salt = PinService.generateSalt();
    final hash = PinService.hashPin(pin, salt);
    expect(
      PinService.verifyPin(pin: pin, salt: salt, storedHash: hash),
      isTrue,
    );
    expect(
      PinService.verifyPin(pin: '0000', salt: salt, storedHash: hash),
      isFalse,
    );
  });
}
