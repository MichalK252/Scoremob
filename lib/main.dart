import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicjalizacja flutter_dotenv
  await dotenv.load(fileName: ".env");
  
  // Inicjalizacja Supabase
  await Supabase.initialize(
    url: (dotenv.env['SUPABASE_URL'] ?? '').trim(),
    anonKey: (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim(),
  );

  runApp(const MatchDayApp());
}

class MatchDayApp extends StatelessWidget {
  const MatchDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MatchDay',
      theme: ThemeData.dark(),
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
