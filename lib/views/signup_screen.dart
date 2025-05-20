import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final matriculeController = TextEditingController();

  Future<void> signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final matricule = matriculeController.text.trim();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final userId = response.user?.id;
      if (userId != null) {
        final existingProfile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (existingProfile == null) {
          await Supabase.instance.client.from('profiles').insert({
            'id': userId,
            'matricule': matricule,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup successful! Please verify your email.")),
        );
        Navigator.pop(context);
      } else {
        throw Exception("User not created.");
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Create Account",
          style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.app_registration_rounded, size: 80, color: Color(0xFF1A237E)),
            const SizedBox(height: 30),
            _buildTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: matriculeController,
              label: 'Matricule',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
                elevation: 8,
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
