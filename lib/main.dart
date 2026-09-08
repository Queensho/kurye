import 'package:flutter/material.dart';
import 'create_shipment_page.dart';

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
        scaffoldBackgroundColor: const Color(0xFFF7FBFF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF168CF5)),
      ),
      home: const CreateShipmentPage(),
    );
  }
}
