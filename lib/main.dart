import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/app/app.dart';
import 'core/di/di_container.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run app immediately - Firebase initializes in background via FutureProvider
  runApp(
    const ProviderScope(
      child: CoverApp(),
    ),
  );
}
