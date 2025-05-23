import 'package:flutter/material.dart';
import 'package:identity_app/services/face_auth_service.dart';
import 'package:identity_app/services/sounds_service.dart';
import 'package:identity_app/styles/button_styles.dart';
import 'package:identity_app/styles/snackbar_styles.dart';

class FaceIdLoginScreen extends StatefulWidget {
  final dynamic user;
  const FaceIdLoginScreen({required this.user, super.key});

  @override
  State<FaceIdLoginScreen> createState() => _FaceIdLoginScreenState();
}

class _FaceIdLoginScreenState extends State<FaceIdLoginScreen> {
  final FaceAuthService _faceService = FaceAuthService();
  bool _loading = false;
  String? _message;

  Future<void> _handleFaceLogin() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try{
      final success = await _faceService.loginWithFace(widget.user?['id']);
      if (success) {
        setState(() => _message = 'Login successful.');
        await playSuccessSound();
        Navigator.pushReplacementNamed(context, "/home",
            arguments: widget.user
        );
      } else {
        setState(() => _message = 'Face login failed.');
      }
    }catch(e){
      showAppSnackBar(context,
      "An error occurred during face login: $e"
        ,type: SnackBarType.error,
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
            'Login with Face ID',
          style: TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
          ? const CircularProgressIndicator()
          : Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.face_retouching_natural,
                  size: 120,
                  color: Color(0xFF1A237E),
                ),
                Card(
                  color: Colors.white,
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
                  onPressed: _handleFaceLogin,
                  style: primaryButtonStyle().copyWith(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.all( 16),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 24),
                  label: const Text(
                    "Capture Face",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_message!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            )
          ),
        ),
      ),
    );

  }
  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF1A237E),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF455A64),
            ),
          ),
        ),
      ],
    );
  }
}
