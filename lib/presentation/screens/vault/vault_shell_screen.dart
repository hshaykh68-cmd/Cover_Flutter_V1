import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cover/presentation/screens/vault/tabs/vault_tab.dart';
import 'package:cover/presentation/screens/vault/tabs/gallery_tab.dart';
import 'package:cover/presentation/screens/vault/tabs/files_tab.dart';
import 'package:cover/presentation/screens/vault/tabs/notes_tab.dart';
import 'package:cover/presentation/screens/vault/tabs/passwords_tab.dart';
import 'package:cover/presentation/screens/vault/tabs/contacts_tab.dart';
import 'package:cover/presentation/screens/vault/tabs/settings_tab.dart';
import 'package:cover/presentation/screens/premium/premium_screen.dart';
import 'package:cover/presentation/widgets/apple_style_top_bar.dart';
import 'package:cover/core/emergency/emergency_close_service.dart';
import 'package:cover/core/biometrics/biometrics_service.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/di/di_container.dart';

enum VaultTab {
  vault,
  gallery,
  files,
  notes,
  passwords,
  contacts,
  settings,
}

class VaultShellScreen extends ConsumerStatefulWidget {
  const VaultShellScreen({super.key});

  @override
  ConsumerState<VaultShellScreen> createState() => _VaultShellScreenState();
}

class _VaultShellScreenState extends ConsumerState<VaultShellScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  EmergencyCloseService? _emergencyCloseService;
  BiometricsService? _biometricsService;
  bool _biometricsPrompted = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize emergency close service
    _initializeEmergencyClose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync page controller with provider state
    final currentTab = ref.read(vaultTabStateProvider);
    _pageController.jumpToPage(currentTab.index);
  }

  void _initializeEmergencyClose() {
    final appConfig = ref.read(appConfigProvider);
    _emergencyCloseService = EmergencyCloseServiceImpl(
      appConfig: appConfig,
      sensitivity: appConfig.shakeSensitivity,
    );

    // Set up emergency close callback
    _emergencyCloseService!.onEmergencyClose = () {
      if (mounted) {
        HapticFeedback.heavyImpact();
        context.go('/');
      }
    };

    // Start monitoring if enabled
    if (appConfig.intruderEnabled) {
      _emergencyCloseService!.startMonitoring();
    }

    // Initialize biometrics
    _initializeBiometrics(appConfig);
  }

  void _initializeBiometrics(AppConfig appConfig) async {
    if (!appConfig.biometricsEnabled) {
      return;
    }

    try {
      final localAuth = LocalAuthentication();
      _biometricsService = BiometricsServiceImpl(
        localAuth: localAuth,
        appConfig: appConfig,
      );

      final isAvailable = await _biometricsService!.isAvailable();
      if (isAvailable && mounted && !_biometricsPrompted) {
        _biometricsPrompted = true;

        // Prompt for biometrics based on variant
        final shouldPrompt = appConfig.biometricsPromptVariant == 'after_first_unlock';
        if (shouldPrompt) {
          final authenticated = await _biometricsService!.authenticate();
          if (!authenticated && mounted) {
            // If biometrics fails, return to calculator
            context.go('/');
          }
        }
      }
    } catch (e) {
      // Biometrics initialization failed, continue without it
      AppLogger.error('Failed to initialize biometrics', e);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emergencyCloseService?.dispose();
    super.dispose();
  }

  void _onTabChanged(VaultTab tab) {
    HapticFeedback.selectionClick();
    ref.read(vaultTabStateProvider.notifier).setTab(tab);
    _pageController.animateToPage(
      tab.index,
      duration: const Duration(milliseconds: 200), // DESIGN-003: Tab switch duration
      curve: Curves.easeOutCubic, // DESIGN-003: Tab switch curve
    );
  }

  void _onPageChanged(int index) {
    final tab = VaultTab.values[index];
    ref.read(vaultTabStateProvider.notifier).setTab(tab);
  }

  void _onBackPressed() {
    // Back press from any vault tab should navigate to calculator
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentTab = ref.watch(vaultTabStateProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => _onBackPressed(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            AppleStyleTopBar(
              title: _getTabTitle(currentTab),
              actions: [_buildPremiumButton()],
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: const [
                  VaultOverviewTab(),
                  GalleryTab(),
                  FilesTab(),
                  NotesTab(),
                  PasswordsTab(),
                  ContactsTab(),
                  SettingsTab(),
                ],
              ),
            ),
            _CustomBottomNavigationBar(
              currentTab: currentTab,
              onTabChanged: _onTabChanged,
            ),
          ],
        ),
      ),
    );
  }

  String _getTabTitle(VaultTab tab) {
    switch (tab) {
      case VaultTab.vault:
        return 'Vault';
      case VaultTab.gallery:
        return 'Gallery';
      case VaultTab.files:
        return 'Files';
      case VaultTab.notes:
        return 'Notes';
      case VaultTab.passwords:
        return 'Passwords';
      case VaultTab.contacts:
        return 'Contacts';
      case VaultTab.settings:
        return 'Settings';
    }
  }

  Widget _buildPremiumButton() {
    return TextButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        context.push('/premium');
      },
      child: Text(
        'Upgrade',
        style: TextStyle(
          color: CupertinoColors.systemBlue.resolveFrom(context),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CustomBottomNavigationBar extends StatelessWidget {
  final VaultTab currentTab;
  final Function(VaultTab) onTabChanged;

  const _CustomBottomNavigationBar({
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            border: Border(
              top: BorderSide(
                color: const Color(0x33545458), // separator color
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Builder(
                builder: (context) {
                  final totalWidth = MediaQuery.of(context).size.width - 32;
                  final tabW = totalWidth / VaultTab.values.length;
                  final pillW = tabW * 0.8;
                  final pillLeft = 16 + (currentTab.index * tabW) + (tabW * 0.1);
                  
                  return Stack(
                    children: [
                      // Sliding pill indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200), // DESIGN-003: Tab switch duration
                        curve: Curves.easeOutCubic, // DESIGN-003: Tab switch curve
                        left: pillLeft,
                        top: 4,
                        child: Container(
                          width: pillW,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      // Tab buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: VaultTab.values.map((tab) {
                          return Expanded(
                            child: _TabButton(
                              tab: tab,
                              isSelected: currentTab == tab,
                              onTap: () => onTabChanged(tab),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final VaultTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _getTabIcon(tab);
    final label = _getTabLabel(tab);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTabIcon(VaultTab tab) {
    switch (tab) {
      case VaultTab.vault:
        return CupertinoIcons.square_grid_2x2;
      case VaultTab.gallery:
        return CupertinoIcons.photo_on_rectangle;
      case VaultTab.files:
        return CupertinoIcons.folder;
      case VaultTab.notes:
        return CupertinoIcons.doc_text;
      case VaultTab.passwords:
        return CupertinoIcons.lock;
      case VaultTab.contacts:
        return CupertinoIcons.person_2;
      case VaultTab.settings:
        return CupertinoIcons.gear;
    }
  }

  String _getTabLabel(VaultTab tab) {
    switch (tab) {
      case VaultTab.vault:
        return 'Vault';
      case VaultTab.gallery:
        return 'Gallery';
      case VaultTab.files:
        return 'Files';
      case VaultTab.notes:
        return 'Notes';
      case VaultTab.passwords:
        return 'Passwords';
      case VaultTab.contacts:
        return 'Contacts';
      case VaultTab.settings:
        return 'Settings';
    }
  }
}

