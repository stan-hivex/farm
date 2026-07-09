import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

import '/app_state.dart';

class NotificationFeedbackService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> trigger() async {
    final soundEnabled = FFAppState().notificationSoundEnabled;
    final vibrationEnabled = FFAppState().notificationVibrationEnabled;

    if (soundEnabled) {
      try {
        await _player.play(
          AssetSource('audios/notification.wav'),
          volume: 1.0,
          mode: PlayerMode.lowLatency,
        );
      } catch (e) {
        debugPrint('Notification sound failed: $e');
      }
    }

    if (vibrationEnabled) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          await Vibration.vibrate(duration: 250);
        }
      } catch (e) {
        debugPrint('Notification vibration failed: $e');
      }
    }
  }
}
