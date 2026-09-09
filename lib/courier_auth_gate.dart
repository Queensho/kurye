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
  bool pendingApproval = false;
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
      pendingApproval = false;
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
      final value = await data.client.rpc('get_current_courier_account');
      if (!mounted) return;

      if (value == null) {
        await data.signOut();
        if (!mounted) return;
        setState(() {
          checking = false;
          allowed = false;
          message = 'Bu oturum kurye hesabına ait değil. Kurye hesabınla giriş yap.';
        });
        return;
      }

      final courier = Map<String, dynamic>.from(value as Map);

      if (courier['account_status'] == 'suspended') {
        await data.signOut();
        if (!mounted) return;
        setState(() {
          checking = false;
          allowed = false;
          message = 'Bu kurye hesabı askıya alınmış. Destek ile iletişime geç.';
        });
        return;
      }

      if (courier['is_approved'] != true) {
        setState(() {
          checking = false;
          allowed = false;
          pendingApproval = true;
        });
        return;
      }

      setState(() {
        checking = false;
        allowed = true;
        pendingApproval = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        checking = false;
        allowed = false;
        message = 'Kurye hesabı doğrulanamadı. Tekrar giriş yap.';
      });
    }
  }

  Future<void> _logout() async {
    await data.signOut();
    if (mounted) await _check();
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F8FC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (pendingApproval) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F8FC),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: Color(0xFFE8F4FF),
                      child: Icon(Icons.hourglass_top_rounded, size: 44, color: Color(0xFF168CF5)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Kurye başvurun inceleniyor',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF10213E)),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Hesabın oluşturuldu. Admin onayından sonra online olabilir, iş havuzunu görebilir, konum paylaşabilir ve kazanç alanını kullanabilirsin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF74839A), height: 1.45),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _check,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Onay Durumunu Yenile', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(onPressed: _logout, child: const Text('Çıkış Yap')),
                  ],
                ),
              ),
            ),
          ),
        ),
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
