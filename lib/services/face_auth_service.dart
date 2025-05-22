import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FaceAuthService {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: false,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  Future<File?> captureFaceImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  Future<bool> validateSingleFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await _faceDetector.processImage(inputImage);
    return faces.length == 1;
  }

  Future<String?> uploadFace(String userId, File imageFile) async {
    final String filePath = 'user-faces/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fileBytes = await imageFile.readAsBytes();

    try {
      await supabase.storage.from('user-faces').uploadBinary(filePath, fileBytes, fileOptions: FileOptions(upsert: true));
      final publicUrl = supabase.storage.from('user-faces').getPublicUrl(filePath);
      await supabase.from('profiles').update({'face_image_path': publicUrl}).eq('id', userId);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<String?> getStoredFaceUrl(String userId) async {
    final response = await supabase.from('profiles').select('face_image_path').eq('id', userId).single();
    return response['face_image_path'] as String?;
  }

  Future<bool> matchFaces(File capturedFace, File storedFace) async {
    // Placeholder - You would integrate real face matching here
    return true; // Simulate success
  }

  Future<File?> downloadImageToFile(String url) async {
    final response = await HttpClient().getUrl(Uri.parse(url));
    final result = await response.close();
    final bytes = await consolidateHttpClientResponseBytes(result);
    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, 'stored_face.jpg');
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<bool> loginWithFace(String userId) async {
    final capturedFace = await captureFaceImage();
    if (capturedFace == null || !(await validateSingleFace(capturedFace))) return false;

    final url = await getStoredFaceUrl(userId);
    if (url == null) return false;

    final storedFace = await downloadImageToFile(url);
    return await matchFaces(capturedFace, storedFace!);
  }
}
