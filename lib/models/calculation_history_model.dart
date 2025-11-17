class CalculationHistoryModel {
  final String id;
  final DateTime timestamp;
  final double voltage;
  final double current;
  final double length;
  final double resistance;
  final String cableName;
  final double voltageDropVolts;
  final double voltageDropPercent;
  final double remainingVoltage;
  final double remainingVoltagePercent;
  final bool isValid;
  final String? warning;

  CalculationHistoryModel({
    required this.id,
    required this.timestamp,
    required this.voltage,
    required this.current,
    required this.length,
    required this.resistance,
    required this.cableName,
    required this.voltageDropVolts,
    required this.voltageDropPercent,
    required this.remainingVoltage,
    required this.remainingVoltagePercent,
    required this.isValid,
    this.warning,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'voltage': voltage,
      'current': current,
      'length': length,
      'resistance': resistance,
      'cableName': cableName,
      'voltageDropVolts': voltageDropVolts,
      'voltageDropPercent': voltageDropPercent,
      'remainingVoltage': remainingVoltage,
      'remainingVoltagePercent': remainingVoltagePercent,
      'isValid': isValid,
      'warning': warning,
    };
  }

  // Create from Map
  factory CalculationHistoryModel.fromMap(Map<String, dynamic> map) {
    return CalculationHistoryModel(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      voltage: (map['voltage'] as num).toDouble(),
      current: (map['current'] as num).toDouble(),
      length: (map['length'] as num).toDouble(),
      resistance: (map['resistance'] as num).toDouble(),
      cableName: map['cableName'] as String,
      voltageDropVolts: (map['voltageDropVolts'] as num).toDouble(),
      voltageDropPercent: (map['voltageDropPercent'] as num).toDouble(),
      remainingVoltage: (map['remainingVoltage'] as num).toDouble(),
      remainingVoltagePercent: (map['remainingVoltagePercent'] as num).toDouble(),
      isValid: map['isValid'] as bool,
      warning: map['warning'] as String?,
    );
  }

  // Create from calculation result
  factory CalculationHistoryModel.fromCalculation({
    required String id,
    required DateTime timestamp,
    required double voltage,
    required double current,
    required double length,
    required double resistance,
    required String cableName,
    required double voltageDropVolts,
    required double voltageDropPercent,
    required double remainingVoltage,
    required double remainingVoltagePercent,
    required bool isValid,
    String? warning,
  }) {
    return CalculationHistoryModel(
      id: id,
      timestamp: timestamp,
      voltage: voltage,
      current: current,
      length: length,
      resistance: resistance,
      cableName: cableName,
      voltageDropVolts: voltageDropVolts,
      voltageDropPercent: voltageDropPercent,
      remainingVoltage: remainingVoltage,
      remainingVoltagePercent: remainingVoltagePercent,
      isValid: isValid,
      warning: warning,
    );
  }
}

