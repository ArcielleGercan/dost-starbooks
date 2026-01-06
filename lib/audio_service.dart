import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  bool _isInitialized = false;

  // Current playing music type
  String? _currentMusic;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Preload all audio files
      await FlameAudio.audioCache.loadAll([
        'homepage_music.mp3',
        'click1.wav',
        'dialogue.mp3',
        'matchpuzzle.mp3',
        'quiz_music.mp3',
        'battle.mp3',
      ]);
      _isInitialized = true;
      debugPrint('✅ Audio service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing audio: $e');
    }
  }

  // Background Music Methods
  Future<void> playHomepageMusic() async {
    if (!_isMusicEnabled || _currentMusic == 'homepage') return;

    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play('homepage_music.mp3', volume: 0.3);
      _currentMusic = 'homepage';
      debugPrint('🎵 Playing homepage music');
    } catch (e) {
      debugPrint('❌ Error playing homepage music: $e');
    }
  }

  Future<void> playQuizMusic() async {
    if (!_isMusicEnabled || _currentMusic == 'quiz') return;

    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play('quiz_music.mp3', volume: 0.2);
      _currentMusic = 'quiz';
      debugPrint('🎵 Playing quiz music');
    } catch (e) {
      debugPrint('❌ Error playing quiz music: $e');
    }
  }

  Future<void> playBattleMusic() async {
    if (!_isMusicEnabled || _currentMusic == 'battle') return;

    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play('battle.mp3', volume: 0.25);
      _currentMusic = 'battle';
      debugPrint('🎵 Playing battle music');
    } catch (e) {
      debugPrint('❌ Error playing battle music: $e');
    }
  }

  Future<void> playMatchPuzzleMusic() async {
    if (!_isMusicEnabled || _currentMusic == 'matchpuzzle') return;

    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play('matchpuzzle.mp3', volume: 0.25);
      _currentMusic = 'matchpuzzle';
      debugPrint('🎵 Playing match/puzzle music');
    } catch (e) {
      debugPrint('❌ Error playing match/puzzle music: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
      _currentMusic = null;
      debugPrint('🛑 Music stopped');
    } catch (e) {
      debugPrint('❌ Error stopping music: $e');
    }
  }

  Future<void> pauseMusic() async {
    try {
      FlameAudio.bgm.pause();
      debugPrint('⏸️ Music paused');
    } catch (e) {
      debugPrint('❌ Error pausing music: $e');
    }
  }

  Future<void> resumeMusic() async {
    if (!_isMusicEnabled) return;

    try {
      FlameAudio.bgm.resume();
      debugPrint('▶️ Music resumed');
    } catch (e) {
      debugPrint('❌ Error resuming music: $e');
    }
  }

  // Sound Effects Methods
  Future<void> playClickSound() async {
    if (!_isSfxEnabled) return;

    try {
      await FlameAudio.play('click1.wav', volume: 0.5);
    } catch (e) {
      debugPrint('❌ Error playing click sound: $e');
    }
  }

  Future<void> playDialogueSound() async {
    if (!_isSfxEnabled) return;

    try {
      await FlameAudio.play('dialogue.mp3', volume: 0.4);
    } catch (e) {
      debugPrint('❌ Error playing dialogue sound: $e');
    }
  }

  // Settings
  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    if (!_isMusicEnabled) {
      stopMusic();
    }
    debugPrint('🎵 Music ${_isMusicEnabled ? "enabled" : "disabled"}');
  }

  void toggleSfx() {
    _isSfxEnabled = !_isSfxEnabled;
    debugPrint('🔊 SFX ${_isSfxEnabled ? "enabled" : "disabled"}');
  }

  void setMusicVolume(double volume) {
    FlameAudio.bgm.audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  // Getters
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  String? get currentMusic => _currentMusic;
}