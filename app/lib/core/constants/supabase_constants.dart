abstract final class SupabaseConstants {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yvelgggjuiuqdjvxaaeq.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2ZWxnZ2dqdWl1cWRqdnhhYWVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM3MDU5NDgsImV4cCI6MjEwOTI4MTk0OH0.xzFVAxLiGcnULjQecKTV904b_A86iq20u8A8TfOg-4s',
  );
}
