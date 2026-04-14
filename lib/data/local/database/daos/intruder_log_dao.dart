import 'package:cover/data/local/database/app_database.dart';
import 'package:drift/drift.dart';

part 'intruder_log_dao.g.dart';

/// Data Access Object for Intruder Log operations
@DriftAccessor(tables: [IntruderLogs])
class IntruderLogDao extends DatabaseAccessor<AppDatabase> with _$IntruderLogDaoMixin {
  IntruderLogDao(AppDatabase db) : super(db);

  /// Get intruder log by ID
  Future<IntruderLog?> getIntruderLogById(int id) {
    return (select(intruderLogs)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get all intruder logs for a vault
  Future<List<IntruderLog>> getIntruderLogsByVault(String vaultId) {
    return (select(intruderLogs)..where((tbl) => tbl.vaultId.equals(vaultId))).get();
  }

  /// Get all intruder logs (for calculator attempts)
  Future<List<IntruderLog>> getAllIntruderLogs() {
    return select(intruderLogs).get();
  }

  /// Get intruder logs by event type
  Future<List<IntruderLog>> getIntruderLogsByType(String eventType) {
    return (select(intruderLogs)..where((tbl) => tbl.eventType.equals(eventType))).get();
  }

  /// Get intruder logs by date range
  Future<List<IntruderLog>> getIntruderLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(intruderLogs)
          ..where((tbl) =>
              tbl.timestamp.isBiggerOrEqualValue(startDate) &
              tbl.timestamp.isSmallerOrEqualValue(endDate)))
        .get();
  }

  /// Get recent intruder logs (last N days)
  Future<List<IntruderLog>> getRecentIntruderLogs(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return (select(intruderLogs)
          ..where((tbl) => tbl.timestamp.isBiggerThanValue(cutoffDate))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .get();
  }

  /// Create a new intruder log
  Future<IntruderLog> createIntruderLog(IntruderLogsCompanion log) async {
    return await into(intruderLogs).insert(log);
  }

  /// Update an intruder log
  Future<void> updateIntruderLog(
    int id, {
    Value<String?>? encryptedPhotoPath,
    Value<String?>? encryptedLocation,
    Value<String?>? metadata,
  }) async {
    await (update(intruderLogs)..where((tbl) => tbl.id.equals(id))).write(
      IntruderLogsCompanion(
        encryptedPhotoPath: encryptedPhotoPath ?? const Value.absent(),
        encryptedLocation: encryptedLocation ?? const Value.absent(),
        metadata: metadata ?? const Value.absent(),
      ),
    );
  }

  /// Delete an intruder log
  Future<int> deleteIntruderLog(int id) {
    return (delete(intruderLogs)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Delete intruder logs by vault
  Future<int> deleteIntruderLogsByVault(String vaultId) {
    return (delete(intruderLogs)..where((tbl) => tbl.vaultId.equals(vaultId))).go();
  }

  /// Delete intruder logs older than N days
  Future<int> deleteOldIntruderLogs(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return (delete(intruderLogs)..where((tbl) => tbl.timestamp.isSmallerThanValue(cutoffDate)))
        .go();
  }

  /// Get intruder log count
  Future<int> getIntruderLogCount() {
    return select(intruderLogs).get().then((list) => list.length);
  }

  /// Get intruder log count by event type
  Future<int> getIntruderLogCountByType(String eventType) {
    return (select(intruderLogs)..where((tbl) => tbl.eventType.equals(eventType)))
        .get()
        .then((list) => list.length);
  }
}
