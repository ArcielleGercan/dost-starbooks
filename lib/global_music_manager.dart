import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

class GlobalMusicManager {
  static final GlobalMusicManager _instance = GlobalMusicManager._internal();

  factory GlobalMusicManager() {
    return _instance;
  }

  GlobalMusicManager._internal();

  bool _isPlaying = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await FlameAudio.audioCache.load('homepage_music.mp3');
      _isInitialized = true;
      debugPrint('✅ Music initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing music: $e');
    }
  }

  Future<void> startHomepageMusic() async {
    if (_isPlaying) {
      debugPrint('🎵 Music already playing');
      return;
    }

    try {
      await FlameAudio.bgm.play('homepage_music.mp3', volume: 0.3);
      _isPlaying = true;
      debugPrint('🎵 Homepage music started');
    } catch (e) {
      debugPrint('❌ Error starting music: $e');
    }
  }

  // ✅ FIXED - Added actual stop implementation
  Future<void> stopMusic() async {
    if (!_isPlaying) return;

    try {
      await FlameAudio.bgm.stop();
      _isPlaying = false;
      debugPrint('🛑 Music stopped');
    } catch (e) {
      debugPrint('❌ Error stopping music: $e');
    }
  }

  Future<void> pauseMusic() async {
    if (!_isPlaying) return;

    try {
      FlameAudio.bgm.pause();
      debugPrint('⏸️ Music paused');
    } catch (e) {
      debugPrint('❌ Error pausing music: $e');
    }
  }

  Future<void> resumeMusic() async {
    if (!_isPlaying) return;

    try {
      FlameAudio.bgm.resume();
      debugPrint('▶️ Music resumed');
    } catch (e) {
      debugPrint('❌ Error resuming music: $e');
    }
  }

  bool get isPlaying => _isPlaying;
}