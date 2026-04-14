import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/di/di_container.dart';
import 'package:cover/core/secure_storage/secure_key_storage.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _lockOnBackground = true;
  bool _denyScreenshots = true;
  bool _blurAppSwitcher = true;
  bool _intruderDetection = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final secureStorage = ref.read(secureKeyStorageProvider);
    final appConfig = ref.read(appConfigProvider);
    
    final lockOnBackground = await secureStorage.retrieveString('lock_on_background');
    final denyScreenshots = await secureStorage.retrieveString('deny_screenshots');
    final blurAppSwitcher = await secureStorage.retrieveString('blur_app_switcher');
    final intruderDetection = await secureStorage.retrieveString('intruder_detection');
    
    setState(() {
      _lockOnBackground = lockOnBackground == 'true' ? true : (lockOnBackground == null ? appConfig.lockOnBackground : false);
      _denyScreenshots = denyScreenshots == 'true' ? true : (denyScreenshots == null ? appConfig.denyScreenshots : false);
      _blurAppSwitcher = blurAppSwitcher == 'true' ? true : (blurAppSwitcher == null ? appConfig.blurAppSwitcher : false);
      _intruderDetection = intruderDetection == 'true' ? true : (intruderDetection == null ? appConfig.intruderEnabled : false);
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final secureStorage = ref.read(secureKeyStorageProvider);
    await secureStorage.storeString(key, value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16),
        children: [
          CupertinoListSection.insetGrouped(
            backgroundColor: Colors.black,
            children: [
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.phone, color: CupertinoColors.systemBlue),
                title: const Text('Lock on Background'),
                subtitle: const Text('Lock vault when app goes to background'),
                trailing: CupertinoSwitch(
                  value: _lockOnBackground,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _lockOnBackground = value);
                    _saveSetting('lock_on_background', value);
                  },
                ),
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.xmark_circle, color: CupertinoColors.systemBlue),
                title: const Text('Deny Screenshots'),
                subtitle: const Text('Prevent screenshots of vault content'),
                trailing: CupertinoSwitch(
                  value: _denyScreenshots,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _denyScreenshots = value);
                    _saveSetting('deny_screenshots', value);
                  },
                ),
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.eye_slash, color: CupertinoColors.systemBlue),
                title: const Text('Blur App Switcher'),
                subtitle: const Text('Blur app in recent apps (iOS)'),
                trailing: CupertinoSwitch(
                  value: _blurAppSwitcher,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _blurAppSwitcher = value);
                    _saveSetting('blur_app_switcher', value);
                  },
                ),
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.camera, color: CupertinoColors.systemRed),
                title: const Text('Intruder Detection'),
                subtitle: const Text('Capture photo on wrong PIN attempts'),
                trailing: CupertinoSwitch(
                  value: _intruderDetection,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _intruderDetection = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CupertinoListSection.insetGrouped(
            backgroundColor: Colors.black,
            children: [
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.info_circle, color: CupertinoColors.systemBlue),
                title: const Text('About Encryption'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // TODO: Navigate to encryption info screen
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

}
