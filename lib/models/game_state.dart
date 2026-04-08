import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ShapeType { circle, triangle, square, star }

extension ShapeTypeExtension on ShapeType {
  String get name {
    switch (this) {
      case ShapeType.circle:
        return 'CIRCLE';
      case ShapeType.triangle:
        return 'TRIANGLE';
      case ShapeType.square:
        return 'SQUARE';
      case ShapeType.star:
        return 'STAR';
    }
  }

  String get emoji {
    switch (this) {
      case ShapeType.circle:
        return '⬤';
      case ShapeType.triangle:
        return '▲';
      case ShapeType.square:
        return '■';
      case ShapeType.star:
        return '★';
    }
  }
}

enum GamePhase { idle, playing, morphing, dead }

class GameState extends ChangeNotifier {
  GamePhase phase = GamePhase.idle;
  ShapeType currentShape = ShapeType.circle;
  int score = 0;
  int highScore = 0;
  int lives = 3;
  double speed = 1.0;
  int wallsPassed = 0;
  bool isPaused = false;
  bool isMorphing = false;

  GameState() {
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0;
    notifyListeners();
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  void startGame() {
    phase = GamePhase.playing;
    score = 0;
    lives = 3;
    speed = 1.0;
    wallsPassed = 0;
    currentShape = ShapeType.circle;
    isPaused = false;
    isMorphing = false;
    notifyListeners();
  }

  void morphTo(ShapeType shape) {
    if (isMorphing || phase != GamePhase.playing) return;
    isMorphing = true;
    currentShape = shape;
    phase = GamePhase.morphing;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 300), () {
      isMorphing = false;
      phase = GamePhase.playing;
      notifyListeners();
    });
  }

  void onWallPassed() {
    wallsPassed++;
    score += 10 + (speed * 5).toInt();
    if (wallsPassed % 5 == 0) {
      speed = (speed + 0.15).clamp(1.0, 3.5);
    }
    notifyListeners();
  }

  void onHit() {
    lives--;
    if (lives <= 0) {
      _gameOver();
    } else {
      notifyListeners();
    }
  }

  void _gameOver() {
    phase = GamePhase.dead;
    if (score > highScore) {
      highScore = score;
      _saveHighScore();
    }
    notifyListeners();
  }

  void togglePause() {
    if (phase == GamePhase.playing || phase == GamePhase.morphing) {
      isPaused = !isPaused;
      notifyListeners();
    }
  }

  void resetToHome() {
    phase = GamePhase.idle;
    notifyListeners();
  }
}
