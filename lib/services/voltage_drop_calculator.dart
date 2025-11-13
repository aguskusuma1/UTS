import '../models/cable_model.dart';

class VoltageDropResult {
  final double voltageDropVolts;
  final double voltageDropPercent;
  final double remainingVoltage;
  final double remainingVoltagePercent;
  final bool isValid;
  final String? warning;

  VoltageDropResult({
    required this.voltageDropVolts,
    required this.voltageDropPercent,
    required this.remainingVoltage,
    required this.remainingVoltagePercent,
    required this.isValid,
    this.warning,
  });
}

class VoltageDropCalculator {
  // Menghitung drop tegangan untuk JTR (Jaringan Tegangan Rendah)
  // Rumus: V_drop = I × R × L × 2
  // Dimana:
  // - I = Arus (Ampere)
  // - R = Resistansi per km (Ohm/km)
  // - L = Panjang kabel (km)
  // - Faktor 2 karena ada kabel fasa dan netral

  static VoltageDropResult calculate({
    required double voltage, // Tegangan sumber (Volt)
    required double current, // Arus beban (Ampere)
    required double length, // Panjang kabel (meter)
    required double resistance, // Resistansi kabel (Ohm/km)
  }) {
    // Konversi panjang dari meter ke kilometer
    final lengthKm = length / 1000;

    // Hitung drop tegangan dalam Volt
    // Faktor 2 karena ada kabel fasa dan netral (hantaran bolak-balik)
    final voltageDropVolts = current * resistance * lengthKm * 2;

    // Hitung persentase drop tegangan
    final voltageDropPercent = (voltageDropVolts / voltage) * 100;

    // Hitung tegangan yang tersisa di beban
    final remainingVoltage = voltage - voltageDropVolts;
    final remainingVoltagePercent = (remainingVoltage / voltage) * 100;

    // Validasi: Drop tegangan maksimal 5% untuk JTR (SNI)
    bool isValid = voltageDropPercent <= 5.0 && remainingVoltagePercent >= 95.0;
    
    String? warning;
    if (voltageDropPercent > 5.0) {
      warning = 'Drop tegangan melebihi 5%! Gunakan kabel dengan ukuran lebih besar atau kurangi panjang kabel.';
    } else if (voltageDropPercent > 3.0) {
      warning = 'Drop tegangan mendekati batas maksimal (5%). Pertimbangkan menggunakan kabel yang lebih besar.';
    }

    return VoltageDropResult(
      voltageDropVolts: voltageDropVolts,
      voltageDropPercent: voltageDropPercent,
      remainingVoltage: remainingVoltage,
      remainingVoltagePercent: remainingVoltagePercent,
      isValid: isValid,
      warning: warning,
    );
  }

  // Menghitung ukuran kabel minimum berdasarkan drop tegangan yang diizinkan
  static CableModel? recommendCable({
    required double voltage,
    required double current,
    required double length,
    required double maxVoltageDropPercent, // Maksimal drop tegangan dalam persen
  }) {
    final availableCables = CableDatabase.getCables();
    
    // Filter kabel yang memiliki ampacity cukup
    final suitableCables = availableCables.where((cable) {
      return cable.ampacity >= current * 1.25; // Faktor keamanan 1.25
    }).toList();

    if (suitableCables.isEmpty) {
      return null;
    }

    // Hitung resistansi maksimal yang diizinkan
    final lengthKm = length / 1000;
    final maxVoltageDropVolts = (voltage * maxVoltageDropPercent) / 100;
    final maxResistance = maxVoltageDropVolts / (current * lengthKm * 2);

    // Cari kabel dengan resistansi yang memenuhi syarat
    final recommendedCables = suitableCables.where((cable) {
      return cable.resistance <= maxResistance;
    }).toList();

    if (recommendedCables.isEmpty) {
      return suitableCables.first; // Ambil yang terkecil dengan ampacity cukup
    }

    // Return kabel dengan resistansi terendah yang memenuhi syarat
    recommendedCables.sort((a, b) => a.resistance.compareTo(b.resistance));
    return recommendedCables.first;
  }
}

