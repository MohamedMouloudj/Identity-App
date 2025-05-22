import 'package:flutter/material.dart';
import 'package:identity_app/services/face_auth_service.dart';

class FaceIdSignupScreen extends StatefulWidget {
  final String userId; // passed after initial signup
  const FaceIdSignupScreen({required this.userId, super.key});

  @override
  State<FaceIdSignupScreen> createState() => _FaceIdSignupScreenState();
}

class _FaceIdSignupScreenState extends State<FaceIdSignupScreen> {
  final FaceAuthService _faceService = FaceAuthService();
  bool _loading = false;
  String? _message;

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
      setState(() => _message = 'Please ensure only one clear face is visible.');
      return;
    }

    final uploadedUrl = await _faceService.uploadFace(widget.userId, faceImage);
    if (uploadedUrl != null) {
      setState(() => _message = 'Face registered successfully.');
      // Navigate or finish
    } else {
      setState(() => _message = 'Failed to upload face image.');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Face ID')),
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
              onPressed: _handleFaceCapture,
              child: const Text('Capture Face'),
            ),
          ],
        ),
      ),
    );
  }
}