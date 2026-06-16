import 'package:flutter/services.dart';

class SoundManager {
  static const MethodChannel _soundChannel = MethodChannel('turf.app/sfx');

  /// Internal channel invoker passing the sound action identifier
  static Future<void> _playSfx(String name) async {
    try {
      await _soundChannel.invokeMethod('playSfx', {'name': name});
    } catch (e) {
      // Fail silently in environments where native methods are mocked/unavailable
      print("Failed to play sound: $e");
    }
  }

  /// Plays the default button tap click sound
  static Future<void> playButtonClick() => _playSfx('button_click');

  /// Plays the start walk sound
  static Future<void> playStartWalk() => _playSfx('start_walk');

  /// Plays the end walk sound
  static Future<void> playEndWalk() => _playSfx('end_walk');

  /// Plays the login success sound
  static Future<void> playLogin() => _playSfx('login');

  /// Plays the logout sound
  static Future<void> playLogout() => _playSfx('logout');

  /// Plays the map recenter sound
  static Future<void> playRecenter() => _playSfx('recenter');

  /// Plays the delete history sound
  static Future<void> playDeleteHistory() => _playSfx('delete_history');
}
