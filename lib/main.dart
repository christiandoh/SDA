import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/local_db_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDbService.instance.init();
  await NotificationService.instance.init();
  runApp(const App());
}
