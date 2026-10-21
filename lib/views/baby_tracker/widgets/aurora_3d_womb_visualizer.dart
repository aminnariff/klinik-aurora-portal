import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Clinical biometric measurements and developmental milestones for a given gestational week.
class FetalBiometrics {
  final int week;
  final String fruit;
  final String fruitEmoji;
  final double crlCm; // Crown-Rump Length in cm
  final double weightGrams; // Weight in grams
  final double bpdCm; // Biparietal diameter in cm (head width)
  final String fhrRange; // Fetal heart rate range (e.g. '120–160 bpm')
  final String milestone; // Clinical guidance by Dr. Aurora
  final int trimester; // 1, 2, or 3

  const FetalBiometrics({
    required this.week,
    required this.fruit,
    required this.fruitEmoji,
    required this.crlCm,
    required this.weightGrams,
    required this.bpdCm,
    required this.fhrRange,
    required this.milestone,
    required this.trimester,
  });

  String get formattedWeight {
    if (weightGrams < 1.0) {
      return weightGrams == 0.0 ? '< 0.1 g' : '${weightGrams.toStringAsFixed(1)} g';
    }
    final intVal = weightGrams.round();
    final formatted = intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted g';
  }

  String get formattedCrl => '${crlCm.toStringAsFixed(1)} cm';
  String get formattedBpd => '${bpdCm.toStringAsFixed(1)} cm';
  String get formattedFhr => fhrRange.contains('bpm') || fhrRange == '-' ? fhrRange : '$fhrRange bpm';
}

/// Built-in clinical biometrics lookup for Weeks 1 to 40.
final Map<int, FetalBiometrics> _kBiometricsTable = {
  1: const FetalBiometrics(
    week: 1,
    fruit: 'Biji Vanila',
    fruitEmoji: '🌱',
    crlCm: 0.1,
    weightGrams: 0.0,
    bpdCm: 0.0,
    fhrRange: '-',
    milestone: 'Persenyawaan sel telur dan sperma berlaku. Zigot mula membahagi secara mitosis.',
    trimester: 1,
  ),
  2: const FetalBiometrics(
    week: 2,
    fruit: 'Biji Popi',
    fruitEmoji: '🌱',
    crlCm: 0.1,
    weightGrams: 0.0,
    bpdCm: 0.0,
    fhrRange: '-',
    milestone: 'Blastocyst mula menempel pada lapisan endometrium rahim ibu (implantasi).',
    trimester: 1,
  ),
  3: const FetalBiometrics(
    week: 3,
    fruit: 'Biji Chia',
    fruitEmoji: '🌾',
    crlCm: 0.15,
    weightGrams: 0.0,
    bpdCm: 0.0,
    fhrRange: '-',
    milestone: 'Pembentukan plat neural dan tiga lapisan kuman embrio asas: ektoderm, mesoderm, endoderm.',
    trimester: 1,
  ),
  4: const FetalBiometrics(
    week: 4,
    fruit: 'Biji Popi',
    fruitEmoji: '🌱',
    crlCm: 0.2,
    weightGrams: 0.1,
    bpdCm: 0.1,
    fhrRange: '100–115 bpm',
    milestone: 'Kantung gestasi mula kelihatan pada imbasan ultrasound awal. Tiub neural mula tertutup.',
    trimester: 1,
  ),
  5: const FetalBiometrics(
    week: 5,
    fruit: 'Biji Epal',
    fruitEmoji: '🍎',
    crlCm: 0.3,
    weightGrams: 0.2,
    bpdCm: 0.2,
    fhrRange: '100–120 bpm',
    milestone: 'Jantung primitif janin mula berdegup buat kali pertama! Tunas anggota badan terbentuk.',
    trimester: 1,
  ),
  6: const FetalBiometrics(
    week: 6,
    fruit: 'Kekacang Lentil',
    fruitEmoji: '🫘',
    crlCm: 0.6,
    weightGrams: 0.5,
    bpdCm: 0.3,
    fhrRange: '110–130 bpm',
    milestone: 'Tiub saraf tertutup sepenuhnya. Bentuk melengkung C embrio jelas kelihatan.',
    trimester: 1,
  ),
  7: const FetalBiometrics(
    week: 7,
    fruit: 'Beri Biru',
    fruitEmoji: '🫐',
    crlCm: 1.0,
    weightGrams: 0.8,
    bpdCm: 0.5,
    fhrRange: '130–150 bpm',
    milestone: 'Tunas tangan dan kaki memanjang; otak berkembang pantas dengan pembentukan vesikel.',
    trimester: 1,
  ),
  8: const FetalBiometrics(
    week: 8,
    fruit: 'Beri Raspberi',
    fruitEmoji: '🍓',
    crlCm: 1.6,
    weightGrams: 1.0,
    bpdCm: 0.8,
    fhrRange: '140–160 bpm',
    milestone: 'Jari jemari mula berpisah daripada jaringan selaput. Refleks saraf spontan bermula.',
    trimester: 1,
  ),
  9: const FetalBiometrics(
    week: 9,
    fruit: 'Biji Zaitun',
    fruitEmoji: '🫒',
    crlCm: 2.3,
    weightGrams: 2.0,
    bpdCm: 1.1,
    fhrRange: '140–170 bpm',
    milestone: 'Semua organ penting telah mula terbentuk. Sendi siku dan pergelangan tangan mula fleksi.',
    trimester: 1,
  ),
  10: const FetalBiometrics(
    week: 10,
    fruit: 'Buah Prun',
    fruitEmoji: '🫐',
    crlCm: 3.1,
    weightGrams: 4.0,
    bpdCm: 1.4,
    fhrRange: '140–170 bpm',
    milestone: 'Fasa embrio tamat secara rasmi; kini digelar fetus. Tulang rawan mula proses pengerasan.',
    trimester: 1,
  ),
  11: const FetalBiometrics(
    week: 11,
    fruit: 'Buah Ara',
    fruitEmoji: '🫐',
    crlCm: 4.1,
    weightGrams: 7.0,
    bpdCm: 1.7,
    fhrRange: '140–165 bpm',
    milestone: 'Fetus mula menelan cecair amnion dan menggerakkan anggota badan secara aktif.',
    trimester: 1,
  ),
  12: const FetalBiometrics(
    week: 12,
    fruit: 'Limau Nipis',
    fruitEmoji: '🍋',
    crlCm: 5.4,
    weightGrams: 14.0,
    bpdCm: 2.1,
    fhrRange: '120–160 bpm',
    milestone: 'Profil wajah dan kuku halus terbentuk lengkap. Risiko keguguran menurun mendadak.',
    trimester: 1,
  ),
  13: const FetalBiometrics(
    week: 13,
    fruit: 'Lemon',
    fruitEmoji: '🍋',
    crlCm: 7.4,
    weightGrams: 23.0,
    bpdCm: 2.4,
    fhrRange: '120–160 bpm',
    milestone: 'Selamat datang ke Trimester 2! Corak cap jari yang unik mula terbentuk pada jari-jemari.',
    trimester: 2,
  ),
  14: const FetalBiometrics(
    week: 14,
    fruit: 'Buah Kiwi',
    fruitEmoji: '🥝',
    crlCm: 8.7,
    weightGrams: 43.0,
    bpdCm: 2.8,
    fhrRange: '120–160 bpm',
    milestone: 'Janin mula membuat ekspresi muka dan refleks menghisap ibu jari mula dikesan.',
    trimester: 2,
  ),
  15: const FetalBiometrics(
    week: 15,
    fruit: 'Epal Merah',
    fruitEmoji: '🍎',
    crlCm: 10.1,
    weightGrams: 70.0,
    bpdCm: 3.2,
    fhrRange: '120–160 bpm',
    milestone: 'Kerangka tulang janin mengeras (osifikasi). Janin mula peka terhadap pancaran cahaya luar.',
    trimester: 2,
  ),
  16: const FetalBiometrics(
    week: 16,
    fruit: 'Avokado',
    fruitEmoji: '🥑',
    crlCm: 11.6,
    weightGrams: 100.0,
    bpdCm: 3.6,
    fhrRange: '120–160 bpm',
    milestone: 'Otot janin semakin teguh. Jantina bayi kini boleh ditentukan melalui imbasan ultrasound.',
    trimester: 2,
  ),
  17: const FetalBiometrics(
    week: 17,
    fruit: 'Buah Pir',
    fruitEmoji: '🍐',
    crlCm: 13.0,
    weightGrams: 140.0,
    bpdCm: 3.9,
    fhrRange: '120–160 bpm',
    milestone: 'Lapisan lemak coklat mula terkumpul untuk membantu mengekalkan suhu badan bayi.',
    trimester: 2,
  ),
  18: const FetalBiometrics(
    week: 18,
    fruit: 'Lada Benggala',
    fruitEmoji: '🫑',
    crlCm: 14.2,
    weightGrams: 190.0,
    bpdCm: 4.3,
    fhrRange: '120–160 bpm',
    milestone: 'Telinga berada pada posisi sempurna; janin boleh mendengar degupan jantung dan suara ibu.',
    trimester: 2,
  ),
  19: const FetalBiometrics(
    week: 19,
    fruit: 'Mangga',
    fruitEmoji: '🥭',
    crlCm: 15.3,
    weightGrams: 240.0,
    bpdCm: 4.6,
    fhrRange: '120–160 bpm',
    milestone: 'Lapisan pelindung vernix caseosa menyelaputi kulit janin daripada cecair amnion.',
    trimester: 2,
  ),
  20: const FetalBiometrics(
    week: 20,
    fruit: 'Pisang',
    fruitEmoji: '🍌',
    crlCm: 25.6,
    weightGrams: 300.0,
    bpdCm: 4.9,
    fhrRange: '120–160 bpm',
    milestone: 'Anatomi scan lengkap. Jari tangan & kaki terbentuk sempurna. Tendangan mula dirasai ibu!',
    trimester: 2,
  ),
  21: const FetalBiometrics(
    week: 21,
    fruit: 'Lobak Merah',
    fruitEmoji: '🥕',
    crlCm: 26.7,
    weightGrams: 360.0,
    bpdCm: 5.2,
    fhrRange: '120–160 bpm',
    milestone: 'Sistem pencernaan janin mula menyerap air dan gula daripada cecair amnion yang ditelan.',
    trimester: 2,
  ),
  22: const FetalBiometrics(
    week: 22,
    fruit: 'Betik Kecil',
    fruitEmoji: '🍈',
    crlCm: 27.8,
    weightGrams: 430.0,
    bpdCm: 5.5,
    fhrRange: '120–160 bpm',
    milestone: 'Deria sentuhan dan tunas rasa lidah berfungsi; janin meneroka ruang rahim ibu.',
    trimester: 2,
  ),
  23: const FetalBiometrics(
    week: 23,
    fruit: 'Buah Delima',
    fruitEmoji: '🍇',
    crlCm: 28.9,
    weightGrams: 500.0,
    bpdCm: 5.8,
    fhrRange: '120–160 bpm',
    milestone: 'Denyutan jantung janin boleh didengari dengan stetoskop klinikal. Gerakan semakin berirama.',
    trimester: 2,
  ),
  24: const FetalBiometrics(
    week: 24,
    fruit: 'Jagung',
    fruitEmoji: '🌽',
    crlCm: 30.0,
    weightGrams: 600.0,
    bpdCm: 6.1,
    fhrRange: '120–160 bpm',
    milestone: 'Paru-paru menghasilkan surfaktan asas. Janin mencapai ambang kebolehhidupan (viability).',
    trimester: 2,
  ),
  25: const FetalBiometrics(
    week: 25,
    fruit: 'Bunga Kubis',
    fruitEmoji: '🥦',
    crlCm: 34.6,
    weightGrams: 660.0,
    bpdCm: 6.4,
    fhrRange: '120–160 bpm',
    milestone: 'Rambut halus dan kapilari darah kulit matang; janin memberi respon kepada sentuhan perut ibu.',
    trimester: 2,
  ),
  26: const FetalBiometrics(
    week: 26,
    fruit: 'Salad Romaine',
    fruitEmoji: '🥬',
    crlCm: 35.6,
    weightGrams: 760.0,
    bpdCm: 6.7,
    fhrRange: '120–160 bpm',
    milestone: 'Mata janin mula celik! Janin bertindak balas terhadap rangsangan bunyi bising luar rahim.',
    trimester: 2,
  ),
  27: const FetalBiometrics(
    week: 27,
    fruit: 'Kubis Ungu',
    fruitEmoji: '🥦',
    crlCm: 36.6,
    weightGrams: 875.0,
    bpdCm: 7.0,
    fhrRange: '120–160 bpm',
    milestone: 'Janin kerap tersedu (hiccups), melatih otot diafragma untuk pernafasan selepas lahir.',
    trimester: 2,
  ),
  28: const FetalBiometrics(
    week: 28,
    fruit: 'Terung',
    fruitEmoji: '🍆',
    crlCm: 37.6,
    weightGrams: 1000.0,
    bpdCm: 7.3,
    fhrRange: '120–160 bpm',
    milestone: 'Selamat datang ke Trimester 3! Janin mula bermimpi dalam fasa tidur Rapid Eye Movement (REM).',
    trimester: 3,
  ),
  29: const FetalBiometrics(
    week: 29,
    fruit: 'Labu Butternut',
    fruitEmoji: '🎃',
    crlCm: 38.6,
    weightGrams: 1150.0,
    bpdCm: 7.6,
    fhrRange: '120–160 bpm',
    milestone: 'Otak janin mengawal suhu badan dan corak pernafasan dengan koordinasi saraf tinggi.',
    trimester: 3,
  ),
  30: const FetalBiometrics(
    week: 30,
    fruit: 'Kubis Bulat',
    fruitEmoji: '🥬',
    crlCm: 39.9,
    weightGrams: 1320.0,
    bpdCm: 7.8,
    fhrRange: '120–160 bpm',
    milestone: 'Sumsum tulang janin mengambil alih penghasilan sel darah merah sepenuhnya.',
    trimester: 3,
  ),
  31: const FetalBiometrics(
    week: 31,
    fruit: 'Nanas',
    fruitEmoji: '🍍',
    crlCm: 41.1,
    weightGrams: 1500.0,
    bpdCm: 8.0,
    fhrRange: '120–160 bpm',
    milestone: 'Ruang rahim semakin sempit; tendangan bertukar menjadi gerakan regangan kuat.',
    trimester: 3,
  ),
  32: const FetalBiometrics(
    week: 32,
    fruit: 'Kelapa Muda',
    fruitEmoji: '🥥',
    crlCm: 42.4,
    weightGrams: 1700.0,
    bpdCm: 8.2,
    fhrRange: '120–160 bpm',
    milestone: 'Semua tulang mengeras kecuali tempurung kepala yang fleksibel untuk proses kelahiran.',
    trimester: 3,
  ),
  33: const FetalBiometrics(
    week: 33,
    fruit: 'Nanas Madu',
    fruitEmoji: '🍍',
    crlCm: 43.7,
    weightGrams: 1900.0,
    bpdCm: 8.4,
    fhrRange: '120–160 bpm',
    milestone: 'Antibodi maternal dipindahkan pesat ke janin bagi membina imuniti awal selepas lahir.',
    trimester: 3,
  ),
  34: const FetalBiometrics(
    week: 34,
    fruit: 'Tembikai Susu',
    fruitEmoji: '🍈',
    crlCm: 45.0,
    weightGrams: 2150.0,
    bpdCm: 8.6,
    fhrRange: '120–160 bpm',
    milestone: 'Paru-paru dan sistem saraf pusat janin hampir mencapai tahap kematangan lengkap.',
    trimester: 3,
  ),
  35: const FetalBiometrics(
    week: 35,
    fruit: 'Tembikai Wangi',
    fruitEmoji: '🍈',
    crlCm: 46.2,
    weightGrams: 2380.0,
    bpdCm: 8.8,
    fhrRange: '120–160 bpm',
    milestone: 'Sebahagian besar janin berada dalam kedudukan kepala ke bawah (cephalic presentation).',
    trimester: 3,
  ),
  36: const FetalBiometrics(
    week: 36,
    fruit: 'Betik',
    fruitEmoji: '🍈',
    crlCm: 47.4,
    weightGrams: 2600.0,
    bpdCm: 9.0,
    fhrRange: '120–160 bpm',
    milestone: 'Fetus mencapai status awal matang (late preterm). Ruang terhad, bersiap turun ke pelvis.',
    trimester: 3,
  ),
  37: const FetalBiometrics(
    week: 37,
    fruit: 'Tembikai Madu',
    fruitEmoji: '🍉',
    crlCm: 48.6,
    weightGrams: 2850.0,
    bpdCm: 9.1,
    fhrRange: '120–160 bpm',
    milestone: 'Tahniah! Janin kini dianggap matang penuh (early term). Refleks menggenggam sangat kuat.',
    trimester: 3,
  ),
  38: const FetalBiometrics(
    week: 38,
    fruit: 'Labu Manis',
    fruitEmoji: '🎃',
    crlCm: 49.8,
    weightGrams: 3080.0,
    bpdCm: 9.3,
    fhrRange: '120–160 bpm',
    milestone: 'Bulu halus lanugo dan lapisan vernix mula tertanggal daripada kulit janin.',
    trimester: 3,
  ),
  39: const FetalBiometrics(
    week: 39,
    fruit: 'Tembikai Kecil',
    fruitEmoji: '🍉',
    crlCm: 50.7,
    weightGrams: 3250.0,
    bpdCm: 9.4,
    fhrRange: '120–160 bpm',
    milestone: 'Kepala janin memasuki rongga pelvis ibu (engagement), menanti detik kelahiran bila-bila masa.',
    trimester: 3,
  ),
  40: const FetalBiometrics(
    week: 40,
    fruit: 'Tembikai',
    fruitEmoji: '🍉',
    crlCm: 51.2,
    weightGrams: 3400.0,
    bpdCm: 9.5,
    fhrRange: '120–160 bpm',
    milestone: 'Tarikh jangkaan bersalin (EDD)! Bayi comel bersedia menyambut dunia pada bila-bila masa.',
    trimester: 3,
  ),
};

/// Retrieve biometrics for a given week (clamped 1–40).
FetalBiometrics _getBiometricsForWeek(int week) {
  final clamped = week.clamp(1, 40);
  return _kBiometricsTable[clamped]!;
}

// ---------------------------------------------------------------------------
// 3D Matrix Mathematics Helper Data Structures
// ---------------------------------------------------------------------------

class _Point3D {
  final double x;
  final double y;
  final double z;
  const _Point3D(this.x, this.y, this.z);
}

class _ProjectedPoint {
  final double screenX;
  final double screenY;
  final double rotatedZ;
  final double perspective;

  const _ProjectedPoint({
    required this.screenX,
    required this.screenY,
    required this.rotatedZ,
    required this.perspective,
  });

  Offset get offset => Offset(screenX, screenY);
}

class _WireSegment {
  final _ProjectedPoint p1;
  final _ProjectedPoint p2;
  final double avgZ;

  const _WireSegment(this.p1, this.p2, this.avgZ);
}

// ---------------------------------------------------------------------------
// 3D Womb Orb CustomPainter
// ---------------------------------------------------------------------------

class _WombOrbPainter extends CustomPainter {
  final int week;
  final double userYaw;
  final double userPitch;
  final double idlePrecession;
  final double heartbeatProgress;

  _WombOrbPainter({
    required this.week,
    required this.userYaw,
    required this.userPitch,
    required this.idlePrecession,
    required this.heartbeatProgress,
  });

  // Calculate cardiac double-systolic pulse value in [0, 1]
  double _calcCardiacPulse(double t) {
    if (t < 0.22) {
      return math.sin((t / 0.22) * math.pi);
    } else if (t < 0.44) {
      return 0.45 * math.sin(((t - 0.22) / 0.22) * math.pi);
    }
    return 0.0;
  }

  _ProjectedPoint _project(
    _Point3D p,
    double cosYaw,
    double sinYaw,
    double cosPitch,
    double sinPitch,
    double focalLength,
    double centerX,
    double centerY,
  ) {
    final rotatedX = p.x * cosYaw + p.z * sinYaw;
    final tempZ = -p.x * sinYaw + p.z * cosYaw;
    final rotatedY = p.y * cosPitch - tempZ * sinPitch;
    final rotatedZ = p.y * sinPitch + tempZ * cosPitch;

    final perspective = focalLength / (focalLength + rotatedZ);
    final screenX = centerX + rotatedX * perspective;
    final screenY = centerY + rotatedY * perspective;

    return _ProjectedPoint(
      screenX: screenX,
      screenY: screenY,
      rotatedZ: rotatedZ,
      perspective: perspective,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2.0;
    final centerY = size.height / 2.0;
    final R = size.width * 0.38; // Radius of 3D womb sphere
    final focalLength = R * 3.4;

    final totalYaw = userYaw + idlePrecession;
    final totalPitch = userPitch;

    final cosYaw = math.cos(totalYaw);
    final sinYaw = math.sin(totalYaw);
    final cosPitch = math.cos(totalPitch);
    final sinPitch = math.sin(totalPitch);

    final cardiacPulse = _calcCardiacPulse(heartbeatProgress);

    // -------------------------------------------------------------------------
    // Layer 1: Ambient Backdrop Glow
    // -------------------------------------------------------------------------
    final outerGlowPaint = Paint()
      ..color = const Color(0xFFFFB4C8).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(Offset(centerX, centerY), R * 1.08, outerGlowPaint);

    // -------------------------------------------------------------------------
    // Layer 2: Amniotic Fluid Radial Gradient Disc with Specular Highlight
    // -------------------------------------------------------------------------
    final fluidRect = Rect.fromCircle(center: Offset(centerX, centerY), radius: R);
    final fluidGradient = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.95,
      colors: [
        const Color(0xFFFFF0F5).withValues(alpha: 0.88),
        const Color(0xFFFFD5E2).withValues(alpha: 0.60),
        const Color(0xFFF9A8D4).withValues(alpha: 0.28),
        const Color(0xFFF472B6).withValues(alpha: 0.12),
      ],
      stops: const [0.0, 0.45, 0.78, 1.0],
    );
    final fluidPaint = Paint()..shader = fluidGradient.createShader(fluidRect);
    canvas.drawCircle(Offset(centerX, centerY), R, fluidPaint);

    // Subtle inner uterine wall stroke
    final rimPaint = Paint()
      ..color = const Color(0xFFFB7185).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset(centerX, centerY), R, rimPaint);

    // -------------------------------------------------------------------------
    // Generate Wireframe Mesh Rings (Latitude & Longitude)
    // -------------------------------------------------------------------------
    final List<_WireSegment> backSegments = [];
    final List<_WireSegment> frontSegments = [];

    void addSegment(_ProjectedPoint p1, _ProjectedPoint p2) {
      final avgZ = (p1.rotatedZ + p2.rotatedZ) / 2.0;
      final seg = _WireSegment(p1, p2, avgZ);
      if (avgZ > 0) {
        backSegments.add(seg);
      } else {
        frontSegments.add(seg);
      }
    }

    // Latitude rings: phi = -50°, -25°, 0°, 25°, 50°
    const latAngles = [-0.90, -0.45, 0.0, 0.45, 0.90];
    const latSteps = 32;
    for (final phi in latAngles) {
      final rLat = R * math.cos(phi);
      final yLat = R * math.sin(phi);
      _ProjectedPoint? prevP;
      _ProjectedPoint? firstP;

      for (int i = 0; i <= latSteps; i++) {
        final theta = (i / latSteps) * 2 * math.pi;
        final pt = _Point3D(rLat * math.cos(theta), yLat, rLat * math.sin(theta));
        final proj = _project(pt, cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

        if (i == 0) firstP = proj;
        if (prevP != null) {
          addSegment(prevP, proj);
        }
        prevP = proj;
      }
      if (prevP != null && firstP != null) {
        addSegment(prevP, firstP);
      }
    }

    // Longitude meridians: 6 rings
    const meridianCount = 6;
    const lonSteps = 32;
    for (int m = 0; m < meridianCount; m++) {
      final lambda = (m / meridianCount) * math.pi;
      _ProjectedPoint? prevP;
      _ProjectedPoint? firstP;

      for (int i = 0; i <= lonSteps; i++) {
        final phi = (i / lonSteps) * 2 * math.pi;
        final pt = _Point3D(
          R * math.cos(phi) * math.cos(lambda),
          R * math.sin(phi),
          R * math.cos(phi) * math.sin(lambda),
        );
        final proj = _project(pt, cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

        if (i == 0) firstP = proj;
        if (prevP != null) {
          addSegment(prevP, proj);
        }
        prevP = proj;
      }
      if (prevP != null && firstP != null) {
        addSegment(prevP, firstP);
      }
    }

    // -------------------------------------------------------------------------
    // Layer 3: Render Back Wireframe Rings (Depth faded)
    // -------------------------------------------------------------------------
    final wirePaint = Paint()..style = PaintingStyle.stroke;
    for (final seg in backSegments) {
      final frontFactor = ((R - seg.avgZ) / (2.0 * R)).clamp(0.0, 1.0);
      final alpha = (0.08 + 0.35 * frontFactor).clamp(0.05, 0.95);
      wirePaint.color = const Color(0xFFFFB4C8).withValues(alpha: alpha);
      wirePaint.strokeWidth = 0.9 + 0.6 * frontFactor;
      canvas.drawLine(seg.p1.offset, seg.p2.offset, wirePaint);
    }

    // -------------------------------------------------------------------------
    // Layer 4: Floating Bio-Particles (Amniotic Droplets)
    // -------------------------------------------------------------------------
    final particlePaint = Paint()..style = PaintingStyle.fill;
    const particleCount = 14;
    for (int i = 0; i < particleCount; i++) {
      final seed = i * 2.399;
      final speed = 0.4 + (i % 5) * 0.15;
      final currentTheta = seed + idlePrecession * speed;
      final currentPhi = math.sin(seed * 1.5 + idlePrecession * 0.3) * 0.85;
      final radiusFactor = 0.30 + ((i * 17) % 50) / 100.0;
      final pR = R * radiusFactor;

      final pPt = _Point3D(
        pR * math.cos(currentPhi) * math.cos(currentTheta),
        pR * math.sin(currentPhi),
        pR * math.cos(currentPhi) * math.sin(currentTheta),
      );
      final proj = _project(pPt, cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

      final frontFactor = ((R - proj.rotatedZ) / (2.0 * R)).clamp(0.0, 1.0);
      final pAlpha = (0.20 + 0.65 * frontFactor).clamp(0.1, 0.95);
      final pRadius = (1.4 + 1.6 * frontFactor) * proj.perspective;

      particlePaint.color = const Color(0xFFFFF1F2).withValues(alpha: pAlpha);
      canvas.drawCircle(proj.offset, pRadius, particlePaint);

      // Pearl core
      if (frontFactor > 0.6) {
        particlePaint.color = Colors.white.withValues(alpha: pAlpha);
        canvas.drawCircle(proj.offset, pRadius * 0.5, particlePaint);
      }
    }

    // -------------------------------------------------------------------------
    // Layer 5: Fetal Biometric Avatar (Week-based morphing engine)
    // -------------------------------------------------------------------------
    _paintFetalAvatar(
      canvas: canvas,
      R: R,
      centerX: centerX,
      centerY: centerY,
      focalLength: focalLength,
      cosYaw: cosYaw,
      sinYaw: sinYaw,
      cosPitch: cosPitch,
      sinPitch: sinPitch,
      cardiacPulse: cardiacPulse,
    );

    // -------------------------------------------------------------------------
    // Layer 6: Render Front Wireframe Rings (Bright glowing depth)
    // -------------------------------------------------------------------------
    for (final seg in frontSegments) {
      final frontFactor = ((R - seg.avgZ) / (2.0 * R)).clamp(0.0, 1.0);
      final alpha = (0.35 + 0.55 * frontFactor).clamp(0.1, 0.95);
      wirePaint.color = const Color(0xFFFFB4C8).withValues(alpha: alpha);
      wirePaint.strokeWidth = 1.1 + 1.1 * frontFactor;
      canvas.drawLine(seg.p1.offset, seg.p2.offset, wirePaint);
    }

    // -------------------------------------------------------------------------
    // Layer 7: Specular Glass Arc & Curved Womb Highlight
    // -------------------------------------------------------------------------
    final highlightPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: R * 0.94),
        -math.pi * 0.85,
        math.pi * 0.45,
      );
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highlightPath, highlightPaint);
  }

  // ---------------------------------------------------------------------------
  // Fetal Avatar Rendering by Morphing Stage
  // ---------------------------------------------------------------------------
  void _paintFetalAvatar({
    required Canvas canvas,
    required double R,
    required double centerX,
    required double centerY,
    required double focalLength,
    required double cosYaw,
    required double sinYaw,
    required double cosPitch,
    required double sinPitch,
    required double cardiacPulse,
  }) {
    if (week <= 4) {
      _paintBlastocystStage(
        canvas: canvas,
        R: R,
        centerX: centerX,
        centerY: centerY,
        focalLength: focalLength,
        cosYaw: cosYaw,
        sinYaw: sinYaw,
        cosPitch: cosPitch,
        sinPitch: sinPitch,
        cardiacPulse: cardiacPulse,
      );
    } else if (week <= 12) {
      _paintEmbryonicStage(
        canvas: canvas,
        R: R,
        centerX: centerX,
        centerY: centerY,
        focalLength: focalLength,
        cosYaw: cosYaw,
        sinYaw: sinYaw,
        cosPitch: cosPitch,
        sinPitch: sinPitch,
        cardiacPulse: cardiacPulse,
      );
    } else if (week <= 27) {
      _paintFetalTrimester2Stage(
        canvas: canvas,
        R: R,
        centerX: centerX,
        centerY: centerY,
        focalLength: focalLength,
        cosYaw: cosYaw,
        sinYaw: sinYaw,
        cosPitch: cosPitch,
        sinPitch: sinPitch,
        cardiacPulse: cardiacPulse,
      );
    } else {
      _paintNeonatalTrimester3Stage(
        canvas: canvas,
        R: R,
        centerX: centerX,
        centerY: centerY,
        focalLength: focalLength,
        cosYaw: cosYaw,
        sinYaw: sinYaw,
        cosPitch: cosPitch,
        sinPitch: sinPitch,
        cardiacPulse: cardiacPulse,
      );
    }
  }

  // Stage 1: Microscopic Blastocyst Orb (Week 1–4)
  void _paintBlastocystStage({
    required Canvas canvas,
    required double R,
    required double centerX,
    required double centerY,
    required double focalLength,
    required double cosYaw,
    required double sinYaw,
    required double cosPitch,
    required double sinPitch,
    required double cardiacPulse,
  }) {
    final centerPt = _Point3D(0, 0, 0);
    final proj = _project(centerPt, cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

    final baseRadius = (7.0 + week * 1.5) * proj.perspective;
    final pulseScale = 1.0 + 0.10 * cardiacPulse;
    final radius = baseRadius * pulseScale;

    // Glowing golden-rose corona
    final coronaPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(proj.offset, radius * 1.8, coronaPaint);

    // Pearlescent blastocyst core
    final coreGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: const [
        Colors.white,
        Color(0xFFFFCCD5),
        Color(0xFFFB7185),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    final corePaint = Paint()..shader = coreGradient.createShader(Rect.fromCircle(center: proj.offset, radius: radius));
    canvas.drawCircle(proj.offset, radius, corePaint);

    // Peripheral trophoblast cellular nodes
    final cellPaint = Paint()..color = const Color(0xFFFFF1F2).withValues(alpha: 0.85);
    const cellCount = 6;
    for (int i = 0; i < cellCount; i++) {
      final angle = (i / cellCount) * 2 * math.pi;
      final cx = proj.offset.dx + math.cos(angle) * (radius * 1.08);
      final cy = proj.offset.dy + math.sin(angle) * (radius * 1.08);
      canvas.drawCircle(Offset(cx, cy), 1.8 * proj.perspective, cellPaint);
    }
  }

  // Stage 2: Embryonic Curved C-Shape with Cranial Node, Optic Vesicle & Limb Buds (Week 5–12)
  void _paintEmbryonicStage({
    required Canvas canvas,
    required double R,
    required double centerX,
    required double centerY,
    required double focalLength,
    required double cosYaw,
    required double sinYaw,
    required double cosPitch,
    required double sinPitch,
    required double cardiacPulse,
  }) {
    // Proportional scale based on week
    final scale = 0.32 + (week - 5) * 0.045;

    // 1. Cranial Prominence (Head Node)
    final headPt = _Point3D(0, -32 * scale, 0);
    final projHead = _project(headPt, cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final headRadius = 14.0 * scale * projHead.perspective;

    // Head fill
    final headPaint = Paint()..color = const Color(0xFFFFCCD5);
    canvas.drawCircle(projHead.offset, headRadius, headPaint);

    // Optic vesicle point (early eye)
    final opticPt = _Point3D(6 * scale, -32 * scale, 6 * scale);
    final projOptic = _project(opticPt, cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final opticPaint = Paint()..color = const Color(0xFF475569);
    canvas.drawCircle(projOptic.offset, 2.0 * scale * projOptic.perspective, opticPaint);

    // 2. Curved C-Spine Path
    final pNeck = _project(_Point3D(-4 * scale, -18 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final pDorsal = _project(_Point3D(-18 * scale, -4 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final pLumbar = _project(_Point3D(-20 * scale, 12 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final pCaudal = _project(_Point3D(4 * scale, 24 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

    final spinePath = Path()
      ..moveTo(projHead.offset.dx, projHead.offset.dy)
      ..quadraticBezierTo(pNeck.offset.dx, pNeck.offset.dy, pDorsal.offset.dx, pDorsal.offset.dy)
      ..quadraticBezierTo(pLumbar.offset.dx, pLumbar.offset.dy, pCaudal.offset.dx, pCaudal.offset.dy);

    final spinePaint = Paint()
      ..color = const Color(0xFFFFB4C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13.0 * scale * projHead.perspective
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(spinePath, spinePaint);

    // 3. Ventral Cardiac Bulge (Doppler Heartbeat)
    final heartPt = _Point3D(4 * scale, -2 * scale, 3 * scale);
    final projHeart = _project(heartPt, cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final heartRadius = (6.0 * scale * (1.0 + 0.28 * cardiacPulse)) * projHeart.perspective;

    // Cardiac Doppler ripple wave
    if (cardiacPulse > 0.05) {
      final ripplePaint = Paint()
        ..color = const Color(0xFFF43F5E).withValues(alpha: (1.0 - cardiacPulse) * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawCircle(projHeart.offset, heartRadius * (1.2 + 0.8 * cardiacPulse), ripplePaint);
    }

    final heartPaint = Paint()
      ..color = Color.lerp(const Color(0xFFFB7185), const Color(0xFFE11D48), cardiacPulse)!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(projHeart.offset, heartRadius, heartPaint);

    // 4. Limb Buds (Upper & Lower buds)
    final armBud = _project(_Point3D(10 * scale, -4 * scale, 5 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final legBud = _project(_Point3D(8 * scale, 18 * scale, 5 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final budPaint = Paint()..color = const Color(0xFFFFCCD5);
    canvas.drawCircle(armBud.offset, 4.0 * scale * armBud.perspective, budPaint);
    canvas.drawCircle(legBud.offset, 4.2 * scale * legBud.perspective, budPaint);
  }

  // Stage 3: Developed Fetus with Anatomical Head, Spine, Arms & Legs (Week 13–27)
  void _paintFetalTrimester2Stage({
    required Canvas canvas,
    required double R,
    required double centerX,
    required double centerY,
    required double focalLength,
    required double cosYaw,
    required double sinYaw,
    required double cosPitch,
    required double sinPitch,
    required double cardiacPulse,
  }) {
    // Proportional to Crown-Rump Length
    final scale = 0.50 + (week - 13) * 0.016;

    // 1. Anatomical Head
    final headPt = _Point3D(0, -36 * scale, 0);
    final projHead = _project(headPt, cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final headRadius = 17.0 * scale * projHead.perspective;

    final headPaint = Paint()..color = const Color(0xFFFFCCD5);
    canvas.drawCircle(projHead.offset, headRadius, headPaint);

    // Facial profile (nose bridge & chin)
    final nosePt = _project(_Point3D(14 * scale, -34 * scale, 5 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final chinPt = _project(_Point3D(10 * scale, -24 * scale, 4 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final eyePt = _project(_Point3D(8 * scale, -37 * scale, 8 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

    // Facial profile slope
    final profilePath = Path()
      ..moveTo(eyePt.offset.dx, eyePt.offset.dy)
      ..lineTo(nosePt.offset.dx, nosePt.offset.dy)
      ..lineTo(chinPt.offset.dx, chinPt.offset.dy);
    final profilePaint = Paint()
      ..color = const Color(0xFFFDA4AF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * scale * projHead.perspective
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(profilePath, profilePaint);

    // Eye contour
    final eyePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * projHead.perspective
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(eyePt.offset.dx - 2.5 * scale, eyePt.offset.dy),
      Offset(eyePt.offset.dx + 2.5 * scale, eyePt.offset.dy),
      eyePaint,
    );

    // 2. Spine & Torso Path
    final pNeck = _project(_Point3D(-6 * scale, -22 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final pChest = _project(_Point3D(-16 * scale, -8 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final pLumbar = _project(_Point3D(-18 * scale, 10 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final pPelvis = _project(_Point3D(-8 * scale, 26 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

    final spinePath = Path()
      ..moveTo(projHead.offset.dx, projHead.offset.dy)
      ..quadraticBezierTo(pNeck.offset.dx, pNeck.offset.dy, pChest.offset.dx, pChest.offset.dy)
      ..quadraticBezierTo(pLumbar.offset.dx, pLumbar.offset.dy, pPelvis.offset.dx, pPelvis.offset.dy);

    final bodyPaint = Paint()
      ..color = const Color(0xFFFFB4C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0 * scale * projHead.perspective
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(spinePath, bodyPaint);

    // 3. Beating Heart with Concentric Doppler Waves
    final heartPt = _Point3D(4 * scale, -4 * scale, 5 * scale);
    final projHeart = _project(heartPt, cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final heartRadius = (7.5 * scale * (1.0 + 0.22 * cardiacPulse)) * projHeart.perspective;

    // Doppler concentric arcs
    if (cardiacPulse > 0.08) {
      final dopplerPaint = Paint()
        ..color = const Color(0xFFE11D48).withValues(alpha: (1.0 - cardiacPulse) * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(projHeart.offset, heartRadius * (1.3 + 0.9 * cardiacPulse), dopplerPaint);
      canvas.drawCircle(projHeart.offset, heartRadius * (1.7 + 1.2 * cardiacPulse), dopplerPaint);
    }

    final heartPaint = Paint()
      ..color = Color.lerp(const Color(0xFFFB7185), const Color(0xFFE11D48), cardiacPulse)!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(projHeart.offset, heartRadius, heartPaint);

    // 4. Arms & Hand near face
    final shoulderPt = _project(_Point3D(2 * scale, -14 * scale, 8 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final elbowPt = _project(_Point3D(14 * scale, -10 * scale, 10 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final handPt = _project(_Point3D(8 * scale, -24 * scale, 8 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

    final armPaint = Paint()
      ..color = const Color(0xFFFFCCD5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * scale * projHead.perspective
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final armPath = Path()
      ..moveTo(shoulderPt.offset.dx, shoulderPt.offset.dy)
      ..lineTo(elbowPt.offset.dx, elbowPt.offset.dy)
      ..lineTo(handPt.offset.dx, handPt.offset.dy);
    canvas.drawPath(armPath, armPaint);

    // 5. Bent Legs (Fetal Flexion)
    final hipPt = _project(_Point3D(-4 * scale, 22 * scale, 6 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final kneePt = _project(_Point3D(14 * scale, 18 * scale, 9 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final footPt = _project(_Point3D(4 * scale, 6 * scale, 8 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

    final legPath = Path()
      ..moveTo(hipPt.offset.dx, hipPt.offset.dy)
      ..lineTo(kneePt.offset.dx, kneePt.offset.dy)
      ..lineTo(footPt.offset.dx, footPt.offset.dy);
    canvas.drawPath(legPath, armPaint);

    // 6. Umbilical Cord
    final bellyPt = _project(_Point3D(2 * scale, 8 * scale, 6 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final cordEnd = _project(_Point3D(-38 * scale, 28 * scale, -12 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final cordControl = _project(_Point3D(-14 * scale, 26 * scale, 4 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

    final cordPath = Path()
      ..moveTo(bellyPt.offset.dx, bellyPt.offset.dy)
      ..quadraticBezierTo(cordControl.offset.dx, cordControl.offset.dy, cordEnd.offset.dx, cordEnd.offset.dy);

    final cordPaint = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * scale * projHead.perspective
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(cordPath, cordPaint);
  }

  // Stage 4: Full-Term Neonatal Curled Posture (Week 28–40)
  void _paintNeonatalTrimester3Stage({
    required Canvas canvas,
    required double R,
    required double centerX,
    required double centerY,
    required double focalLength,
    required double cosYaw,
    required double sinYaw,
    required double cosPitch,
    required double sinPitch,
    required double cardiacPulse,
  }) {
    // Mature fetus occupies significant womb volume
    final scale = 0.74 + (week - 28) * 0.014;

    // 1. Plump Head nestled down
    final headPt = _Point3D(2 * scale, -34 * scale, 0);
    final projHead = _project(headPt, cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final headRadius = 21.0 * scale * projHead.perspective;

    final headPaint = Paint()..color = const Color(0xFFFFCCD5);
    canvas.drawCircle(projHead.offset, headRadius, headPaint);

    // Cute chubby cheek & button nose
    final cheekPt = _project(_Point3D(14 * scale, -28 * scale, 6 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final cheekPaint = Paint()..color = const Color(0xFFFDA4AF).withValues(alpha: 0.45);
    canvas.drawCircle(cheekPt.offset, 8.0 * scale * projHead.perspective, cheekPaint);

    // Peaceful closed eye
    final eyePt = _project(_Point3D(10 * scale, -36 * scale, 8 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final eyePaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * projHead.perspective
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(eyePt.offset.dx - 3.5 * scale, eyePt.offset.dy),
      Offset(eyePt.offset.dx + 3.5 * scale, eyePt.offset.dy),
      eyePaint,
    );

    // 2. Full Curled Back & Torso hugging the womb contour
    final pNeck = _project(_Point3D(-8 * scale, -18 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final pMidBack = _project(_Point3D(-24 * scale, -2 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final pLowerBack = _project(_Point3D(-26 * scale, 18 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final pRump = _project(_Point3D(-14 * scale, 34 * scale, 0), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

    final spinePath = Path()
      ..moveTo(projHead.offset.dx, projHead.offset.dy)
      ..quadraticBezierTo(pNeck.offset.dx, pNeck.offset.dy, pMidBack.offset.dx, pMidBack.offset.dy)
      ..quadraticBezierTo(pLowerBack.offset.dx, pLowerBack.offset.dy, pRump.offset.dx, pRump.offset.dy);

    final backPaint = Paint()
      ..color = const Color(0xFFFFB4C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26.0 * scale * projHead.perspective
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(spinePath, backPaint);

    // 3. Ventral Abdomen / Round Tummy
    final tummyPt = _project(_Point3D(6 * scale, 10 * scale, 4 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final tummyPaint = Paint()..color = const Color(0xFFFFCCD5);
    canvas.drawCircle(tummyPt.offset, 16.0 * scale * projHead.perspective, tummyPaint);

    // 4. Beating Heart with Strong Doppler Wave Pulse
    final heartPt = _Point3D(4 * scale, -4 * scale, 6 * scale);
    final projHeart = _project(heartPt, cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final heartRadius = (8.5 * scale * (1.0 + 0.22 * cardiacPulse)) * projHeart.perspective;

    // Expanding cardiac Doppler waves
    if (cardiacPulse > 0.05) {
      final dopplerPaint = Paint()
        ..color = const Color(0xFFE11D48).withValues(alpha: (1.0 - cardiacPulse) * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(projHeart.offset, heartRadius * (1.25 + 0.9 * cardiacPulse), dopplerPaint);
      canvas.drawCircle(projHeart.offset, heartRadius * (1.65 + 1.2 * cardiacPulse), dopplerPaint);
    }

    final heartPaint = Paint()
      ..color = Color.lerp(const Color(0xFFFB7185), const Color(0xFFE11D48), cardiacPulse)!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(projHeart.offset, heartRadius, heartPaint);

    // 5. Flexed Neonatal Arms folded across chest
    final shoulderPt = _project(_Point3D(2 * scale, -16 * scale, 9 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final elbowPt = _project(_Point3D(16 * scale, -6 * scale, 12 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final handPt = _project(_Point3D(4 * scale, -18 * scale, 9 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

    final limbPaint = Paint()
      ..color = const Color(0xFFFFCCD5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5 * scale * projHead.perspective
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final armPath = Path()
      ..moveTo(shoulderPt.offset.dx, shoulderPt.offset.dy)
      ..lineTo(elbowPt.offset.dx, elbowPt.offset.dy)
      ..lineTo(handPt.offset.dx, handPt.offset.dy);
    canvas.drawPath(armPath, limbPaint);

    // 6. Deeply Bent Knees & Legs Tucked Up Tight
    final hipPt = _project(_Point3D(-8 * scale, 28 * scale, 8 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final kneePt = _project(_Point3D(16 * scale, 22 * scale, 12 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final footPt = _project(_Point3D(4 * scale, 6 * scale, 10 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

    final legPath = Path()
      ..moveTo(hipPt.offset.dx, hipPt.offset.dy)
      ..lineTo(kneePt.offset.dx, kneePt.offset.dy)
      ..lineTo(footPt.offset.dx, footPt.offset.dy);
    canvas.drawPath(legPath, limbPaint);

    // 7. Thick Umbilical Cord
    final bellyCord = _project(_Point3D(4 * scale, 12 * scale, 6 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final cordEnd = _project(_Point3D(-42 * scale, 34 * scale, -10 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);
    final cordControl = _project(_Point3D(-16 * scale, 30 * scale, 6 * scale), cosYaw, sinYaw, cosPitch, sinPitch, focalLength, centerX, centerY);

    final cordPath = Path()
      ..moveTo(bellyCord.offset.dx, bellyCord.offset.dy)
      ..quadraticBezierTo(cordControl.offset.dx, cordControl.offset.dy, cordEnd.offset.dx, cordEnd.offset.dy);

    final cordPaint = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * scale * projHead.perspective
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(cordPath, cordPaint);
  }

  @override
  bool shouldRepaint(_WombOrbPainter oldDelegate) {
    return oldDelegate.week != week ||
        oldDelegate.userYaw != userYaw ||
        oldDelegate.userPitch != userPitch ||
        oldDelegate.idlePrecession != idlePrecession ||
        oldDelegate.heartbeatProgress != heartbeatProgress;
  }
}

// ---------------------------------------------------------------------------
// Main Aurora3DWombVisualizer Widget
// ---------------------------------------------------------------------------

class Aurora3DWombVisualizer extends StatefulWidget {
  final int initialWeek;
  final ValueChanged<int>? onWeekChanged;
  final VoidCallback? onFilterPatients;
  final bool isCollapsible;
  final bool initiallyExpanded;

  const Aurora3DWombVisualizer({
    super.key,
    this.initialWeek = 20,
    this.onWeekChanged,
    this.onFilterPatients,
    this.isCollapsible = true,
    this.initiallyExpanded = true,
  });

  /// Static helper to retrieve biometrics data for any week.
  static FetalBiometrics getBiometricsForWeek(int week) => _getBiometricsForWeek(week);

  @override
  State<Aurora3DWombVisualizer> createState() => _Aurora3DWombVisualizerState();
}

class _Aurora3DWombVisualizerState extends State<Aurora3DWombVisualizer> with TickerProviderStateMixin {
  late int _currentWeek;
  late bool _isExpanded;

  double _userYaw = 0.0;
  double _userPitch = 0.0;

  late final AnimationController _heartbeatController;
  late final AnimationController _idleController;

  static const List<int> _quickJumpWeeks = [8, 12, 20, 28, 36, 40];

  @override
  void initState() {
    super.initState();
    _currentWeek = widget.initialWeek.clamp(1, 40);
    _isExpanded = widget.initiallyExpanded;

    // Doppler heartbeat pulse at ~140 bpm (428ms cycle)
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 430),
    )..repeat();

    // Smooth idle auto-rotation precession (22s full turn)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void didUpdateWidget(Aurora3DWombVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialWeek != oldWidget.initialWeek) {
      final clamped = widget.initialWeek.clamp(1, 40);
      if (clamped != _currentWeek) {
        setState(() {
          _currentWeek = clamped;
        });
      }
    }
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  void _resetView() {
    setState(() {
      _userYaw = 0.0;
      _userPitch = 0.0;
    });
  }

  void _setWeek(int week) {
    final clamped = week.clamp(1, 40);
    if (_currentWeek != clamped) {
      setState(() {
        _currentWeek = clamped;
      });
      widget.onWeekChanged?.call(clamped);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _userYaw += details.delta.dx * 0.012;
      _userPitch = (_userPitch - details.delta.dy * 0.012).clamp(-1.3, 1.3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bio = _getBiometricsForWeek(_currentWeek);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF5F8),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD1DC), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14E91E63),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(),
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFFFE4EC)),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _build3DCanvasBox(bio),
                        const SizedBox(width: 24),
                        Expanded(child: _buildBiometricsAndScrubberHUD(bio)),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _build3DCanvasBox(bio)),
                        const SizedBox(height: 20),
                        _buildBiometricsAndScrubberHUD(bio),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header Bar
  // ---------------------------------------------------------------------------
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD1DC)),
                  ),
                  child: const Text(
                    '🌟 3D Womb Explorer • Gestasi Maya',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBE185D),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Perkembangan Janin & Skala Minggu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Visualisasi 3D anatomi rahim & biometrik klinikal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Set Semula Putaran 3D',
            icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFFE11D48)),
            onPressed: _resetView,
          ),
          if (widget.isCollapsible)
            IconButton(
              tooltip: _isExpanded ? 'Tutup' : 'Buka',
              icon: Icon(
                _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: const Color(0xFF64748B),
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3D Canvas Box
  // ---------------------------------------------------------------------------
  Widget _build3DCanvasBox(FetalBiometrics bio) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD5E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0DE91E63),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              key: const ValueKey('aurora_3d_womb_gesture'),
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _onPanUpdate,
              onDoubleTap: _resetView,
              child: AnimatedBuilder(
                animation: Listenable.merge([_heartbeatController, _idleController]),
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(260, 260),
                    painter: _WombOrbPainter(
                      week: _currentWeek,
                      userYaw: _userYaw,
                      userPitch: _userPitch,
                      idlePrecession: _idleController.value * 2 * math.pi,
                      heartbeatProgress: _heartbeatController.value,
                    ),
                  );
                },
              ),
            ),
            // Doppler FHR Badge in top right
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCCD5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _heartbeatController,
                      builder: (context, _) {
                        final pulse = _heartbeatController.value < 0.22
                            ? math.sin((_heartbeatController.value / 0.22) * math.pi)
                            : 0.0;
                        return Transform.scale(
                          scale: 1.0 + 0.25 * pulse,
                          child: const Icon(Icons.favorite_rounded, color: Color(0xFFE11D48), size: 12),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bio.fhrRange == '-' ? 'Denyutan: -' : 'FHR: ${bio.fhrRange}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBE185D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Drag hint pill at bottom
            Positioned(
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD1DC)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFFBE185D)),
                    SizedBox(width: 4),
                    Text(
                      '🖱️ Heret untuk putar 3D',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Right Column: Biometrics & Scrubber HUD
  // ---------------------------------------------------------------------------
  Widget _buildBiometricsAndScrubberHUD(FetalBiometrics bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Week & Fruit Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE11D48), Color(0xFFBE185D)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x28E11D48),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Minggu $_currentWeek',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${bio.fruitEmoji} ${bio.fruit}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Text(
                'Trimester ${bio.trimester}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 4 Biometrics Metric Tiles
        LayoutBuilder(
          builder: (context, constraints) {
            final double tileWidth = constraints.maxWidth >= 320 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _buildMetricTile(
                  width: tileWidth,
                  icon: Icons.straighten_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBg: const Color(0xFFE0F2FE),
                  label: 'Panjang (CRL)',
                  value: bio.formattedCrl,
                ),
                _buildMetricTile(
                  width: tileWidth,
                  icon: Icons.monitor_weight_outlined,
                  iconColor: const Color(0xFF059669),
                  iconBg: const Color(0xFFD1FAE5),
                  label: 'Berat Janin',
                  value: bio.formattedWeight,
                ),
                _buildMetricTile(
                  width: tileWidth,
                  icon: Icons.circle_outlined,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFEF3C7),
                  label: 'Diameter Kepala (BPD)',
                  value: bio.formattedBpd,
                ),
                _buildMetricTile(
                  width: tileWidth,
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFE11D48),
                  iconBg: const Color(0xFFFFE4E6),
                  label: 'Denyutan Jantung',
                  value: bio.formattedFhr,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // Dr. Aurora Clinical Milestone Callout
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFCCD5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.medical_services_outlined,
                  size: 18,
                  color: Color(0xFFBE185D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🩺 Dr. Aurora • Nota Klinikal Minggu $_currentWeek',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9F1239),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bio.milestone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Gestational Scrubber Slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Skala Gestasi (Minggu 1 – 40):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Minggu $_currentWeek / 40',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFE11D48),
                inactiveTrackColor: const Color(0xFFFFD1DC),
                trackHeight: 6,
                thumbColor: const Color(0xFFBE185D),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                overlayColor: const Color(0x28E11D48),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                value: _currentWeek.toDouble(),
                min: 1.0,
                max: 40.0,
                divisions: 39,
                label: 'Minggu $_currentWeek',
                onChanged: (val) => _setWeek(val.round()),
              ),
            ),
          ],
        ),

        // Quick Jump Chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _quickJumpWeeks.map((w) {
            final isSelected = _currentWeek == w;
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _setWeek(w),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE11D48) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE11D48) : const Color(0xFFFFD1DC),
                  ),
                ),
                child: Text(
                  'W$w',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Optional Bottom Filter CTA
        if (widget.onFilterPatients != null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFBE185D),
              side: const BorderSide(color: Color(0xFFFFB4C8)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.filter_list_rounded, size: 16),
            label: Text(
              'Tapis Pesakit Minggu Ini ($_currentWeek)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: widget.onFilterPatients,
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Metric Tile Helper
  // ---------------------------------------------------------------------------
  Widget _buildMetricTile({
    required double width,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE4EC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
