import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/providers/shared_prefs_provider.dart';

import 'core/providers/logger_observer.dart';
import 'features/employee/providers/repository_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: 'https://kebtrzjbwjwcuueymaqw.supabase.co',
    anonKey: 'sb_publishable_soP1ru4_Ebt1-Gj6H2vpIA_QKElv4Qk',
  );

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    observers: [LoggerObserver()],
  );

  // Attempt to sync offline entries on startup
  container.read(syncRepositoryProvider).attemptSync();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ClockInClockOut(),
      
    ),
  );
}
