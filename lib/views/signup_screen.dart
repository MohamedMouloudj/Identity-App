import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../styles/button_styles.dart';
import '../styles/snackbar_styles.dart';
import 'faceId_signup_screen.dart';
import '../main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();

  Future<void> signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final username = usernameController.text.trim();

    if (!email.contains('@') || password.length < 6 || username.isEmpty) {
      showAppSnackBar(context, "Please fill in all fields correctly.", type: SnackBarType.error);
      return;
    }

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final userId = response.user?.id;
      if (userId != null) {
        final existingProfile = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (existingProfile == null) {
          await supabase.from('profiles').insert({
            'id': userId,
            'username': username,
          });
        }else{
          final existingUsername = existingProfile['username'] as String? ?? '';
          if (existingUsername.isEmpty || existingUsername != username) {
            await supabase.from('profiles')
                .update({'username': username})
                .eq('id', userId);
          }
        }

        showAppSnackBar(context, "Signup successful! Please verify your email.",type:SnackBarType.success);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FaceIdSignupScreen(userId: response.user!.id),
          ),
        );
      } else {
        throw Exception("User not created.");
      }
    } on AuthException catch (e) {
      showAppSnackBar(context, "Signup failed: ${e.message}",type:SnackBarType.error);
    } catch (e) {
      showAppSnackBar(context, "Error: $e",type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Create an account",
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
            const Icon(Icons.how_to_reg_rounded, size: 80, color: Color(0xFF1A237E)),
            const SizedBox(height: 30),
            /*----------------------------*/
            _buildTextField(
              controller: usernameController,
              label: 'Username',
              icon: Icons.person,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: signUp,
              style: primaryButtonStyle(),
              child: const Text(
                'Sign Up',
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
