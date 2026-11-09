import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env_config.dart';
import 'core/storage/preferences_service.dart';
import 'features/dashboards/presentation/widgets/renderers/widget_registrations.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerAllWidgets();

  final prefs = await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    publishableKey: EnvConfig.supabaseAnonKey,
  );

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const NexlozaApp(),
    ),
  );
}
