abstract class RemoteConfigRepository {
  Future<void> initialize();
  Future<void> fetchAndActivate();
  T getValue<T>(String key, T defaultValue);
  bool getBool(String key, bool defaultValue);
  int getInt(String key, int defaultValue);
  double getDouble(String key, double defaultValue);
  String getString(String key, String defaultValue);
}
