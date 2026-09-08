import 'dart:async';

import 'package:flutter/material.dart';
import 'courier_found_page.dart';
import 'pickup_status_page.dart';

class CourierFoundFlowPage extends StatefulWidget {
  const CourierFoundFlowPage({super.key});

  @override
  State<CourierFoundFlowPage> createState() => _CourierFoundFlowPageState();
}

class _CourierFoundFlowPageState extends State<CourierFoundFlowPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PickupStatusPage()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const CourierFoundPage();
}
