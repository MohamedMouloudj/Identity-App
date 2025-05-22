import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// A service class for matching two face images using Google ML Kit
class FaceMatchingService {
  // Create face detector with high-accuracy settings
  static FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    ),
  );

  // Matching thresholds
  static const double SIMILARITY_THRESHOLD = 0.92;
  static const double HIGH_CONFIDENCE_THRESHOLD = 0.95;
  static const double ANGLE_THRESHOLD = 7.0;
  static const double EYE_RATIO_MIN = 0.87;
  static const double EYE_RATIO_MAX = 1.13;
  static const int MIN_LANDMARKS = 5;

  /// Convert XFile to a temporary file path for ML Kit processing
  static Future<String> _xFileToTempPath(XFile xFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'temp_face_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempPath = '${tempDir.path}/$fileName';

      // Copy XFile to temporary location
      final bytes = await xFile.readAsBytes();
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);

      return tempPath;
    } catch (e) {
      throw Exception('Failed to convert XFile to temp path: $e');
    }
  }

  /// Main function to match two face images
  /// Returns a Map with matching results
  static Future<Map<String, dynamic>> matchFaces(XFile image1, XFile image2) async {
    try {
      print("[FaceMatchingService] Starting face matching process");

      // Convert XFiles to temporary paths
      final String imagePath1 = await _xFileToTempPath(image1);
      final String imagePath2 = await _xFileToTempPath(image2);

      print("[FaceMatchingService] Processing first image: $imagePath1");
      print("[FaceMatchingService] Processing second image: $imagePath2");

      // Process both images
      final InputImage inputImage1 = InputImage.fromFilePath(imagePath1);
      final InputImage inputImage2 = InputImage.fromFilePath(imagePath2);

      final List<Face> faces1 = await _faceDetector.processImage(inputImage1);
      final List<Face> faces2 = await _faceDetector.processImage(inputImage2);

      // Clean up temporary files
      try {
        await File(imagePath1).delete();
        await File(imagePath2).delete();
      } catch (e) {
        print("[FaceMatchingService] Warning: Could not delete temp files: $e");
      }

      print("[FaceMatchingService] Faces detected - Image1: ${faces1.length}, Image2: ${faces2.length}");

      // Validate face detection results
      final validationResult = _validateFaceDetection(faces1, faces2);
      if (!validationResult['success']) {
        return validationResult;
      }

      final Face face1 = faces1.first;
      final Face face2 = faces2.first;

      // Log face quality for debugging
      _logFaceQuality(face1, "IMAGE1");
      _logFaceQuality(face2, "IMAGE2");

      // Check face quality
      if (!_isFaceQualityGood(face1)) {
        return {
          'success': false,
          'isMatch': false,
          'message': 'First image face quality is not good enough',
          'similarityScore': 0.0,
        };
      }

      if (!_isFaceQualityGood(face2)) {
        return {
          'success': false,
          'isMatch': false,
          'message': 'Second image face quality is not good enough',
          'similarityScore': 0.0,
        };
      }

      // Compare faces using enhanced algorithm
      final Map<String, dynamic> compareResult = await _compareFacesEnhanced(face1, face2);

      final bool isMatch = compareResult['isMatch'];
      final double similarityScore = compareResult['similarityScore'];
      final Map<String, dynamic> details = compareResult['details'];

      print("[FaceMatchingService] Face match result: $isMatch (Score: $similarityScore)");

      return {
        'success': true,
        'isMatch': isMatch,
        'similarityScore': similarityScore,
        'message': isMatch
            ? 'Faces match with ${(similarityScore * 100).toStringAsFixed(1)}% confidence'
            : 'Faces do not match. (Score: ${(similarityScore * 100).toStringAsFixed(1)}%)',
        'details': details,
      };

    } catch (e) {
      print("[FaceMatchingService] Error during face matching: $e");
      return {
        'success': false,
        'isMatch': false,
        'message': 'Error during face matching: $e',
        'similarityScore': 0.0,
      };
    }
  }

  /// Validate face detection results
  static Map<String, dynamic> _validateFaceDetection(List<Face> faces1, List<Face> faces2) {
    if (faces1.isEmpty) {
      return {
        'success': false,
        'isMatch': false,
        'message': 'No face detected in first image',
        'similarityScore': 0.0,
      };
    }

    if (faces2.isEmpty) {
      return {
        'success': false,
        'isMatch': false,
        'message': 'No face detected in second image',
        'similarityScore': 0.0,
      };
    }

    if (faces1.length > 1) {
      return {
        'success': false,
        'isMatch': false,
        'message': 'Multiple faces detected in first image. Please use an image with only one face.',
        'similarityScore': 0.0,
      };
    }

    if (faces2.length > 1) {
      return {
        'success': false,
        'isMatch': false,
        'message': 'Multiple faces detected in second image. Please use an image with only one face.',
        'similarityScore': 0.0,
      };
    }

    return {'success': true};
  }

  /// Log face quality metrics for debugging
  static void _logFaceQuality(Face face, String label) {
    print("[FaceMatchingService] $label FACE METRICS:");
    print("[FaceMatchingService] - Tracking ID: ${face.trackingId}");
    print("[FaceMatchingService] - Head Euler X: ${face.headEulerAngleX}°");
    print("[FaceMatchingService] - Head Euler Y: ${face.headEulerAngleY}°");
    print("[FaceMatchingService] - Head Euler Z: ${face.headEulerAngleZ}°");
    print("[FaceMatchingService] - Smiling Probability: ${face.smilingProbability}");
    print("[FaceMatchingService] - Left Eye Open: ${face.leftEyeOpenProbability}");
    print("[FaceMatchingService] - Right Eye Open: ${face.rightEyeOpenProbability}");
    print("[FaceMatchingService] - Landmarks count: ${face.landmarks.length}");
    print("[FaceMatchingService] - Face bounding box: ${face.boundingBox.width} x ${face.boundingBox.height}");
  }

  /// Check face quality with strict requirements
  static bool _isFaceQualityGood(Face face) {
    // Must have all key landmarks
    final requiredLandmarks = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
    ];

    int foundLandmarks = 0;
    for (var type in requiredLandmarks) {
      if (face.landmarks.containsKey(type)) {
        foundLandmarks++;
      } else {
        print("[FaceMatchingService] Missing required landmark: $type");
      }
    }

    if (foundLandmarks < MIN_LANDMARKS) {
      print("[FaceMatchingService] Not enough landmarks: $foundLandmarks < $MIN_LANDMARKS");
      return false;
    }

    // Strict head rotation check
    if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 15) {
      print("[FaceMatchingService] Head rotation Y too large: ${face.headEulerAngleY}°");
      return false;
    }

    if (face.headEulerAngleZ != null && face.headEulerAngleZ!.abs() > 15) {
      print("[FaceMatchingService] Head rotation Z too large: ${face.headEulerAngleZ}°");
      return false;
    }

    // Eyes must be open
    if (face.leftEyeOpenProbability != null && face.leftEyeOpenProbability! < 0.6) {
      print("[FaceMatchingService] Left eye not open enough: ${face.leftEyeOpenProbability}");
      return false;
    }

    if (face.rightEyeOpenProbability != null && face.rightEyeOpenProbability! < 0.6) {
      print("[FaceMatchingService] Right eye not open enough: ${face.rightEyeOpenProbability}");
      return false;
    }

    // Check face size
    final boundingBox = face.boundingBox;
    if (boundingBox.width < 150 || boundingBox.height < 150) {
      print("[FaceMatchingService] Face too small: ${boundingBox.width}x${boundingBox.height}");
      return false;
    }

    return true;
  }

  /// Enhanced face comparison algorithm
  static Future<Map<String, dynamic>> _compareFacesEnhanced(Face detectedFace, Face referenceFace) async {

    Map<String, dynamic> result = {
      'isMatch': false,
      'similarityScore': 0.0,
      'details': <String, dynamic>{},
    };

    // Check essential landmarks presence
    final requiredLandmarks = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
    ];

    for (var type in requiredLandmarks) {
      if (!detectedFace.landmarks.containsKey(type) || !referenceFace.landmarks.containsKey(type)) {
        return result;
      }
    }

    // Strict head rotation comparison
    if (detectedFace.headEulerAngleY != null && referenceFace.headEulerAngleY != null) {
      final double yDiff = (detectedFace.headEulerAngleY! - referenceFace.headEulerAngleY!).abs();
      result['details']['yRotationDiff'] = yDiff;

      if (yDiff > ANGLE_THRESHOLD) {
        return result;
      }
    }

    if (detectedFace.headEulerAngleZ != null && referenceFace.headEulerAngleZ != null) {
      final double zDiff = (detectedFace.headEulerAngleZ! - referenceFace.headEulerAngleZ!).abs();
      result['details']['zRotationDiff'] = zDiff;

      if (zDiff > ANGLE_THRESHOLD) {
        return result;
      }
    }

    // Get key facial landmarks
    final Point<int> detectedNose = detectedFace.landmarks[FaceLandmarkType.noseBase]!.position;
    final Point<int> referenceNose = referenceFace.landmarks[FaceLandmarkType.noseBase]!.position;
    final Point<int> detectedLeftEye = detectedFace.landmarks[FaceLandmarkType.leftEye]!.position;
    final Point<int> referenceLeftEye = referenceFace.landmarks[FaceLandmarkType.leftEye]!.position;
    final Point<int> detectedRightEye = detectedFace.landmarks[FaceLandmarkType.rightEye]!.position;
    final Point<int> referenceRightEye = referenceFace.landmarks[FaceLandmarkType.rightEye]!.position;
    final Point<int> detectedLeftMouth = detectedFace.landmarks[FaceLandmarkType.leftMouth]!.position;
    final Point<int> referenceLeftMouth = referenceFace.landmarks[FaceLandmarkType.leftMouth]!.position;
    final Point<int> detectedRightMouth = detectedFace.landmarks[FaceLandmarkType.rightMouth]!.position;
    final Point<int> referenceRightMouth = referenceFace.landmarks[FaceLandmarkType.rightMouth]!.position;

    try {
      // Calculate distances between facial landmarks
      final double detectedEyeDistance = _distance(detectedLeftEye, detectedRightEye);
      final double referenceEyeDistance = _distance(referenceLeftEye, referenceRightEye);

      // Calculate ratio between eyes
      final double eyeRatio = detectedEyeDistance / referenceEyeDistance;
      result['details']['eyeRatio'] = eyeRatio;

      // Strict eye ratio check
      if (eyeRatio < EYE_RATIO_MIN || eyeRatio > EYE_RATIO_MAX) {
        print("[FaceMatchingService] Eye distance ratio out of range: $eyeRatio");
        return result;
      }

      // Calculate normalized distances and similarities
      Map<String, double> similarities = {};

      // Eye-to-nose relationships
      final double detectedLeftEyeToNose = _distance(detectedLeftEye, detectedNose) / detectedEyeDistance;
      final double referenceLeftEyeToNose = _distance(referenceLeftEye, referenceNose) / referenceEyeDistance;
      similarities['leftEyeToNoseRatio'] = 1 - (detectedLeftEyeToNose - referenceLeftEyeToNose).abs();

      final double detectedRightEyeToNose = _distance(detectedRightEye, detectedNose) / detectedEyeDistance;
      final double referenceRightEyeToNose = _distance(referenceRightEye, referenceNose) / referenceEyeDistance;
      similarities['rightEyeToNoseRatio'] = 1 - (detectedRightEyeToNose - referenceRightEyeToNose).abs();

      // Eye-to-eye ratio
      similarities['eyeToEyeRatio'] = 1 - min((eyeRatio - 1).abs(), 0.3);

      // Face angle analysis
      final double detectedEyeNoseEyeAngle = _calculateAngle(detectedLeftEye, detectedNose, detectedRightEye);
      final double referenceEyeNoseEyeAngle = _calculateAngle(referenceLeftEye, referenceNose, referenceRightEye);
      final double eyeNoseEyeAngleDiff = (detectedEyeNoseEyeAngle - referenceEyeNoseEyeAngle).abs();

      if (eyeNoseEyeAngleDiff > 7.0) {
        print("[FaceMatchingService] Eye-nose-eye angle difference too large: $eyeNoseEyeAngleDiff°");
        return result;
      }

      similarities['eyeNoseEyeAngle'] = 1 - (eyeNoseEyeAngleDiff / 180);

      // Mouth width ratio
      final double detectedMouthWidth = _distance(detectedLeftMouth, detectedRightMouth) / detectedEyeDistance;
      final double referenceMouthWidth = _distance(referenceLeftMouth, referenceRightMouth) / referenceEyeDistance;
      similarities['mouthWidthRatio'] = 1 - min((detectedMouthWidth - referenceMouthWidth).abs(), 0.3);

      // Eye-to-mouth vertical distance
      final Point<int> detectedMouthCenter = Point<int>(
          (detectedLeftMouth.x + detectedRightMouth.x) ~/ 2,
          (detectedLeftMouth.y + detectedRightMouth.y) ~/ 2);
      final Point<int> referenceMouthCenter = Point<int>(
          (referenceLeftMouth.x + referenceRightMouth.x) ~/ 2,
          (referenceLeftMouth.y + referenceRightMouth.y) ~/ 2);
      final Point<int> detectedEyeCenter = Point<int>(
          (detectedLeftEye.x + detectedRightEye.x) ~/ 2,
          (detectedLeftEye.y + detectedRightEye.y) ~/ 2);
      final Point<int> referenceEyeCenter = Point<int>(
          (referenceLeftEye.x + referenceRightEye.x) ~/ 2,
          (referenceLeftEye.y + referenceRightEye.y) ~/ 2);

      final double detectedEyeToMouthDist = _distance(detectedEyeCenter, detectedMouthCenter) / detectedEyeDistance;
      final double referenceEyeToMouthDist = _distance(referenceEyeCenter, referenceMouthCenter) / referenceEyeDistance;
      similarities['eyeToMouthRatio'] = 1 - min((detectedEyeToMouthDist - referenceEyeToMouthDist).abs(), 0.3);

      // Cross-face diagonal ratios
      final double detectedLeftEyeToRightMouth = _distance(detectedLeftEye, detectedRightMouth) / detectedEyeDistance;
      final double referenceLeftEyeToRightMouth = _distance(referenceLeftEye, referenceRightMouth) / referenceEyeDistance;
      similarities['leftEyeToRightMouthRatio'] = 1 - min((detectedLeftEyeToRightMouth - referenceLeftEyeToRightMouth).abs(), 0.3);

      final double detectedRightEyeToLeftMouth = _distance(detectedRightEye, detectedLeftMouth) / detectedEyeDistance;
      final double referenceRightEyeToLeftMouth = _distance(referenceRightEye, referenceLeftMouth) / referenceEyeDistance;
      similarities['rightEyeToLeftMouthRatio'] = 1 - min((detectedRightEyeToLeftMouth - referenceRightEyeToLeftMouth).abs(), 0.3);

      // Log similarity scores
      print("[FaceMatchingService] Similarity scores:");
      similarities.forEach((key, value) {
        print("[FaceMatchingService] - $key: $value");
      });

      // Calculate weighted average similarity
      Map<String, double> weights = {
        'leftEyeToNoseRatio': 1.5,
        'rightEyeToNoseRatio': 1.5,
        'eyeToEyeRatio': 0.7,
        'eyeNoseEyeAngle': 2.0,
        'mouthWidthRatio': 1.0,
        'eyeToMouthRatio': 1.8,
        'leftEyeToRightMouthRatio': 1.4,
        'rightEyeToLeftMouthRatio': 1.4,
      };

      double totalWeight = 0;
      double weightedSum = 0;
      int validFeatures = 0;
      Map<String, bool> failedFeatures = {};

      similarities.forEach((key, value) {
        if (value.isNaN) {
          print("[FaceMatchingService] Skipping invalid measurement: $key = $value");
          return;
        }

        if (value < 0.75) {
          failedFeatures[key] = true;
          print("[FaceMatchingService] Low similarity feature: $key = $value");
        }

        double weight = weights[key] ?? 1.0;
        weightedSum += value * weight;
        totalWeight += weight;
        validFeatures++;
      });

      result['details']['failedFeatures'] = failedFeatures;

      if (validFeatures < MIN_LANDMARKS) {
        print("[FaceMatchingService] Not enough valid measurements: $validFeatures");
        return result;
      }

      if (failedFeatures.length > 3) {
        print("[FaceMatchingService] Too many features with low similarity: ${failedFeatures.length}");
        return result;
      }

      // Final similarity score
      double similarityScore = totalWeight > 0 ? weightedSum / totalWeight : 0;
      result['similarityScore'] = similarityScore;
      result['details']['similarities'] = similarities;

      print("[FaceMatchingService] Final similarity score: $similarityScore");

      // Determine match based on threshold
      if (similarityScore >= SIMILARITY_THRESHOLD) {
        if (similarityScore >= HIGH_CONFIDENCE_THRESHOLD) {
          print("[FaceMatchingService] High confidence match");
          result['isMatch'] = true;
        } else {
          // Additional verification for borderline matches
          bool eyeConsistencyCheck = true;
          if (detectedFace.leftEyeOpenProbability != null && referenceFace.leftEyeOpenProbability != null) {
            double eyeDiff = (detectedFace.leftEyeOpenProbability! - referenceFace.leftEyeOpenProbability!).abs();
            if (eyeDiff > 0.35) {
              eyeConsistencyCheck = false;
            }
          }

          result['isMatch'] = eyeConsistencyCheck && !failedFeatures.containsKey('eyeNoseEyeAngle');
          print("[FaceMatchingService] Borderline match with additional checks: ${result['isMatch']}");
        }
      }

      return result;
    } catch (e) {
      print("[FaceMatchingService] Error in face comparison: $e");
      return result;
    }
  }

  /// Calculate distance between two points
  static double _distance(Point<int> point1, Point<int> point2) {
    return sqrt(pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2));
  }

  /// Calculate angle between three points (in degrees)
  static double _calculateAngle(Point<int> p1, Point<int> p2, Point<int> p3) {
    double v1x = (p1.x - p2.x).toDouble();
    double v1y = (p1.y - p2.y).toDouble();
    double v2x = (p3.x - p2.x).toDouble();
    double v2y = (p3.y - p2.y).toDouble();

    double dotProduct = v1x * v2x + v1y * v2y;
    double mag1 = sqrt(v1x * v1x + v1y * v1y);
    double mag2 = sqrt(v2x * v2x + v2y * v2y);

    double cosAngle = dotProduct / (mag1 * mag2);
    cosAngle = cosAngle.clamp(-1.0, 1.0);
    double angleRadians = acos(cosAngle);
    double angleDegrees = angleRadians * 180 / pi;

    return angleDegrees;
  }

  /// Clean up resources
  static void dispose() {
    _faceDetector.close();
  }
}

// Usage Example:
/*
// How to use the FaceMatchingService:

Future<void> compareTwoImages(XFile image1, XFile image2) async {
  final result = await FaceMatchingService.matchFaces(image1, image2);

  if (result['success']) {
    if (result['isMatch']) {
      print('Faces match with ${result['similarityScore']} confidence!');
      print('Message: ${result['message']}');
    } else {
      print('Faces do not match: ${result['message']}');
    }
  } else {
    print('Error: ${result['message']}');
  }
}

// Example with your downloadImageToFile function:
Future<void> compareDownloadedImages(String url1, String url2) async {
  XFile? image1 = await downloadImageToFile(url1);
  XFile? image2 = await downloadImageToFile(url2);

  if (image1 != null && image2 != null) {
    final result = await FaceMatchingService.matchFaces(image1, image2);

    print('Match result: ${result['isMatch']}');
    print('Similarity: ${(result['similarityScore'] * 100).toStringAsFixed(1)}%');
  }
}
*/