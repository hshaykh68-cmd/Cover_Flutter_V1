import 'package:cover/data/local/database/daos/intruder_log_dao.dart';
import 'package:cover/data/local/database/tables.dart';
import 'package:cover/domain/repository/intruder_log_repository.dart';
import 'package:cover/core/utils/logger.dart';

class IntruderLogRepositoryImpl implements IntruderLogRepository {
  final IntruderLogDao _intruderLogDao;

  IntruderLogRepositoryImpl(this._intruderLogDao);

  @override
  Future<IntruderLog?> getIntruderLogById(int id) async {
    try {
      return await _intruderLogDao.getIntruderLogById(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get intruder log by id: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<IntruderLog>> getIntruderLogsByVault(String vaultId) async {
    try {
      return await _intruderLogDao.getIntruderLogsByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get intruder logs for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<IntruderLog>> getAllIntruderLogs() async {
    try {
      return await _intruderLogDao.getAllIntruderLogs();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get all intruder logs', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<IntruderLog>> getIntruderLogsByType(String eventType) async {
    try {
      return await _intruderLogDao.getIntruderLogsByType(eventType);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get intruder logs by type', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<IntruderLog>> getIntruderLogsByDateRange(DateTime startDate, DateTime endDate, {String? vaultId}) async {
    try {
      final logs = await _intruderLogDao.getIntruderLogsByDateRange(startDate, endDate);
      if (vaultId != null) {
        return logs.where((log) => log.vaultId == vaultId).toList();
      }
      return logs;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get intruder logs by date range', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<IntruderLog>> getRecentIntruderLogs(int days) async {
    try {
      return await _intruderLogDao.getRecentIntruderLogs(days);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get recent intruder logs', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<IntruderLog> createIntruderLog(IntruderLogsCompanion log) async {
    try {
      return await _intruderLogDao.createIntruderLog(log);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create intruder log', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateIntruderLog(
    int id, {
    Value<String?>? encryptedPhotoPath,
    Value<String?>? encryptedLocation,
    Value<String?>? metadata,
  }) async {
    try {
      await _intruderLogDao.updateIntruderLog(
        id,
        encryptedPhotoPath: encryptedPhotoPath,
        encryptedLocation: encryptedLocation,
        metadata: metadata,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update intruder log: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteIntruderLog(int id) async {
    try {
      return await _intruderLogDao.deleteIntruderLog(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete intruder log: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteIntruderLogsByVault(String vaultId) async {
    try {
      return await _intruderLogDao.deleteIntruderLogsByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete intruder logs for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteOldIntruderLogs(int days) async {
    try {
      return await _intruderLogDao.deleteOldIntruderLogs(days);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete old intruder logs', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getIntruderLogCount() async {
    try {
      return await _intruderLogDao.getIntruderLogCount();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get intruder log count', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getIntruderLogCountByType(String eventType) async {
    try {
      return await _intruderLogDao.getIntruderLogCountByType(eventType);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get intruder log count by type', e, stackTrace);
      rethrow;
    }
  }
}
