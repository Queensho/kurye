import 'package:flutter/material.dart';

import 'courier_home_page.dart';
import 'courier_job_pool_page.dart';
import 'courier_profile_page.dart';
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

  String get path => Uri.decodeComponent(Uri.base.path).toLowerCase();

  bool get isCustomerPath =>
      path.contains('/müsteri') ||
      path.contains('/müşteri') ||
      path.contains('/musteri');

  bool get isJobPoolPath =>
      path.contains('/havuz') || path.contains('/is-havuzu') || path.contains('/iş-havuzu');

  bool get isCourierProfilePath =>
      path.contains('/profil') || path.contains('/kurye-profili');

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (isCustomerPath) {
      home = const HomePixelPreview();
    } else if (isJobPoolPath) {
      home = const CourierJobPoolPage();
    } else if (isCourierProfilePath) {
      home = const CourierProfilePage();
    } else {
      home = const CourierHomePage();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: isCustomerPath ? 'Kurye Müşteri' : 'Kurye',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FBFF),
        visualDensity: VisualDensity.compact,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF168CF5)),
      ),
      builder: (context, child) {
        if (child == null || isCustomerPath) return child ?? const SizedBox.shrink();

        final mq = MediaQuery.of(context);
        final width = mq.size.width;

        // Kurye tarafındaki tüm ekranlarda aynı responsive ölçeği kullan.
        // 360px ve altı telefonlarda taşmayı önlemek için yazılar kontrollü küçülür,
        // 390-430px aralığında referans tasarım oranı korunur.
        final scale = (width / 430).clamp(0.84, 1.0);

        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        );
      },
      home: home,
    );
  }
}
