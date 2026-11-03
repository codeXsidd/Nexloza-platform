import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexioza/app.dart';
import 'package:nexioza/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    publishableKey: SupabaseConstants.anonKey,
  );

  runApp(const ProviderScope(child: NexiozaApp()));
}
