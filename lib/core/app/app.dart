import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cover/core/theme/app_theme.dart';
import 'package:cover/core/di/di_container.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/presentation/navigation/app_router.dart';
import 'package:cover/presentation/navigation/app_router.g.dart';

class CoverApp extends ConsumerStatefulWidget {
  const CoverApp({super.key});

  @override
  ConsumerState<CoverApp> createState() => _CoverAppState();
}

class _CoverAppState extends ConsumerState<CoverApp> {
  @override
  void initState() {
    super.initState();
    _initializeRemoteConfig();
  }

  Future<void> _initializeRemoteConfig() async {
    try {
      final remoteConfigRepository = ref.read(remoteConfigRepositoryProvider);
      await remoteConfigRepository.initialize();
      
      // Log configuration for debugging
      final appConfig = ref.read(appConfigProvider);
      appConfig.logConfig();
      
      final featureGating = ref.read(featureGatingProvider);
      featureGating.logFeatureStatus();
      
      AppLogger.info('Remote Config initialization completed');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Remote Config', e, stackTrace);
      // App will continue with default values
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cover',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
