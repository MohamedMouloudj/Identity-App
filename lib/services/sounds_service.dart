import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';

Future<void> playSuccessSound() async {
  try {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/success.mp3'));
  } catch (e) {
    debugPrint('Error playing sound: $e');
  }
}