import 'package:cover/domain/repository/pin_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinRepositoryImpl implements PinRepository {
  final FlutterSecureStorage _secureStorage;

  PinRepositoryImpl(this._secureStorage);

  static const String _primaryPinKey = 'primary_pin';
  static const String _decoyPinKey = 'decoy_pin';

  @override
  Future<void> setPrimaryPin(String pin) async {
    await _secureStorage.write(key: _primaryPinKey, value: pin);
  }

  @override
  Future<void> setDecoyPin(String pin) async {
    await _secureStorage.write(key: _decoyPinKey, value: pin);
  }

  @override
  Future<String?> getPrimaryPin() async {
    return await _secureStorage.read(key: _primaryPinKey);
  }

  @override
  Future<String?> getDecoyPin() async {
    return await _secureStorage.read(key: _decoyPinKey);
  }

  @override
  Future<bool> validatePin(String pin) async {
    final primaryPin = await getPrimaryPin();
    final decoyPin = await getDecoyPin();
    return pin == primaryPin || pin == decoyPin;
  }

  @override
  Future<bool> isDecoyPin(String pin) async {
    final decoyPin = await getDecoyPin();
    return pin == decoyPin;
  }

  @override
  Future<void> clearPins() async {
    await _secureStorage.delete(key: _primaryPinKey);
    await _secureStorage.delete(key: _decoyPinKey);
  }
}
