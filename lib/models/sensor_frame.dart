class SensorFrame {
  final double pitch1;
  final double pitch2;
  final double kneeAngle;
  final double roll1;
  final double roll2;
  final String stability;
  final DateTime timestamp;
  final double smoothedKneeAngle;

  const SensorFrame({
    required this.pitch1,
    required this.pitch2,
    required this.kneeAngle,
    required this.roll1,
    required this.roll2,
    required this.stability,
    required this.timestamp,
    required this.smoothedKneeAngle,
  });

  /// Example data: S1:12.3,S2:8.1,KNEE:4.2,R1:1.0,R2:0.5,STAB:Good
  static SensorFrame? tryParse(
    String raw,
    DateTime timestamp,
    double smoothedKnee,
  ) {
    try {
      final parts = raw.split(',');
      double? s1, s2, knee, r1, r2;
      String? stab;

      for (var part in parts) {
        final kv = part.split(':');
        if (kv.length != 2) continue;

        final key = kv[0].trim();
        final val = kv[1].trim();

        switch (key) {
          case 'S1':
            s1 = double.tryParse(val);
            break;
          case 'S2':
            s2 = double.tryParse(val);
            break;
          case 'KNEE':
            knee = double.tryParse(val);
            break;
          case 'R1':
            r1 = double.tryParse(val);
            break;
          case 'R2':
            r2 = double.tryParse(val);
            break;
          case 'STAB':
            stab = val;
            break;
        }
      }

      if (s1 != null &&
          s2 != null &&
          knee != null &&
          r1 != null &&
          r2 != null &&
          stab != null) {
        return SensorFrame(
          pitch1: s1,
          pitch2: s2,
          kneeAngle: knee,
          roll1: r1,
          roll2: r2,
          stability: stab,
          timestamp: timestamp,
          smoothedKneeAngle: smoothedKnee,
        );
      }
    } catch (e) {
      // Parsing failed
    }
    return null;
  }
}
