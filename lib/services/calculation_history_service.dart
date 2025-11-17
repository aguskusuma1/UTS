import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_history_model.dart';

class CalculationHistoryService {
  static const String _historyKey = 'calculation_history';

  // Save calculation to history
  static Future<void> saveCalculation(CalculationHistoryModel calculation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      
      // Add new calculation to the beginning of the list
      history.insert(0, calculation);
      
      // Limit to last 100 calculations
      if (history.length > 100) {
        history.removeRange(100, history.length);
      }
      
      // Convert to JSON
      final historyJson = history.map((calc) => calc.toMap()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyJson));
    } catch (e) {
      print('Error saving calculation: $e');
      rethrow;
    }
  }

  // Get all calculation history
  static Future<List<CalculationHistoryModel>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList
          .map((map) => CalculationHistoryModel.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting history: $e');
      return [];
    }
  }

  // Delete a specific calculation
  static Future<void> deleteCalculation(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      
      history.removeWhere((calc) => calc.id == id);
      
      final historyJson = history.map((calc) => calc.toMap()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyJson));
    } catch (e) {
      print('Error deleting calculation: $e');
      rethrow;
    }
  }

  // Clear all history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing history: $e');
      rethrow;
    }
  }

  // Get history count
  static Future<int> getHistoryCount() async {
    final history = await getHistory();
    return history.length;
  }
}

