class CableModel {
  final String name;
  final double resistance; // Ohm/km
  final double ampacity; // Ampere
  final double diameter; // mm²

  CableModel({
    required this.name,
    required this.resistance,
    required this.ampacity,
    required this.diameter,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CableModel &&
        other.name == name &&
        other.resistance == resistance &&
        other.ampacity == ampacity &&
        other.diameter == diameter;
  }

  @override
  int get hashCode {
    return Object.hash(name, resistance, ampacity, diameter);
  }
}

class CableDatabase {
  static List<CableModel> getCables() {
    return [
      CableModel(
        name: 'NYA 1.5 mm²',
        resistance: 13.3,
        ampacity: 19,
        diameter: 1.5,
      ),
      CableModel(
        name: 'NYA 2.5 mm²',
        resistance: 8.0,
        ampacity: 27,
        diameter: 2.5,
      ),
      CableModel(
        name: 'NYA 4 mm²',
        resistance: 5.0,
        ampacity: 36,
        diameter: 4.0,
      ),
      CableModel(
        name: 'NYA 6 mm²',
        resistance: 3.3,
        ampacity: 46,
        diameter: 6.0,
      ),
      CableModel(
        name: 'NYA 10 mm²',
        resistance: 2.0,
        ampacity: 63,
        diameter: 10.0,
      ),
      CableModel(
        name: 'NYA 16 mm²',
        resistance: 1.25,
        ampacity: 85,
        diameter: 16.0,
      ),
      CableModel(
        name: 'NYA 25 mm²',
        resistance: 0.8,
        ampacity: 115,
        diameter: 25.0,
      ),
      CableModel(
        name: 'NYA 35 mm²',
        resistance: 0.57,
        ampacity: 140,
        diameter: 35.0,
      ),
      CableModel(
        name: 'NYA 50 mm²',
        resistance: 0.4,
        ampacity: 175,
        diameter: 50.0,
      ),
      CableModel(
        name: 'NYA 70 mm²',
        resistance: 0.29,
        ampacity: 220,
        diameter: 70.0,
      ),
      CableModel(
        name: 'NYA 95 mm²',
        resistance: 0.21,
        ampacity: 270,
        diameter: 95.0,
      ),
      CableModel(
        name: 'NYA 120 mm²',
        resistance: 0.17,
        ampacity: 315,
        diameter: 120.0,
      ),
    ];
  }
}

