import 'package:flutter/material.dart';
import 'package:identity_app/services/face_auth_service.dart';
import 'package:identity_app/styles/snackbar_styles.dart';

class FaceIdLoginScreen extends StatefulWidget {
  final String userId;
  const FaceIdLoginScreen({required this.userId, super.key});

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
      final success = await _faceService.loginWithFace(widget.userId);
      if (success) {
        setState(() => _message = 'Login successful.');
        Navigator.pushReplacementNamed(context, "/home");
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
      appBar: AppBar(title: const Text('Login with Face ID')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_message!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: _handleFaceLogin,
              child: const Text('Authenticate Face'),
            ),
          ],
        ),
      ),
    );
  }
}
