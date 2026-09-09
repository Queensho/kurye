import 'package:flutter/material.dart';

import 'courier_home_page.dart';
import 'data/app_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppDataService.instance.initialize();
  } catch (_) {
    // Backend auth may not be enabled yet. Keep the courier UI usable
    // instead of blocking the whole application during setup.
  }
  runApp(const KuryeApp());
}

class KuryeApp extends StatelessWidget {
  const KuryeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kurye',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FBFF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF168CF5)),
      ),
      home: const CourierHomePage(),
    );
  }
}
