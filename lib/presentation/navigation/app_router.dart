import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/calculator/calculator_screen.dart';
import '../screens/vault/vault_shell_screen.dart';
import '../screens/vault/password/create_password_screen.dart';
import '../screens/vault/password/edit_password_screen.dart';
import '../screens/vault/contact/create_contact_screen.dart';
import '../screens/vault/contact/edit_contact_screen.dart';
import '../screens/settings/pin_change_screen.dart';
import '../screens/settings/security_settings_screen.dart';
import '../screens/settings/auto_lock_settings_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/settings/terms_conditions_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/storage_settings_screen.dart';
import '../screens/intruder/intruder_logs_screen.dart';
import '../screens/premium/premium_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/pin_setup_screen.dart';
import '../screens/onboarding/calculator_trick_screen.dart';
import '../screens/onboarding/decoy_pin_screen.dart';
import '../screens/splash_screen.dart';

part 'app_router.g.dart';

enum AppRoute {
  splash,
  calculator,
  premium,
  vault,
  createPassword,
  editPassword,
  createContact,
  editContact,
  pinChange,
  securitySettings,
  autoLockSettings,
  privacyPolicy,
  termsConditions,
  about,
  storageSettings,
  intruderLogs,
  onboardingWelcome,
  onboardingPinSetup,
  onboardingCalculatorTrick,
  onboardingDecoyPin,
}

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,
    routes: [
      // Splash route for initial onboarding check
      GoRoute(
        path: '/splash',
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashScreen(),
      ),
      // Onboarding routes
      GoRoute(
        path: '/onboarding/welcome',
        name: AppRoute.onboardingWelcome.name,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/pin-setup',
        name: AppRoute.onboardingPinSetup.name,
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/calculator-trick',
        name: AppRoute.onboardingCalculatorTrick.name,
        builder: (context, state) => const CalculatorTrickScreen(),
      ),
      GoRoute(
        path: '/onboarding/decoy-pin',
        name: AppRoute.onboardingDecoyPin.name,
        builder: (context, state) => const DecoyPinScreen(),
      ),
      // Main app routes
      GoRoute(
        path: '/',
        name: AppRoute.calculator.name,
        builder: (context, state) => const CalculatorScreen(),
      ),
      GoRoute(
        path: '/premium',
        name: AppRoute.premium.name,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const PremiumScreen(),
        ),
      ),
      GoRoute(
        path: '/vault',
        name: AppRoute.vault.name,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const VaultShellScreen(),
        ),
        routes: [
          GoRoute(
            path: 'password/create',
            name: AppRoute.createPassword.name,
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: const CreatePasswordScreen(),
            ),
          ),
          GoRoute(
            path: 'password/edit/:passwordId',
            name: AppRoute.editPassword.name,
            pageBuilder: (context, state) {
              final passwordId = int.parse(state.pathParameters['passwordId']!);
              return CupertinoPage(
                key: state.pageKey,
                child: EditPasswordScreen(passwordId: passwordId),
              );
            },
          ),
          GoRoute(
            path: 'contact/create',
            name: AppRoute.createContact.name,
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: const CreateContactScreen(),
            ),
          ),
          GoRoute(
            path: 'contact/edit/:contactId',
            name: AppRoute.editContact.name,
            pageBuilder: (context, state) {
              final contactId = int.parse(state.pathParameters['contactId']!);
              return CupertinoPage(
                key: state.pageKey,
                child: EditContactScreen(contactId: contactId),
              );
            },
          ),
          GoRoute(
            path: 'settings/pin-change',
            name: AppRoute.pinChange.name,
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: const PinChangeScreen(),
            ),
          ),
          GoRoute(
            path: 'settings/security',
            name: AppRoute.securitySettings.name,
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: const SecuritySettingsScreen(),
            ),
          ),
          GoRoute(
            path: 'settings/auto-lock',
            name: AppRoute.autoLockSettings.name,
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: const AutoLockSettingsScreen(),
            ),
          ),
          GoRoute(
            path: 'settings/storage',
            name: AppRoute.storageSettings.name,
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: const StorageSettingsScreen(),
            ),
          ),
          GoRoute(
            path: 'settings/intruder-logs',
            name: AppRoute.intruderLogs.name,
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: const IntruderLogsScreen(),
            ),
          ),
          GoRoute(
            path: 'settings/privacy-policy',
            name: AppRoute.privacyPolicy.name,
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: const PrivacyPolicyScreen(),
            ),
          ),
          GoRoute(
            path: 'settings/terms',
            name: AppRoute.termsConditions.name,
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: const TermsConditionsScreen(),
            ),
          ),
          GoRoute(
            path: 'settings/about',
            name: AppRoute.about.name,
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              child: const AboutScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}
