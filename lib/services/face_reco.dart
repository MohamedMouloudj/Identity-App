/*
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_face_api/flutter_face_api.dart';
import 'package:image_picker/image_picker.dart';

class FaceRecognition extends StatefulWidget {
  const FaceRecognition({Key? key}) : super(key: key);

  @override
  State<FaceRecognition> createState() => _FaceRecognitionState();
}

class _FaceRecognitionState extends State<FaceRecognition> {
  final FaceSDK faceSdk = FaceSDK.instance;

  String _status = "Ready";
  String _similarityStatus = "nil";
  String _livenessStatus = "nil";

  MatchFacesImage? mfImage1;
  MatchFacesImage? mfImage2;

  @override
  void initState() {
    super.initState();
    _initializeFaceSDK();
  }

  // Initialize the Face SDK
  Future<void> _initializeFaceSDK() async {
    setState(() {
      _status = "Initializing...";
    });

    Future<ByteData?> _loadAssetIfExists(String path) async {
      try {
        return await rootBundle.load(path);
      } catch (e) {
        return null;
      }
    }
    try {
      // Try to load license if it exists
      ByteData? license = await _loadAssetIfExists("assets/regula.license");
      InitConfig? config;
      if (license != null) {
        config = InitConfig(license);
      }

      var (success, error) = await faceSdk.initialize(config: config);

      if (success) {
        setState(() {
          _status = "Ready";
        });
      } else {
        setState(() {
          _status = error?.message ?? "Initialization failed";
        });
        print("${error?.code}: ${error?.message}");
      }
    } catch (e) {
      setState(() {
        _status = "Initialization error: $e";
      });
    }
  }

  // Load asset file if it exists
  Future<String?> _loadAssetIfExists(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      return null;
    }
  }

  // Convert XFile to MatchFacesImage
  Future<MatchFacesImage?> _xFileToMatchFacesImage(XFile xFile) async {
    try {
      final bytes = await File(xFile.path).readAsBytes();
      return MatchFacesImage(bytes, ImageType.PRINTED);
    } catch (e) {
      print("Error converting XFile to MatchFacesImage: $e");
      return null;
    }
  }

  // Set image from XFile
  Future<void> setImageFromXFile(XFile xFile, int imageNumber) async {
    final matchFacesImage = await _xFileToMatchFacesImage(xFile);
    if (matchFacesImage != null) {
      setState(() {
        if (imageNumber == 1) {
          mfImage1 = matchFacesImage;
        } else if (imageNumber == 2) {
          mfImage2 = matchFacesImage;
        }
      });
    }
  }

  // Match two faces
  Future<void> matchFaces() async {
    if (mfImage1 == null || mfImage2 == null) {
      setState(() {
        _status = "Both images required!";
      });
      return;
    }

    setState(() {
      _status = "Processing...";
      _similarityStatus = "Processing...";
    });

    try {
      final request = MatchFacesRequest([mfImage1!, mfImage2!]);
      final response = await faceSdk.matchFaces(request);
      final split = await faceSdk.splitComparedFaces(response.results, 0.75);
      final matchedFaces = split.matchedFaces;

      setState(() {
        if (matchedFaces.isNotEmpty) {
          final similarity = (matchedFaces[0].similarity * 100).toStringAsFixed(2);
          _similarityStatus = "$similarity%";
        } else {
          _similarityStatus = "No match found";
        }
        _status = "Matching completed";
      });
    } catch (e) {
      setState(() {
        _status = "Error during matching: $e";
        _similarityStatus = "Error";
      });
      print("Match faces error: $e");
    }
  }

  // Start liveness detection
  Future<void> startLiveness() async {
    try {
      final result = await faceSdk.startLiveness(
        config: LivenessConfig(skipStep: [LivenessSkipStep.ONBOARDING_STEP]),
        notificationCompletion: (notification) {
          print("Liveness notification: ${notification.status}");
        },
      );

      if (result.image != null) {
        final matchFacesImage = MatchFacesImage(result.image!, ImageType.LIVE);
        setState(() {
          mfImage1 = matchFacesImage;
          _livenessStatus = result.liveness.name.toLowerCase();
        });
      }
    } catch (e) {
      setState(() {
        _livenessStatus = "Error: $e";
      });
      print("Liveness error: $e");
    }
  }

  // Clear all results
  void clearResults() {
    setState(() {
      _status = "Ready";
      _similarityStatus = "nil";
      _livenessStatus = "nil";
      mfImage1 = null;
      mfImage2 = null;
    });
  }

  // Check if faces match with a threshold
  bool doFacesMatch({double threshold = 0.75}) {
    if (_similarityStatus == "nil" || _similarityStatus.contains("Error")) {
      return false;
    }

    try {
      final similarity = double.parse(_similarityStatus.replaceAll('%', '')) / 100;
      return similarity >= threshold;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $_status',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Similarity: $_similarityStatus',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Liveness: $_livenessStatus',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Images Preview (if you want to show them)
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: mfImage1 != null
                            ? const Center(child: Text('Image 1 Loaded'))
                            : const Center(child: Text('No Image 1')),
                      ),
                      const SizedBox(height: 8),
                      const Text('Image 1', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: mfImage2 != null
                            ? const Center(child: Text('Image 2 Loaded'))
                            : const Center(child: Text('No Image 2')),
                      ),
                      const SizedBox(height: 8),
                      const Text('Image 2', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            ElevatedButton(
              onPressed: matchFaces,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Match Faces',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: startLiveness,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Start Liveness Detection',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: clearResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Clear Results',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 20),

            // Match Result
            if (_similarityStatus != "nil" && !_similarityStatus.contains("Error"))
              Card(
                color: doFacesMatch() ? Colors.green.shade100 : Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    doFacesMatch()
                        ? 'FACES MATCH! ✓'
                        : 'FACES DO NOT MATCH ✗',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: doFacesMatch() ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Usage example:
// To use this widget with your XFile images, call:
// await faceRecognitionState.setImageFromXFile(xFile1, 1);
// await faceRecognitionState.setImageFromXFile(xFile2, 2);
// await faceRecognitionState.matchFaces();*/
