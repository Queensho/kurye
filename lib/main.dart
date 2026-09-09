import 'package:flutter/material.dart';

import 'data/app_data_service.dart';
import 'home_pixel_preview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;
  try {
    await AppDataService.instance.initialize();
  } catch (e) {
    startupError = e;
  }
  runApp(KuryeApp(startupError: startupError));
}

class KuryeApp extends StatelessWidget {
  const KuryeApp({super.key, this.startupError});

  final Object? startupError;

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
      home: startupError == null
          ? const HomePixelPreview()
          : _BackendErrorPage(error: startupError!),
    );
  }
}

class _BackendErrorPage extends StatelessWidget {
  const _BackendErrorPage({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFF168CF5)),
                const SizedBox(height: 16),
                const Text(
                  'Veri bağlantısı kurulamadı',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Supabase Anonymous Sign-Ins ayarının açık olduğundan ve internet bağlantısından emin ol.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
