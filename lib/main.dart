import 'package:flutter/material.dart';

import 'courier_home_page.dart';
import 'data/app_data_service.dart';
import 'home_pixel_preview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppDataService.instance.initialize();
  } catch (_) {
    // Backend bağlantısı hazır olmasa bile arayüzleri aç.
  }
  runApp(const KuryeApp());
}

class KuryeApp extends StatelessWidget {
  const KuryeApp({super.key});

  bool get isCustomerPath {
    final path = Uri.decodeComponent(Uri.base.path).toLowerCase();
    return path.contains('/müsteri') ||
        path.contains('/müşteri') ||
        path.contains('/musteri');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: isCustomerPath ? 'Kurye Müşteri' : 'Kurye',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FBFF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF168CF5)),
      ),
      home: isCustomerPath
          ? const HomePixelPreview()
          : const CourierHomePage(),
    );
  }
}
