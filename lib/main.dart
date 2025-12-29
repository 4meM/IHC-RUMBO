import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'injection_container.dart' as di;
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Hive
  await Hive.initFlutter();
  
  // Inicializar notificaciones
  await NotificationService().initialize();
  
  // Inicializar GetIt (Dependency Injection)
  await di.init();

  // TODO: Inicializar WebSockets/Sockets para Live Tracking
  // TODO: Inicializar Background Service

  runApp(const RumboApp());
}
