import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    User? user = supabase.auth.currentSession?.user;
    if(user == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
    final profile = supabase
        .from('profiles')
        .select()
        .eq('id', user!.id)
        .single();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1A237E),
        title: const Text('Home',
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          )
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Welcome, ${profile}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
          ),
        ),
      )
    );
  }
}
