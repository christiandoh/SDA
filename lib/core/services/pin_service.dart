import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion du code PIN (connexion). Code par défaut : 0000.
class PinService {
  PinService._();
  static final PinService instance = PinService._();

  static const String _keyPin = 'app_pin';
  static const String _keyUserName = 'user_name';
  static const String defaultPin = '0000';

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyUserName);
    return name != null && name.trim().isNotEmpty ? name.trim() : null;
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name.trim());
  }

  Future<String> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPin) ?? defaultPin;
  }

  Future<void> setPin(String pin) async {
    if (pin.length != 4) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPin, pin);
  }

  Future<bool> validatePin(String input) async {
    final pin = await getPin();
    return pin == input;
  }
}
