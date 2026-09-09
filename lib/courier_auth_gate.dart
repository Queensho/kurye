import 'dart:async';

import 'package:flutter/material.dart';

import 'courier_auth_page.dart';
import 'data/app_data_service.dart';

class CourierAuthGate extends StatefulWidget {
  const CourierAuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<CourierAuthGate> createState() => _CourierAuthGateState();
}

class _CourierAuthGateState extends State<CourierAuthGate> {
  final data = AppDataService.instance;
  StreamSubscription? authSub;
  bool checking = true;
  bool allowed = false;
  String? message;

  @override
  void initState() {
    super.initState();
    authSub = data.client.auth.onAuthStateChange.listen((_) => _check());
    _check();
  }

  @override
  void dispose() {
    authSub?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (!mounted) return;
    setState(() {
      checking = true;
      message = null;
    });

    if (!data.isSignedIn) {
      if (!mounted) return;
      setState(() {
        checking = false;
        allowed = false;
      });
      return;
    }

    try {
      final courier = await data.client
          .from('couriers')
          .select('user_id,is_approved,is_online,vehicle_type')
          .eq('user_id', data.userId)
          .maybeSingle();
      final profile = await data.client
          .from('profiles')
          .select('account_status')
          .eq('id', data.userId)
          .maybeSingle();

      if (!mounted) return;
      if (profile?['account_status'] == 'suspended') {
        await data.client.auth.signOut();
        setState(() {
          checking = false;
          allowed = false;
          message = 'Bu kurye hesabı askıya alınmış.';
        });
        return;
      }

      if (courier == null) {
        setState(() {
          checking = false;
          allowed = false;
          message = 'Açık oturum bir kurye hesabına ait değil. Kurye hesabınla giriş yap.';
        });
        return;
      }

      setState(() {
        checking = false;
        allowed = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        checking = false;
        allowed = false;
        message = 'Kurye hesabı doğrulanamadı: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F8FC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!allowed) {
      return CourierAuthPage(
        initialMessage: message,
        onAuthenticated: _check,
      );
    }

    return widget.child;
  }
}
