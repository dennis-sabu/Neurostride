import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/voice_coach_provider.dart';

class LiveExerciseScreen extends ConsumerStatefulWidget {
  const LiveExerciseScreen({super.key});

  @override
  ConsumerState<LiveExerciseScreen> createState() => _LiveExerciseScreenState();
}

class _LiveExerciseScreenState extends ConsumerState<LiveExerciseScreen> {
  void _endSession() {
    final notifier = ref.read(exerciseSessionProvider.notifier);
    final result = notifier.calculateFinalResult();
    notifier.stopExercise();
    Navigator.pushReplacementNamed(
      context,
      '/exercise_result',
      arguments: result,
    );
  }

  void _confirmEnd() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'End Session?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your progress will be saved.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _endSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('End & Save'),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
              SizedBox(width: 10),
              Text(
                'Sensor Disconnected',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'The sensor connection was lost during the exercise.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _endSession();
              },
              child: const Text(
                'End Session',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/bluetooth_connect');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Reconnect'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BluetoothState>(bluetoothProvider, (prev, next) {
      if (prev?.status == BluetoothConnectionStatus.connected &&
          next.status == BluetoothConnectionStatus.disconnected) {
        ref.read(exerciseSessionProvider.notifier).pauseExercise();
        _showDisconnectDialog();
      }
    });

    final exerciseName = ref.watch(
      exerciseSessionProvider.select((s) => s.currentExercise.name),
    );
    final repProgress = ref.watch(
      exerciseSessionProvider.select(
        (s) => '${s.completedReps} / ${s.totalReps} reps',
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmEnd();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Text(
                exerciseName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  repProgress,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _confirmEnd,
              child: Text(
                'End',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const _CoachingBanner(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    children: [
                      const _RepDotsWidget(),
                      const SizedBox(height: 20),
                      const Expanded(child: _GaugeWidget()),
                      const _MovementQualityBarWidget(),
                      const SizedBox(height: 20),
                      // Custom container with explicit dark bg — transparent
                      // inherits white from parent Material on some themes.
                      // ✅ Use _confirmEnd (shows dialog) not _endSession directly —
                      // consistent with the AppBar 'End' button behaviour.
                      GestureDetector(
                        onTap: _confirmEnd,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'End Session',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Coaching Banner ───────────────────────────────────────────────────────────
class _CoachingBanner extends ConsumerStatefulWidget {
  const _CoachingBanner();

  @override
  ConsumerState<_CoachingBanner> createState() => _CoachingBannerState();
}

class _CoachingBannerState extends ConsumerState<_CoachingBanner> {
  String _lastCoaching = '';
  String _lastSpokenBase = '';
  Key _coachingKey = UniqueKey();

  late final FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.45); // calm, clear pace
    _tts.setPitch(1.0);
    _tts.setVolume(1.0);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  /// Strip emoji so TTS reads clean text, and extract a "base" for dedup.
  String _cleanForSpeech(String text) {
    // Remove emoji (most common ranges) and clean up excess whitespace
    return text
        .replaceAll(
          RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
          '',
        )
        .replaceAll('—', ', ')
        .trim();
  }

  /// Extract the "base" of a message (without numbers) for dedup.
  /// e.g. "Breathe easy, 8s rest left" and "Breathe easy, 7s rest left"
  /// both become "Breathe easy, s rest left" → same base, don't re-speak.
  String _messageBase(String text) {
    return text.replaceAll(RegExp(r'\d+'), '');
  }

  void _speakIfNew(String coaching) {
    // Check if voice coach is enabled in settings
    if (!ref.read(voiceCoachProvider)) return;

    final cleanText = _cleanForSpeech(coaching);
    final base = _messageBase(cleanText);

    // Only speak if the message structure actually changed
    // (skip re-speaking countdown updates like "8s" → "7s")
    if (base != _lastSpokenBase && cleanText.isNotEmpty) {
      _lastSpokenBase = base;
      _tts.stop(); // cancel previous speech
      _tts.speak(cleanText);
    }
  }

  Color _phaseColor(RepPhase phase) {
    switch (phase) {
      case RepPhase.holdingTarget:
        return AppColors.success;
      case RepPhase.returning:
        return const Color(0xFFFBBF24);
      case RepPhase.resting:
        return AppColors.primary;
      case RepPhase.movingToTarget:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coaching = ref.watch(
      exerciseSessionProvider.select((s) => s.coachingMessage),
    );
    final phase = ref.watch(
      exerciseSessionProvider.select((s) => s.currentPhase),
    );
    final color = _phaseColor(phase);

    // Only generate a new key if the text actually changes.
    if (coaching != _lastCoaching) {
      _lastCoaching = coaching;
      _coachingKey = UniqueKey();
      // Speak the new coaching message
      _speakIfNew(coaching);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: Text(
          coaching,
          key: _coachingKey,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.4,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Rep Dots ──────────────────────────────────────────────────────────────────
class _RepDotsWidget extends ConsumerWidget {
  const _RepDotsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(exerciseSessionProvider.select((s) => s.totalReps));
    final done = ref.watch(
      exerciseSessionProvider.select((s) => s.completedReps),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: List.generate(total, (i) {
        final isDone = i < done;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isDone ? 14 : 12,
          height: isDone ? 14 : 12,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.success
                : Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            boxShadow: isDone
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

// ── Gauge Widget ──────────────────────────────────────────────────────────────
class _GaugeWidget extends ConsumerWidget {
  const _GaugeWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final angle = ref.watch(
      exerciseSessionProvider.select((s) => s.currentAngle),
    );
    final minT = ref.watch(exerciseSessionProvider.select((s) => s.minTarget));
    final maxT = ref.watch(exerciseSessionProvider.select((s) => s.maxTarget));
    final phase = ref.watch(
      exerciseSessionProvider.select((s) => s.currentPhase),
    );
    final inTarget = ref.watch(
      exerciseSessionProvider.select((s) => s.isInTargetRange),
    );
    final holdSecs = ref.watch(
      exerciseSessionProvider.select((s) => s.holdSeconds),
    );
    final exerciseType = ref.watch(
      exerciseSessionProvider.select((s) => s.currentExercise),
    );

    final bool isWaiting =
        angle == 0.0 && phase == RepPhase.resting && holdSecs == 0;
    final int remainingHold = (exerciseType.requiredHoldSeconds - holdSecs)
        .clamp(0, 99);
    // Show absolute angle so the number always grows as the user moves
    final double absAngle = angle.abs();
    // Direction label: positive = forward/up flex, negative = back/extension
    final String dirLabel = angle >= 0 ? '▲ flexion' : '▼ extension';

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: SizedBox(
              width: 280,
              height: 280,
              child: CustomPaint(
                painter: _AngleGaugePainter(
                  currentAngle:
                      absAngle, // always positive → sweeps 7→5 o'clock
                  minTarget: minT,
                  maxTarget: maxT,
                  phase: phase,
                  isInTarget: inTarget,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWaiting) ...[
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: Colors.white38,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Waiting for sensor',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ] else ...[
                Text(
                  '${absAngle.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    fontSize: 62,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dirLabel,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
                if (inTarget &&
                    phase == RepPhase.holdingTarget &&
                    remainingHold > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Hold — ${remainingHold}s',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Movement Quality Bar ───────────────────────────────────────────────────────
class _MovementQualityBarWidget extends ConsumerWidget {
  const _MovementQualityBarWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(
      exerciseSessionProvider.select((s) => s.stabilityScore),
    );
    final phase = ref.watch(
      exerciseSessionProvider.select((s) => s.currentPhase),
    );
    final completedReps = ref.watch(
      exerciseSessionProvider.select((s) => s.completedReps),
    );

    // Show 'Ready' until user starts moving (prevents false 'Move slower' label)
    final bool started = phase != RepPhase.resting || completedReps > 0;

    final color = !started
        ? Colors.white24
        : (score > 75
              ? AppColors.success
              : (score > 45 ? const Color(0xFFFBBF24) : AppColors.warning));
    final label = !started
        ? 'Ready'
        : (score > 75
              ? 'Good control'
              : (score > 45 ? 'Moderate' : 'Move slower'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Movement Quality',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: started ? score / 100 : 1.0,
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ── Angle Gauge Painter — 270° arc ────────────────────────────────────────────
// Starts at 7 o'clock (135°), sweeps 270° clockwise to 5 o'clock.
// physMin = -10 so 0° neutral sits just past the arc start (dot always visible).
class _AngleGaugePainter extends CustomPainter {
  final double currentAngle;
  final double minTarget;
  final double maxTarget;
  final RepPhase phase;
  final bool isInTarget;

  const _AngleGaugePainter({
    required this.currentAngle,
    required this.minTarget,
    required this.maxTarget,
    required this.phase,
    required this.isInTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;

    // physMin slightly below 0 so the neutral dot is always visible at rest
    const double physMin = -10.0;
    const double physMax = 120.0;
    const double arcStart = math.pi * 0.75; // 135° = 7 o'clock
    const double arcTotal = math.pi * 1.5; // 270° sweep

    double toArcRad(double deg) {
      final pct = ((deg - physMin) / (physMax - physMin)).clamp(0.0, 1.0);
      return arcStart + pct * arcTotal;
    }

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Grey background track
    canvas.drawArc(
      rect,
      arcStart,
      arcTotal,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round,
    );

    // Green target zone
    final tS = toArcRad(minTarget.clamp(physMin, physMax));
    final tE = toArcRad(maxTarget.clamp(physMin, physMax));
    if (tE > tS) {
      canvas.drawArc(
        rect,
        tS,
        tE - tS,
        false,
        Paint()
          ..color = AppColors.success.withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Neutral 0° tick mark — always a reference point
    final zeroRad = toArcRad(0.0);
    canvas.drawLine(
      Offset(
        center.dx + (radius - 18) * math.cos(zeroRad),
        center.dy + (radius - 18) * math.sin(zeroRad),
      ),
      Offset(
        center.dx + (radius + 6) * math.cos(zeroRad),
        center.dy + (radius + 6) * math.sin(zeroRad),
      ),
      Paint()
        ..color = Colors.white30
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // currentAngle is already abs(), so this always sweeps from arc start rightward
    final arcColor = isInTarget ? AppColors.success : AppColors.primaryLight;
    final currentRad = toArcRad(currentAngle.clamp(physMin, physMax));
    final filled = currentRad - arcStart;

    if (filled > 0.01) {
      // Glow pass
      canvas.drawArc(
        rect,
        arcStart,
        filled,
        false,
        Paint()
          ..color = arcColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 32
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      // Solid pass
      canvas.drawArc(
        rect,
        arcStart,
        filled,
        false,
        Paint()
          ..color = arcColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..strokeCap = StrokeCap.round,
      );
    }

    // Tip dot — ALWAYS drawn (even at 0° / tiny sweep) so the indicator
    // is always visible and not mysteriously absent at rest.
    final tipX = center.dx + radius * math.cos(currentRad);
    final tipY = center.dy + radius * math.sin(currentRad);
    canvas.drawCircle(
      Offset(tipX, tipY),
      16,
      Paint()
        ..color = arcColor.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(Offset(tipX, tipY), 10, Paint()..color = arcColor);
  }

  @override
  bool shouldRepaint(covariant _AngleGaugePainter old) =>
      old.currentAngle != currentAngle ||
      old.isInTarget != isInTarget ||
      old.minTarget != minTarget ||
      old.maxTarget != maxTarget;
}
