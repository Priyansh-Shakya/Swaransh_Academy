import 'package:audioplayers/audioplayers.dart';

class AppSounds {
  AppSounds._();
  static final AudioPlayer player = AudioPlayer();
  static Future<void> playApproveSound() async {
    await player.play(AssetSource('success.mp3'));
  }

  static Future<void> playDeclineSound() async {
    await player.play(AssetSource('failure.mp3'));
  }

  static Future<void> playDeleteSound() async {
    await player.play(AssetSource('delete.mp3'));
  }
}
