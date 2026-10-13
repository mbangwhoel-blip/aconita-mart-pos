import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aconita_mart_pos/core/theme/app_theme.dart';
import 'package:aconita_mart_pos/core/utils/date_formatter.dart';
import 'package:aconita_mart_pos/core/services/api_service.dart';
import 'package:aconita_mart_pos/core/services/sync_service.dart';
import 'package:aconita_mart_pos/data/database/database_helper.dart';
import 'package:aconita_mart_pos/presentation/screens/mart_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Load environment variables if available
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Initialize database & services
  await DatabaseHelper.instance.database;
  await ApiService.instance.initialize();
  await SyncService.instance.initialize();
  await DateFormatter.initialize();

  runApp(const AconitaMartApp());
}

class AconitaMartApp extends StatelessWidget {
  const AconitaMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aconita Mart POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MartDashboardScreen(),
    );
  }
}
