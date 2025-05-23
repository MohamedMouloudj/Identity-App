import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:identity_app/services/g_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../main.dart';

class FaceAuthService {
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

  Future<XFile?> captureFaceImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (pickedFile == null) return null;
    return pickedFile;
  }

  Future<bool> validateSingleFace(XFile imageFile) async {
    final inputImage = InputImage.fromFile(File(imageFile.path));
    final faces = await _faceDetector.processImage(inputImage);
    return faces.length == 1;
  }

  Future<String?> uploadFace(String userId, XFile imageFile) async {
    final String filePath =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fileBytes = await imageFile.readAsBytes();

    try {
      await supabase.storage
          .from('user-faces')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(upsert: true),
          );
      final publicUrl = supabase.storage
          .from('user-faces')
          .getPublicUrl(filePath);
      await supabase
          .from('profiles')
          .update({
            'face_image_path': publicUrl,
            'face_registered_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String?> getStoredFaceUrl(String userId) async {
    final response = await supabase
            .from('profiles')
            .select('face_image_path')
            .eq('id', userId)
            .single();
    return response['face_image_path'] as String?;
  }

  Future<bool> matchFaces(XFile capturedFace, XFile storedFace) async {
    final result = await FaceMatchingService.matchFaces(
      capturedFace,
      storedFace,
    );

    if (result['success']) {
      if (result['isMatch']) {
        print('Faces match with ${result['similarityScore']} confidence!');
        return true;
      } else {
        print('Faces do not match: ${result['message']}');
        return false;
      }
    } else {
      throw Exception('Face matching failed: ${result['message']}');
    }
  }

  Future<XFile?> downloadImageToFile(String url) async {
    final response = await HttpClient().getUrl(Uri.parse(url));
    final result = await response.close();
    final bytes = await consolidateHttpClientResponseBytes(result);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'stored_face_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = p.join(tempDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return XFile(file.path);
  }

  Future<bool> loginWithFace(String userId) async {
    final capturedFace = await captureFaceImage();
    if (capturedFace == null || !(await validateSingleFace(capturedFace))) {
      return false;
    }

    final url = await getStoredFaceUrl(userId);
    if (url == null) return false;

    final storedFace = await downloadImageToFile(url);
    return await matchFaces(capturedFace, storedFace!);
  }
}
