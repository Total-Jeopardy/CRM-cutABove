import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/design_system/design_system.dart';
import 'core/env/build_secrets.dart';
import 'core/router/app_router.dart';
import 'core/storage/app_boxes.dart';
import 'core/supabase/supabase_provider.dart';

/// Defaults when `.env` is missing (e.g. some web release bundles).
const String _defaultSupabaseUrl =
    'https://fmfuubqbjwrtrhnadvfy.supabase.co';

/// JWT anon public key (web fallback when `.env` / `--dart-define` absent).
const String _defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZtZnV1YnFiandydHJobmFkdmZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MzY4MjEsImV4cCI6MjA5MTUxMjgyMX0.KKAYr_TM4f5PBLW8mCxCX3mJEuuD9ZeDiggJJPIAsfU';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('en', null);

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  try {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(AppBoxes.settings);
  } catch (_) {}

  try {
    // Order: --dart-define (CI) → .env → baked-in defaults (web fallback).
    final url = _firstNonEmpty([
      BuildSecrets.supabaseUrl,
      dotenv.env['SUPABASE_URL'],
      _defaultSupabaseUrl,
    ]);
    final key = _firstNonEmpty([
      BuildSecrets.supabaseAnonKey,
      dotenv.env['SUPABASE_ANON_KEY'],
      _defaultSupabaseAnonKey,
    ]);
    if (url.isNotEmpty &&
        key.isNotEmpty &&
        key.startsWith('eyJ') &&
        key.contains('.')) {
      await Supabase.initialize(url: url, anonKey: key);
    }
  } catch (_) {}

  if (isSupabaseInitialized) {
    await _refreshExpiredSupabaseSessionIfNeeded();
  }

  if (!isSupabaseInitialized) {
    runApp(const _InitErrorApp());
    return;
  }

  runApp(const ProviderScope(child: CutAboveCrmApp()));
}

String _firstNonEmpty(List<String?> values) {
  for (final v in values) {
    if (v != null && v.isNotEmpty) return v;
  }
  return '';
}

Future<void> _refreshExpiredSupabaseSessionIfNeeded() async {
  final session = supabaseClient.auth.currentSession;
  if (session != null && session.isExpired) {
    try {
      await supabaseClient.auth.refreshSession();
    } catch (_) {
      // Invalid refresh token; user will see login.
    }
  }
}

class CutAboveCrmApp extends ConsumerWidget {
  const CutAboveCrmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CutAbove CRM',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _InitErrorApp extends StatelessWidget {
  const _InitErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF4A148C),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CutAbove CRM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Configuration error.\nPlease contact your administrator.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
