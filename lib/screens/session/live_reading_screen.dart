import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class LiveReadingScreen extends StatefulWidget {
  final String? patientName;

  const LiveReadingScreen({super.key, this.patientName});

  @override
  State<LiveReadingScreen> createState() => _LiveReadingScreenState();
}

class _LiveReadingScreenState extends State<LiveReadingScreen> {
  bool _isPaused = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  int _steps = 0;
  int _cadence = 0;
  double _currentAngle = 0.0;
  int _mobilityScore = 85;
  final List<double> _angleHistory = List.filled(50, 0.0);

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          _secondsElapsed++;
          _currentAngle = 45.0 + (30.0 * sin(_secondsElapsed.toDouble()));
          _angleHistory.removeAt(0);
          _angleHistory.add(_currentAngle);
          if (_secondsElapsed % 2 == 0) _steps++;
          final mins = _secondsElapsed / 60;
          _cadence = mins > 0 ? (_steps / mins).round() : 0;
          _mobilityScore = 80 + Random().nextInt(10);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color statusColor = _isPaused
        ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
        : theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientName ?? 'Live Session',
          style: const TextStyle(letterSpacing: 1),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Timer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(
                    _formatDuration(_secondsElapsed),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 68,
                      fontWeight: FontWeight.w900,
                      color: _isPaused
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isPaused)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                        Text(
                          _isPaused ? 'PAUSED' : 'LIVE',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Graph
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, double.infinity),
                      painter: _GraphPainter(
                        _angleHistory,
                        theme.colorScheme.primary,
                        theme.colorScheme.surface,
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Text(
                        'KNEE FLEXION',
                        style: theme.textTheme.bodySmall?.copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _currentAngle.abs().toStringAsFixed(1),
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '°',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Metrics grid
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.55,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _metricCard('STEPS', '$_steps', 'total'),
                    _metricCard('CADENCE', '$_cadence', 'steps/min'),
                    _metricCard('MAX FLEX', '78.5°', 'peak'),
                    _metricCard(
                      'MOBILITY',
                      '$_mobilityScore',
                      'score',
                      highlight: true,
                    ),
                  ],
                ),
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isPaused = !_isPaused),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPaused ? 'RESUME' : 'PAUSE',
                            style: const TextStyle(letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _timer?.cancel();
                        Navigator.pushReplacementNamed(
                          context,
                          '/session_summary',
                          arguments: {
                            'steps': _steps,
                            'duration': _secondsElapsed,
                            'cadence': _cadence,
                            'score': _mobilityScore,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop_rounded),
                          SizedBox(width: 8),
                          Text('END', style: TextStyle(letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
    String title,
    String value,
    String unit, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? theme.colorScheme.secondary.withValues(alpha: 0.35)
              : theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: highlight
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color surfaceColor;

  _GraphPainter(this.data, this.lineColor, this.surfaceColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height * (1.0 - (data[i] / 100.0).clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY =
            size.height * (1.0 - (data[i - 1] / 100.0).clamp(0.0, 1.0));
        path.cubicTo(
          prevX + (x - prevX) / 2,
          prevY,
          prevX + (x - prevX) / 2,
          y,
          x,
          y,
        );
      }
    }

    canvas.drawShadow(path, lineColor, 10.0, true);
    canvas.drawPath(path, paint);

    // Gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.18),
          surfaceColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => true;
}
