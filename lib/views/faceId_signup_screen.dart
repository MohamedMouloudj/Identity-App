import 'package:flutter/material.dart';
import 'package:identity_app/main.dart';
import 'package:identity_app/services/face_auth_service.dart';
import 'package:identity_app/styles/button_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FaceIdSignupScreen extends StatefulWidget {
  final PostgrestMap? user; // passed after initial signup
  FaceIdSignupScreen({required this.user, super.key});

  @override
  State<FaceIdSignupScreen> createState() => _FaceIdSignupScreenState();
}

class _FaceIdSignupScreenState extends State<FaceIdSignupScreen> {
  final FaceAuthService _faceService = FaceAuthService();
  bool _loading = false;
  String? _message;

  Future<void> cancelSignUp() async {
    await supabase.from('profiles').delete().eq('id', widget.user!);
    await supabase.auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _handleFaceCapture() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final hasPermission = await _faceService.requestCameraPermission();
    if (!hasPermission) {
      setState(() => _message = 'Camera permission denied.');
      return;
    }

    final faceImage = await _faceService.captureFaceImage();
    if (faceImage == null) {
      setState(() => _message = 'Image capture cancelled.');
      return;
    }

    final isValid = await _faceService.validateSingleFace(faceImage);
    if (!isValid) {
      setState(
        () => _message = 'Please ensure only one clear face is visible.',
      );
      return;
    }

    final uploadedUrl = await _faceService.uploadFace(
      widget.user!['id'],
      faceImage,
    );
    if (uploadedUrl != null) {
      setState(() => _message = 'Face registered successfully.');
      Navigator.pushReplacementNamed(context, "/home", arguments: widget.user);
    } else {
      setState(() => _message = 'Failed to upload face image.');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Face ID Setup',
          style: TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child:
            _loading
                ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1A237E),
                        ),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _message != null ? _message! : "Setting up Face ID...",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF455A64),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        const Icon(
                          Icons.face_retouching_natural,
                          size: 120,
                          color: Color(0xFF1A237E),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          "Set up Face ID Authentication",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Secure your account with biometric authentication",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF455A64),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "For best results:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildTipRow(
                                  Icons.lightbulb_outline,
                                  "Ensure good lighting",
                                ),
                                const SizedBox(height: 12),
                                _buildTipRow(
                                  Icons.visibility,
                                  "Keep your eyes open",
                                ),
                                const SizedBox(height: 12),
                                _buildTipRow(
                                  Icons.center_focus_strong,
                                  "Look directly at the camera",
                                ),
                                const SizedBox(height: 12),
                                _buildTipRow(
                                  Icons.person_outline,
                                  "Ensure only your face is visible",
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        ElevatedButton.icon(
                          onPressed: _handleFaceCapture,
                          style: primaryButtonStyle().copyWith(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt, size: 24),
                          label: const Text(
                            "Capture Face",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: cancelSignUp,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF1A237E),
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancel sign up",
                            style: TextStyle(
                              color: Color(0xFF1A237E),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1A237E)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Color(0xFF455A64)),
          ),
        ),
      ],
    );
  }
}
