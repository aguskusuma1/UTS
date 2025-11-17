import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cable_model.dart';
import '../models/calculation_history_model.dart';
import '../services/voltage_drop_calculator.dart';
import '../services/calculation_history_service.dart';
import 'calculation_history_screen.dart';

class VoltageDropCalculatorScreen extends StatefulWidget {
  const VoltageDropCalculatorScreen({super.key});

  @override
  State<VoltageDropCalculatorScreen> createState() =>
      _VoltageDropCalculatorScreenState();
}

class _VoltageDropCalculatorScreenState
    extends State<VoltageDropCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _voltageController = TextEditingController(text: '220');
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _resistanceController = TextEditingController();

  CableModel? _selectedCable;
  VoltageDropResult? _calculationResult;
  List<CableModel> _availableCables = CableDatabase.getCables();

  @override
  void initState() {
    super.initState();
    if (_availableCables.isNotEmpty) {
      _selectedCable = _availableCables[0];
      _resistanceController.text = _selectedCable!.resistance.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _voltageController.dispose();
    _currentController.dispose();
    _lengthController.dispose();
    _resistanceController.dispose();
    super.dispose();
  }

  void _calculate() async {
    if (_formKey.currentState!.validate()) {
      final voltage = double.parse(_voltageController.text);
      final current = double.parse(_currentController.text);
      final length = double.parse(_lengthController.text);
      final resistance = double.parse(_resistanceController.text);

      final result = VoltageDropCalculator.calculate(
        voltage: voltage,
        current: current,
        length: length,
        resistance: resistance,
      );

      setState(() {
        _calculationResult = result;
      });

      // Save to history
      try {
        final historyModel = CalculationHistoryModel.fromCalculation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          voltage: voltage,
          current: current,
          length: length,
          resistance: resistance,
          cableName: _selectedCable?.name ?? 'Custom',
          voltageDropVolts: result.voltageDropVolts,
          voltageDropPercent: result.voltageDropPercent,
          remainingVoltage: result.remainingVoltage,
          remainingVoltagePercent: result.remainingVoltagePercent,
          isValid: result.isValid,
          warning: result.warning,
        );
        await CalculationHistoryService.saveCalculation(historyModel);
      } catch (e) {
        // Error saving to history, but don't show error to user
        print('Error saving to history: $e');
      }

      // Scroll to result
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onCableChanged(CableModel? cable) {
    setState(() {
      _selectedCable = cable;
      if (cable != null) {
        _resistanceController.text = cable.resistance.toStringAsFixed(2);
      }
    });
  }

  void _recommendCable() {
    if (_formKey.currentState!.validate() && _currentController.text.isNotEmpty && _lengthController.text.isNotEmpty) {
      final voltage = double.parse(_voltageController.text);
      final current = double.parse(_currentController.text);
      final length = double.parse(_lengthController.text);

      final recommended = VoltageDropCalculator.recommendCable(
        voltage: voltage,
        current: current,
        length: length,
        maxVoltageDropPercent: 5.0,
      );

      if (recommended != null) {
        setState(() {
          // Cari instance yang sama dari _availableCables untuk memastikan DropdownButton bisa mencocokkannya
          _selectedCable = _availableCables.firstWhere(
            (cable) => cable.name == recommended.name,
            orElse: () => recommended,
          );
          _resistanceController.text = _selectedCable!.resistance.toStringAsFixed(2);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kabel yang direkomendasikan: ${recommended.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada kabel yang sesuai. Perlu ukuran kabel khusus atau kurangi arus beban.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Drop Tegangan JTR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalculationHistoryScreen(),
                ),
              );
            },
            tooltip: 'History Perhitungan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.electrical_services,
                        size: 48,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kalkulator Drop Tegangan JTR',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hitung drop tegangan pada Jaringan Tegangan Rendah',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Input Fields
              TextFormField(
                controller: _voltageController,
                decoration: const InputDecoration(
                  labelText: 'Tegangan Sumber (Volt)',
                  hintText: '220',
                  prefixIcon: Icon(Icons.bolt),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan tegangan sumber';
                  }
                  final voltage = double.tryParse(value);
                  if (voltage == null || voltage <= 0) {
                    return 'Tegangan harus lebih dari 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _currentController,
                decoration: const InputDecoration(
                  labelText: 'Arus Beban (Ampere)',
                  hintText: '10',
                  prefixIcon: Icon(Icons.flash_on),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan arus beban';
                  }
                  final current = double.tryParse(value);
                  if (current == null || current <= 0) {
                    return 'Arus harus lebih dari 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _lengthController,
                decoration: const InputDecoration(
                  labelText: 'Panjang Kabel (meter)',
                  hintText: '100',
                  prefixIcon: Icon(Icons.straighten),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan panjang kabel';
                  }
                  final length = double.tryParse(value);
                  if (length == null || length <= 0) {
                    return 'Panjang harus lebih dari 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Cable Selection Dropdown
              DropdownButtonFormField<CableModel>(
                value: _selectedCable,
                decoration: const InputDecoration(
                  labelText: 'Jenis Kabel',
                  prefixIcon: Icon(Icons.cable),
                  border: OutlineInputBorder(),
                ),
                items: _availableCables.map((cable) {
                  return DropdownMenuItem(
                    value: cable,
                    child: Text(
                      '${cable.name} (R: ${cable.resistance.toStringAsFixed(2)} Ω/km)',
                    ),
                  );
                }).toList(),
                onChanged: _onCableChanged,
                validator: (value) {
                  if (value == null) {
                    return 'Pilih jenis kabel';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              // Manual Resistance Input
              TextFormField(
                controller: _resistanceController,
                decoration: const InputDecoration(
                  labelText: 'Resistansi Kabel (Ohm/km)',
                  hintText: '5.0',
                  prefixIcon: Icon(Icons.speed),
                  border: OutlineInputBorder(),
                  helperText: 'Atau masukkan resistansi secara manual',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan resistansi kabel';
                  }
                  final resistance = double.tryParse(value);
                  if (resistance == null || resistance <= 0) {
                    return 'Resistansi harus lebih dari 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _recommendCable,
                      icon: const Icon(Icons.recommend),
                      label: const Text('Rekomendasi Kabel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Hitung'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              // Result Card
              if (_calculationResult != null) ...[
                const SizedBox(height: 32),
                Card(
                  color: _calculationResult!.isValid
                      ? Colors.green[50]
                      : Colors.red[50],
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _calculationResult!.isValid
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _calculationResult!.isValid
                                  ? Colors.green
                                  : Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Hasil Perhitungan',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _calculationResult!.isValid
                                      ? Colors.green[900]
                                      : Colors.red[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildResultRow(
                          'Drop Tegangan',
                          '${_calculationResult!.voltageDropVolts.toStringAsFixed(2)} V',
                          '${_calculationResult!.voltageDropPercent.toStringAsFixed(2)}%',
                        ),
                        const Divider(),
                        _buildResultRow(
                          'Tegangan di Beban',
                          '${_calculationResult!.remainingVoltage.toStringAsFixed(2)} V',
                          '${_calculationResult!.remainingVoltagePercent.toStringAsFixed(2)}%',
                        ),
                        if (_calculationResult!.warning != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: Colors.orange[900],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _calculationResult!.warning!,
                                    style: TextStyle(
                                      color: Colors.orange[900],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Catatan: Drop tegangan maksimal untuk JTR adalah 5% (SNI)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value1, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value1,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value2,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

