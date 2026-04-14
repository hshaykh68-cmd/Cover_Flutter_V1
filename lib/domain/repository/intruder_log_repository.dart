import 'package:cover/data/local/database/tables.dart';

abstract class IntruderLogRepository {
  Future<IntruderLog?> getIntruderLogById(int id);
  Future<List<IntruderLog>> getIntruderLogsByVault(String vaultId);
  Future<List<IntruderLog>> getAllIntruderLogs();
  Future<List<IntruderLog>> getIntruderLogsByType(String eventType);
  Future<List<IntruderLog>> getIntruderLogsByDateRange(DateTime startDate, DateTime endDate, {String? vaultId});
  Future<List<IntruderLog>> getRecentIntruderLogs(int days);
  Future<IntruderLog> createIntruderLog(IntruderLogsCompanion log);
  Future<void> updateIntruderLog(int id, {Value<String?>? encryptedPhotoPath, Value<String?>? encryptedLocation, Value<String?>? metadata});
  Future<int> deleteIntruderLog(int id);
  Future<int> deleteIntruderLogsByVault(String vaultId);
  Future<int> deleteOldIntruderLogs(int days);
  Future<int> getIntruderLogCount();
  Future<int> getIntruderLogCountByType(String eventType);
}
