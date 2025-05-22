import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'signup_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import '../styles/button_styles.dart';
import '../styles/snackbar_styles.dart';
import 'faceId_login_screen.dart';

Future<void> playSuccessSound() async {
  try {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/success.mp3'));
  } catch (e) {
    debugPrint('Error playing sound: $e');
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  static final _webClientId = dotenv.env['WEBCLIENT_ID'];
  static final _iosClientId = dotenv.env['IOS_CLIENT_ID'];
  static final _androidClientId = dotenv.env['ANDROID_CLIENT_ID'];

  String getFriendlyError(String message) {
    if (message.contains("invalid login")) return "Invalid email or password.";
    if (message.contains("Email not confirmed")) return "Please verify your email before logging in.";
    return "An unexpected error occurred. Please try again: $message";
  }

  Future<void> signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? _iosClientId : _androidClientId,
        serverClientId: _webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Missing Google tokens');
      }

      final res = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (res.session != null) {
        await playSuccessSound();
        if (mounted) {
          showAppSnackBar(context, 'Google Sign-in successful!', type: SnackBarType.success);
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Google Sign-in failed: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> signIn() async {
    if (_isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showAppSnackBar(context, 'Please enter both email and password.', type: SnackBarType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session != null) {
        await playSuccessSound();
        if (mounted) {
          showAppSnackBar(context, 'Login successful!', type: SnackBarType.success);
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        showAppSnackBar(context, getFriendlyError(e.message), type: SnackBarType.error);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Login failed: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToFaceIdLogin() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showAppSnackBar(
          context,
          'Please enter your email and password first for Face ID login.',
          type: SnackBarType.info
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaceIdLoginScreen(
          userId: Supabase.instance.client.auth.currentUser?.id ?? '',
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Welcome Back",
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
            const Icon(Icons.lock_open_rounded, size: 80, color: Color(0xFF1A237E)),
            const SizedBox(height: 30),
            _buildTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : signIn,
              style: primaryButtonStyle(),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text('Login'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _navigateToFaceIdLogin,
              style: primaryButtonStyle(),
              icon: const Icon(Icons.face),
              label: const Text("Login with Face ID"),
            ),
            const SizedBox(height: 24),
            const Divider(height: 2, color: Color(0xC18E8E8E)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : signInWithGoogle,
              icon: Image.asset(
                'assets/images/google_logo.png',
                height: 24,
                width: 24,
              ),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _isLoading ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                );
              },
              child: const Text(
                "Don't have an account? Sign up",
                style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.w600),
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
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none
        ),
      ),
    );
  }
}