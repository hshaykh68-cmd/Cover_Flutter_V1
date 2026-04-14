import '../repository/intruder_log_repository.dart';
import '../model/intruder_log.dart';

/// Use case for logging intruder detection events
class LogIntruderEventUseCase {
  final IntruderLogRepository _repository;

  LogIntruderEventUseCase(this._repository);

  Future<void> call(IntruderLog log) {
    return _repository.addLog(log);
  }
}

/// Use case for retrieving all intruder logs
class GetIntruderLogsUseCase {
  final IntruderLogRepository _repository;

  GetIntruderLogsUseCase(this._repository);

  Future<List<IntruderLog>> call(String vaultId) {
    return _repository.getLogs(vaultId);
  }
}

/// Use case for retrieving intruder logs within a date range
class GetIntruderLogsByDateRangeUseCase {
  final IntruderLogRepository _repository;

  GetIntruderLogsByDateRangeUseCase(this._repository);

  Future<List<IntruderLog>> call(String vaultId, DateTime start, DateTime end) {
    return _repository.getLogsByDateRange(vaultId, start, end);
  }
}

/// Use case for deleting intruder logs
class DeleteIntruderLogUseCase {
  final IntruderLogRepository _repository;

  DeleteIntruderLogUseCase(this._repository);

  Future<void> call(int id) {
    return _repository.deleteLog(id);
  }
}

/// Use case for clearing all intruder logs
class ClearIntruderLogsUseCase {
  final IntruderLogRepository _repository;

  ClearIntruderLogsUseCase(this._repository);

  Future<void> call(String vaultId) {
    return _repository.clearLogs(vaultId);
  }
}
