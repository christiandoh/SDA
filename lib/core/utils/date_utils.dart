/// Utilitaires de formatage (dates, etc.).
class AppDateUtils {
  AppDateUtils._();

  /// Formate une date ISO en JJ/MM/AAAA.
  static String formatIsoToDisplay(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  /// Retourne la date du jour au format ISO.
  static String todayIso() => DateTime.now().toIso8601String();
}
