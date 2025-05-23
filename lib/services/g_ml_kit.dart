import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// A service class for matching two face images using Google ML Kit
class FaceMatchingService {
  // Create face detector with high-accuracy settings
  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    ),
  );

  // Matching thresholds - Adjusted for better flexibility
  static const double SIMILARITY_THRESHOLD = 0.85; // Reduced from 0.92
  static const double HIGH_CONFIDENCE_THRESHOLD = 0.92; // Reduced from 0.95
  static const double ANGLE_THRESHOLD = 12.0; // Increased from 7.0
  static const double EYE_RATIO_MIN = 0.80; // More flexible from 0.87
  static const double EYE_RATIO_MAX = 1.25; // More flexible from 1.13
  static const int MIN_LANDMARKS = 4; // Reduced from 5

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

      // Convert XFiles to temporary paths
      final String imagePath1 = await _xFileToTempPath(image1);
      final String imagePath2 = await _xFileToTempPath(image2);


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
        print('Error deleting temporary files: $e');
      }


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
  }

  /// Check face quality with more flexible requirements
  static bool _isFaceQualityGood(Face face) {
    // Must have most key landmarks (relaxed requirement)
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
      }
    }

    if (foundLandmarks < MIN_LANDMARKS) {
      return false;
    }

    // More flexible head rotation check
    if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 25) { // Increased from 15
      return false;
    }

    if (face.headEulerAngleZ != null && face.headEulerAngleZ!.abs() > 25) { // Increased from 15
      return false;
    }

    // More flexible eye openness check
    if (face.leftEyeOpenProbability != null && face.leftEyeOpenProbability! < 0.4) { // Reduced from 0.6
      return false;
    }

    if (face.rightEyeOpenProbability != null && face.rightEyeOpenProbability! < 0.4) { // Reduced from 0.6
      return false;
    }

    // More flexible face size check
    final boundingBox = face.boundingBox;
    if (boundingBox.width < 100 || boundingBox.height < 100) { // Reduced from 150
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

    // Get key facial landmarks - handle missing landmarks gracefully
    Point<int>? detectedNose = detectedFace.landmarks[FaceLandmarkType.noseBase]?.position;
    Point<int>? referenceNose = referenceFace.landmarks[FaceLandmarkType.noseBase]?.position;
    Point<int>? detectedLeftEye = detectedFace.landmarks[FaceLandmarkType.leftEye]?.position;
    Point<int>? referenceLeftEye = referenceFace.landmarks[FaceLandmarkType.leftEye]?.position;
    Point<int>? detectedRightEye = detectedFace.landmarks[FaceLandmarkType.rightEye]?.position;
    Point<int>? referenceRightEye = referenceFace.landmarks[FaceLandmarkType.rightEye]?.position;
    Point<int>? detectedLeftMouth = detectedFace.landmarks[FaceLandmarkType.leftMouth]?.position;
    Point<int>? referenceLeftMouth = referenceFace.landmarks[FaceLandmarkType.leftMouth]?.position;
    Point<int>? detectedRightMouth = detectedFace.landmarks[FaceLandmarkType.rightMouth]?.position;
    Point<int>? referenceRightMouth = referenceFace.landmarks[FaceLandmarkType.rightMouth]?.position;

    // Must have eyes for basic comparison
    if (detectedLeftEye == null || referenceLeftEye == null ||
        detectedRightEye == null || referenceRightEye == null) {
      return result;
    }

    try {
      // Calculate distances between facial landmarks
      final double detectedEyeDistance = _distance(detectedLeftEye, detectedRightEye);
      final double referenceEyeDistance = _distance(referenceLeftEye, referenceRightEye);

      // Calculate ratio between eyes
      final double eyeRatio = detectedEyeDistance / referenceEyeDistance;
      result['details']['eyeRatio'] = eyeRatio;

      // More flexible eye ratio check
      if (eyeRatio < EYE_RATIO_MIN || eyeRatio > EYE_RATIO_MAX) {
        // Don't return immediately, but penalize the score
        result['details']['eyeRatioWarning'] = true;
      }

      // Calculate normalized distances and similarities
      Map<String, double> similarities = {};

      // Eye-to-nose relationships (if nose landmarks available)
      if (detectedNose != null && referenceNose != null) {
        final double detectedLeftEyeToNose = _distance(detectedLeftEye, detectedNose) / detectedEyeDistance;
        final double referenceLeftEyeToNose = _distance(referenceLeftEye, referenceNose) / referenceEyeDistance;
        similarities['leftEyeToNoseRatio'] = 1 - (detectedLeftEyeToNose - referenceLeftEyeToNose).abs();

        final double detectedRightEyeToNose = _distance(detectedRightEye, detectedNose) / detectedEyeDistance;
        final double referenceRightEyeToNose = _distance(referenceRightEye, referenceNose) / referenceEyeDistance;
        similarities['rightEyeToNoseRatio'] = 1 - (detectedRightEyeToNose - referenceRightEyeToNose).abs();

        // Face angle analysis (if nose available)
        final double detectedEyeNoseEyeAngle = _calculateAngle(detectedLeftEye, detectedNose, detectedRightEye);
        final double referenceEyeNoseEyeAngle = _calculateAngle(referenceLeftEye, referenceNose, referenceRightEye);
        final double eyeNoseEyeAngleDiff = (detectedEyeNoseEyeAngle - referenceEyeNoseEyeAngle).abs();

        if (eyeNoseEyeAngleDiff > 15.0) { // More flexible from 7.0
          result['details']['angleWarning'] = true;
        }

        similarities['eyeNoseEyeAngle'] = 1 - (eyeNoseEyeAngleDiff / 180);
      }

      // Eye-to-eye ratio (always calculate this)
      similarities['eyeToEyeRatio'] = 1 - min((eyeRatio - 1).abs(), 0.4); // More flexible

      // Mouth measurements (if mouth landmarks available)
      if (detectedLeftMouth != null && referenceLeftMouth != null &&
          detectedRightMouth != null && referenceRightMouth != null) {

        // Mouth width ratio
        final double detectedMouthWidth = _distance(detectedLeftMouth, detectedRightMouth) / detectedEyeDistance;
        final double referenceMouthWidth = _distance(referenceLeftMouth, referenceRightMouth) / referenceEyeDistance;
        similarities['mouthWidthRatio'] = 1 - min((detectedMouthWidth - referenceMouthWidth).abs(), 0.4); // More flexible

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
        similarities['eyeToMouthRatio'] = 1 - min((detectedEyeToMouthDist - referenceEyeToMouthDist).abs(), 0.4); // More flexible

        // Cross-face diagonal ratios
        final double detectedLeftEyeToRightMouth = _distance(detectedLeftEye, detectedRightMouth) / detectedEyeDistance;
        final double referenceLeftEyeToRightMouth = _distance(referenceLeftEye, referenceRightMouth) / referenceEyeDistance;
        similarities['leftEyeToRightMouthRatio'] = 1 - min((detectedLeftEyeToRightMouth - referenceLeftEyeToRightMouth).abs(), 0.4); // More flexible

        final double detectedRightEyeToLeftMouth = _distance(detectedRightEye, detectedLeftMouth) / detectedEyeDistance;
        final double referenceRightEyeToLeftMouth = _distance(referenceRightEye, referenceLeftMouth) / referenceEyeDistance;
        similarities['rightEyeToLeftMouthRatio'] = 1 - min((detectedRightEyeToLeftMouth - referenceRightEyeToLeftMouth).abs(), 0.4); // More flexible
      }

      // Log similarity scores
      similarities.forEach((key, value) {
      });

      // Calculate weighted average similarity with adjusted weights
      Map<String, double> weights = {
        'leftEyeToNoseRatio': 1.2, // Reduced weight
        'rightEyeToNoseRatio': 1.2, // Reduced weight
        'eyeToEyeRatio': 1.5, // Increased importance of eye distance
        'eyeNoseEyeAngle': 1.5, // Reduced from 2.0
        'mouthWidthRatio': 0.8, // Reduced weight
        'eyeToMouthRatio': 1.3, // Reduced weight
        'leftEyeToRightMouthRatio': 1.0, // Reduced weight
        'rightEyeToLeftMouthRatio': 1.0, // Reduced weight
      };

      double totalWeight = 0;
      double weightedSum = 0;
      int validFeatures = 0;
      Map<String, bool> failedFeatures = {};

      similarities.forEach((key, value) {
        if (value.isNaN || value.isInfinite) {
          return;
        }

        // More lenient threshold for failed features
        if (value < 0.65) { // Reduced from 0.75
          failedFeatures[key] = true;
        }

        double weight = weights[key] ?? 1.0;
        weightedSum += value * weight;
        totalWeight += weight;
        validFeatures++;
      });

      result['details']['failedFeatures'] = failedFeatures;

      if (validFeatures < 2) { // Reduced minimum requirement
        return result;
      }

      // More lenient failed features threshold
      if (failedFeatures.length > 4) { // Increased from 3
        // Don't return immediately, but apply penalty
        result['details']['highFailureWarning'] = true;
      }

      // Final similarity score
      double similarityScore = totalWeight > 0 ? weightedSum / totalWeight : 0;
      result['similarityScore'] = similarityScore;
      result['details']['similarities'] = similarities;


      // Determine match based on threshold
      if (similarityScore >= SIMILARITY_THRESHOLD) {
        if (similarityScore >= HIGH_CONFIDENCE_THRESHOLD) {
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
        }
      }

      return result;
    } catch (e) {
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