import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _hitCountKey = 'guest_hit_count';
  static const int _maxHitCount = 3; // Batas maksimal penggunaan tanpa login

  // Cek apakah onboarding sudah selesai
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // Set onboarding sebagai selesai
  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, value);
  }

  // Reset onboarding (untuk testing)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }

  // ========== Hit Counter untuk Guest Access ==========

  // Get hit count saat ini
  static Future<int> getHitCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_hitCountKey) ?? 0;
  }

  // Increment hit count
  static Future<int> incrementHitCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_hitCountKey) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(_hitCountKey, newCount);
    return newCount;
  }

  // Cek apakah masih bisa menggunakan fitur (belum mencapai limit)
  static Future<bool> canUseFeature() async {
    final count = await getHitCount();
    return count < _maxHitCount;
  }

  // Cek apakah sudah mencapai limit
  static Future<bool> hasReachedLimit() async {
    final count = await getHitCount();
    return count >= _maxHitCount;
  }

  // Get sisa penggunaan
  static Future<int> getRemainingUsage() async {
    final count = await getHitCount();
    final remaining = _maxHitCount - count;
    return remaining > 0 ? remaining : 0;
  }

  // Reset hit count (untuk testing atau setelah login)
  static Future<void> resetHitCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hitCountKey);
  }

  // Get max hit count
  static int get maxHitCount => _maxHitCount;
}

