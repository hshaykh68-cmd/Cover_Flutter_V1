import 'package:cover/domain/repository/pin_repository.dart';

class ValidatePinUseCase {
  final PinRepository _pinRepository;

  ValidatePinUseCase(this._pinRepository);

  Future<bool> call(String pin) async {
    return await _pinRepository.validatePin(pin);
  }
}
