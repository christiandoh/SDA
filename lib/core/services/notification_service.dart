import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notifications locales (sans Internet) pour alertes HSE (ex. stock critique).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'hse_alerts',
    'Alertes HSE',
    description: 'Alertes stock critique et rappels',
    importance: Importance.defaultImportance,
  );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelect,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    _initialized = true;
  }

  void _onSelect(NotificationResponse response) {
    // Optionnel : ouvrir un écran selon payload
  }

  /// Affiche une notification d'alerte stock critique.
  Future<void> showStockAlert(String epiDesignation, int stock) async {
    await init();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(
      epiDesignation.hashCode % 0x7FFFFFFF,
      'Stock critique',
      '$epiDesignation : $stock restant(s). Réapprovisionner.',
      details,
    );
  }
}
