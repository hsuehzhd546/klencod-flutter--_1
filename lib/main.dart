import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const BallGame());

class BallGame extends StatelessWidget {
  const BallGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  int level = 1;
  int maxLevel = 10;

  double ballX = 0;
  double ballY = 0;
  double velocityX = 0;
  double velocityY = 0;

  double holeX = 0.75;
  double holeY = 0.15;

  double wind = 0;
  double friction = 0.985;

  bool moving = false;
  bool dragging = false;
  bool won = false;
  bool lost = false;

  Offset dragStart = Offset.zero;
  Offset dragCurrent = Offset.zero;

  Size gameSize = Size.zero;

  final List<Offset> obstacles = [];

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(updateGame);

    controller.repeat();

    setupLevel();
  }

  void setupLevel() {
    ballX = 0.15;
    ballY = 0.85;

    velocityX = 0;
    velocityY = 0;

    moving = false;
    dragging = false;
    won = false;
    lost = false;

    wind = level >= 4 ? (level.isEven ? 0.015 : -0.015) * (level - 3) : 0;

    friction = level >= 7 ? 0.975 : 0.985;

    holeX = 0.78 - (level % 3) * 0.06;
    holeY = 0.16 + (level % 4) * 0.08;

    obstacles.clear();

    if (level >= 3) {
      obstacles.add(Offset(0.5, 0.5));
    }

    if (level >= 5) {
      obstacles.add(Offset(0.35, 0.3));
      obstacles.add(Offset(0.65, 0.7));
    }

    if (level >= 8) {
      obstacles.add(Offset(0.5, 0.2));
      obstacles.add(Offset(0.5, 0.8));
    }

    setState(() {});
  }

  void updateGame() {
    if (!moving || won || lost || gameSize == Size.zero) return;

    const ballRadius = 12.0;

    ballX += velocityX;
    ballY += velocityY;

    velocityX += wind;

    velocityX *= friction;
    velocityY *= friction;

    // الكرة تصطدم بحواف الملعب
    if (ballX < 0.03 || ballX > 0.97 ||
        ballY < 0.03 || ballY > 0.97) {
      loseGame();
      return;
    }

    // الحواجز
    for (final obstacle in obstacles) {
      final dx = ballX - obstacle.dx;
      final dy = ballY - obstacle.dy;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance < 0.075) {
        loseGame();
        return;
      }
    }

    // منطقة الرمل: تقلل سرعة الكرة
    if (level >= 6 &&
        ballX > 0.35 && ballX < 0.65 &&
        ballY > 0.35 && ballY < 0.65) {
      velocityX *= 0.94;
      velocityY *= 0.94;
    }

    // فحص دخول الحفرة
    final dx = ballX - holeX;
    final dy = ballY - holeY;

    if (sqrt(dx * dx + dy * dy) < 0.055) {
      winGame();
      return;
    }

    setState(() {});
  }

  void loseGame() {
    moving = false;
    lost = true;
    setState(() {});
  }

  void winGame() {
    moving = false;
    won = true;
    setState(() {});
  }

  void nextLevel() {
    if (level < maxLevel) {
      level++;
      setupLevel();
    } else {
      setState(() {});
    }
  }

  void restartLevel() {
    setupLevel();
  }

  void startDrag(Offset position) {
    if (moving || won || lost) return;

    dragging = true;
    dragStart = position;
    dragCurrent = position;

    setState(() {});
  }

  void updateDrag(Offset position) {
    if (!dragging) return;

    dragCurrent = position;

    setState(() {});
  }

  void endDrag() {
    if (!dragging) return;

    final difference = dragStart - dragCurrent;

    velocityX = difference.dx / gameSize.width * 0.65;
    velocityY = difference.dy / gameSize.height * 0.65;

    // تحديد قوة الضربة
    final speed = sqrt(velocityX * velocityX + velocityY * velocityY);

    if (speed > 0.035) {
      final scale = 0.035 / speed;
      velocityX *= scale;
      velocityY *= scale;
    }

    dragging = false;
    moving = true;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      body: SafeArea(
        child: Column(
          children: [
            // لوحة معلومات اللعبة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BALL HOLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'المرحلة $level / $maxLevel',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  gameSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return GestureDetector(
                    onPanStart: (details) =>
                        startDrag(details.localPosition),
                    onPanUpdate: (details) =>
                        updateDrag(details.localPosition),
                    onPanEnd: (_) => endDrag(),
                    child: CustomPaint(
                      size: gameSize,
                      painter: GamePainter(
                        ballX: ballX,
                        ballY: ballY,
                        holeX: holeX,
                        holeY: holeY,
                        obstacles: obstacles,
                        level: level,
                        dragging: dragging,
                        dragStart: dragStart,
                        dragCurrent: dragCurrent,
                        wind: wind,
                      ),
                    ),
                  );
                },
              ),
            ),

            // معلومات التحكم
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                lost
                    ? '💥 خسرت! حاول مرة ثانية'
                    : won
                        ? level == maxLevel
                            ? '🏆 أكملت كل المراحل!'
                            : '🎉 ممتاز! المرحلة التالية'
                        : moving
                            ? '⚽ الكرة تتحرك!'
                            : 'اسحب إصبعك للخلف ثم اتركه 🚀',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),

            if (lost)
              ElevatedButton(
                onPressed: restartLevel,
                child: const Text('إعادة المرحلة'),
              ),

            if (won && level < maxLevel)
              ElevatedButton(
                onPressed: nextLevel,
                child: const Text('المرحلة التالية'),
              ),

            if (won && level == maxLevel)
              ElevatedButton(
                onPressed: () {
                  level = 1;
                  setupLevel();
                },
                child: const Text('العب من جديد'),
              ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// رسم الملعب والكرة والحواجز
class GamePainter extends CustomPainter {
  final double ballX;
  final double ballY;
  final double holeX;
  final double holeY;
  final List<Offset> obstacles;
  final int level;
  final bool dragging;
  final Offset dragStart;
  final Offset dragCurrent;
  final double wind;

  GamePainter({
    required this.ballX,
    required this.ballY,
    required this.holeX,
    required this.holeY,
    required this.obstacles,
    required this.level,
    required this.dragging,
    required this.dragStart,
    required this.dragCurrent,
    required this.wind,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // أرضية اللعبة
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFF263D32),
    );

    // حدود الملعب
    final border = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawRect(
      Rect.fromLTWH(
        8, 8,
        size.width - 16,
        size.height - 16,
      ),
      border,
    );

    // خطوط الأرض
    final lines = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 35) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lines);
    }

    for (double y = 0; y < size.height; y += 35) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lines);
    }

    // منطقة الرمل في المراحل المتقدمة
    if (level >= 6) {
      final sand = Paint()..color = const Color(0xFFB99B60);

      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.35,
          size.height * 0.35,
          size.width * 0.30,
          size.height * 0.30,
        ),
        sand,
      );
    }

    // الحفرة
    final holePosition = Offset(
      holeX * size.width,
      holeY * size.height,
    );

    canvas.drawCircle(
      holePosition,
      23,
      Paint()..color = Colors.black,
    );

    canvas.drawCircle(
      holePosition,
      25,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // الحواجز
    for (final obstacle in obstacles) {
      final position = Offset(
        obstacle.dx * size.width,
        obstacle.dy * size.height,
      );

      canvas.drawCircle(
        position,
        25,
        Paint()..color = Colors.redAccent,
      );

      canvas.drawCircle(
        position,
        25,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // رسم مسار الضربة
    if (dragging) {
      final start = Offset(
        ballX * size.width,
        ballY * size.height,
      );

      final end = start + (dragStart - dragCurrent);

      final aimPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawLine(start, end, aimPaint);

      canvas.drawCircle(
        end,
        6,
        Paint()..color = Colors.amber,
      );
    }

    // الكرة
    final ballPosition = Offset(
      ballX * size.width,
      ballY * size.height,
    );

    canvas.drawCircle(
      ballPosition + const Offset(3, 4),
      13,
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    canvas.drawCircle(
      ballPosition,
      12,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      ballPosition,
      12,
      Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      ballPosition + const Offset(-3, -3),
      3,
      Paint()..color = Colors.white,
    );

    // مؤشر الرياح
    if (wind != 0) {
      final windPaint = Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 3;

      final direction = wind > 0 ? 1.0 : -1.0;

      for (int i = 0; i < 3; i++) {
        final y = 45.0 + i * 25;

        canvas.drawLine(
          Offset(30, y),
          Offset(30 + direction * 35, y),
          windPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}