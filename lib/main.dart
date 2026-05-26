import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // <-- 1. Import foundation to use kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/router/router.dart';
import 'themes/transova_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enterprise Production Feature: Offline Persistence
  // 2. Wrap it in an if-statement so it only runs on iOS/Android, not Chrome.
  if (!kIsWeb) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Transova Logistics Platform',
      debugShowCheckedModeBanner: false,
      theme: TransovaTheme.lightTheme,
      routerConfig: router,
    );
  }
}