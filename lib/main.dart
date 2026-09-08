import 'package:flutter/material.dart';
import 'home_pixel_preview.dart';

void main() {
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
        scaffoldBackgroundColor: const Color(0xFFF6FBFF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF178EF4)),
      ),
      home: const HomePixelPreview(),
    );
  }
}
