import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cover/presentation/screens/intruder/intruder_logs_screen.dart';
import 'package:cover/presentation/screens/settings/pin_change_screen.dart';
import 'package:cover/presentation/screens/settings/auto_lock_settings_screen.dart';
import 'package:cover/presentation/screens/settings/privacy_policy_screen.dart';
import 'package:cover/presentation/screens/settings/terms_conditions_screen.dart';
import 'package:cover/presentation/screens/settings/about_screen.dart';
import 'package:cover/presentation/screens/settings/security_settings_screen.dart';
import 'package:cover/core/biometrics/biometrics_service.dart';
import 'package:cover/core/di/di_container.dart';
import 'package:cover/core/utils/logger.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkBiometricsAvailability();
  }

  Future<void> _checkBiometricsAvailability() async {
    final localAuth = LocalAuthentication();
    final available = await localAuth.canCheckBiometrics;
    final availableBiometrics = await localAuth.getAvailableBiometrics();
    
    setState(() {
      _biometricsAvailable = available && availableBiometrics.isNotEmpty;
    });

    // Check current biometrics enabled state
    final biometricsService = ref.read(biometricsServiceProvider);
    setState(() {
      _biometricsEnabled = biometricsService.isEnabled;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleBiometrics(bool value) async {
    final biometricsService = ref.read(biometricsServiceProvider);
    
    if (value) {
      // Prompt for authentication to enable biometrics
      try {
        final authenticated = await biometricsService.authenticate(
          localizedReason: 'Authenticate to enable biometric unlock',
        );
        if (authenticated) {
          await biometricsService.setEnabled(true);
          setState(() {
            _biometricsEnabled = true;
          });
        }
      } catch (e) {
        AppLogger.error('Failed to enable biometrics', e);
      }
    } else {
      // Disable biometrics without authentication
      await biometricsService.setEnabled(false);
      setState(() {
        _biometricsEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16),
        children: [
          CupertinoListSection.insetGrouped(
            backgroundColor: Colors.black,
            header: const Text(
              'SECURITY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0x99FFFFFF),
                letterSpacing: 0.5,
              ),
            ),
            children: [
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.lock_shield_fill, color: CupertinoColors.systemOrange),
                title: const Text('Change PIN'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/vault/settings/pin-change');
                },
              ),
              if (_biometricsAvailable)
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.faceid, color: CupertinoColors.systemBlue),
                  title: const Text('Face ID / Fingerprint'),
                  trailing: CupertinoSwitch(
                    value: _biometricsEnabled,
                    onChanged: _biometricsAvailable ? _toggleBiometrics : null,
                  ),
                ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.shield, color: CupertinoColors.systemBlue),
                title: const Text('Security'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/vault/settings/security');
                },
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.camera, color: CupertinoColors.systemRed),
                title: const Text('Intruder Logs'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/vault/settings/intruder-logs');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          CupertinoListSection.insetGrouped(
            backgroundColor: Colors.black,
            header: const Text(
              'GENERAL',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0x99FFFFFF),
                letterSpacing: 0.5,
              ),
            ),
            children: [
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.timer, color: CupertinoColors.systemBlue),
                title: const Text('Auto-lock'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/vault/settings/auto-lock');
                },
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.folder, color: CupertinoColors.systemBlue),
                title: const Text('Storage'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/vault/settings/storage');
                },
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.cloud_upload, color: CupertinoColors.systemBlue),
                title: const Text('Backup'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // TODO: Implement backup settings
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          CupertinoListSection.insetGrouped(
            backgroundColor: Colors.black,
            header: const Text(
              'ABOUT',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0x99FFFFFF),
                letterSpacing: 0.5,
              ),
            ),
            children: [
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.doc_text, color: CupertinoColors.systemBlue),
                title: const Text('Privacy Policy'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/vault/settings/privacy-policy');
                },
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.gavel, color: CupertinoColors.systemBlue),
                title: const Text('Terms & Conditions'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/vault/settings/terms');
                },
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.info, color: CupertinoColors.systemBlue),
                title: const Text('About'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/vault/settings/about');
                },
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.star, color: CupertinoColors.systemYellow),
                title: const Text('Rate App'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // TODO: Implement rate app
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          CupertinoListSection.insetGrouped(
            backgroundColor: Colors.black,
            header: const Text(
              'DANGER ZONE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0x99FFFFFF),
                letterSpacing: 0.5,
              ),
            ),
            children: [
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed),
                title: const Text('Delete Vault', style: TextStyle(color: CupertinoColors.systemRed)),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // TODO: Implement delete vault
                },
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.trash, color: CupertinoColors.systemRed),
                title: const Text('Wipe All Data', style: TextStyle(color: CupertinoColors.systemRed)),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // TODO: Implement wipe all data
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
