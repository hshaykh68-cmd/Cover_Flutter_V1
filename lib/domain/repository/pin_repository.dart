import 'package:cover/domain/model/pin.dart';

abstract class PinRepository {
  Future<void> setPrimaryPin(String pin);
  Future<void> setDecoyPin(String pin);
  Future<String?> getPrimaryPin();
  Future<String?> getDecoyPin();
  Future<bool> validatePin(String pin);
  Future<bool> isDecoyPin(String pin);
  Future<void> clearPins();
}
