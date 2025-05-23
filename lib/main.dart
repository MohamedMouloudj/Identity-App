import 'package:flutter/material.dart';
import 'package:identity_app/views/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  await Supabase.initialize(url: supabaseUrl!, anonKey: supabaseAnonKey!);
  
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Identity App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) {
          final userData = ModalRoute.of(context)?.settings.arguments;
          return HomePage(userData: userData);
        },
        '/login': (context) => LoginPage(),
        '/signup': (context) => const SignupPage(),
      },
    );
  }
}