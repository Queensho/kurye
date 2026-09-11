import 'dart:async';

import 'package:flutter/material.dart';

import 'courier_active_job_realtime_page.dart';
import 'courier_auth_page.dart';
import 'data/app_data_service.dart';

class CourierAuthGate extends StatefulWidget {
  const CourierAuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<CourierAuthGate> createState() => _CourierAuthGateState();
}

class _CourierAuthGateState extends State<CourierAuthGate>
    with WidgetsBindingObserver {
  final data = AppDataService.instance;
  StreamSubscription? authSub;
  StreamSubscription<Map<String, dynamic>>? courierSub;
  Timer? heartbeatTimer;
  bool checking = true;
  bool allowed = false;
  bool pendingApproval = false;
  bool courierOnline = false;
  Map<String, dynamic>? activeShipment;
  String? message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    authSub = data.client.auth.onAuthStateChange.listen((_) => _check());
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    heartbeatTimer?.cancel();
    courierSub?.cancel();
    authSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && allowed && courierOnline) {
      _startPresence();
      _refreshActiveShipment();
    }
  }

  void _watchCourierState() {
    courierSub?.cancel();
    if (!data.isSignedIn || !allowed) return;
    courierSub = data.watchCourierLocation(data.userId).listen((row) {
      if (!mounted || row.isEmpty) return;
      final nextOnline = row['is_online'] == true;
      if (nextOnline == courierOnline) return;
      courierOnline = nextOnline;
      if (nextOnline) {
        unawaited(_startPresence());
      } else {
        heartbeatTimer?.cancel();
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _startPresence() async {
    heartbeatTimer?.cancel();
    if (!data.isSignedIn || !courierOnline) return;

    Future<void> beat() async {
      if (!data.isSignedIn || !courierOnline) return;
      try {
        final value = await data.client.rpc('courier_heartbeat');
        if (value is Map && value['is_online'] != true) {
          courierOnline = false;
          heartbeatTimer?.cancel();
          if (mounted) setState(() {});
        }
      } catch (_) {
        // Ağ kesintisinde heartbeat gönderilemez. Sunucu 3 dakika içinde
        // stale kuryeyi otomatik offline yapar.
      }
    }

    await beat();
    if (!courierOnline) return;
    unawaited(data.startCourierLocationTracking());
    heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(beat()),
    );
  }

  Future<void> _refreshActiveShipment() async {
    if (!data.isSignedIn || !allowed) return;
    try {
      final value = await data.client.rpc('get_active_courier_shipment');
      if (!mounted) return;
      setState(() {
        activeShipment = value == null
            ? null
            : Map<String, dynamic>.from(value as Map);
      });
    } catch (_) {}
  }

  Future<void> _check() async {
    if (!mounted) return;
    setState(() {
      checking = true;
      message = null;
      pendingApproval = false;
    });

    if (!data.isSignedIn) {
      heartbeatTimer?.cancel();
      await courierSub?.cancel();
      courierSub = null;
      courierOnline = false;
      activeShipment = null;
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
        heartbeatTimer?.cancel();
        await courierSub?.cancel();
        courierSub = null;
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
        heartbeatTimer?.cancel();
        await courierSub?.cancel();
        courierSub = null;
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
        heartbeatTimer?.cancel();
        await courierSub?.cancel();
        courierSub = null;
        courierOnline = false;
        setState(() {
          checking = false;
          allowed = false;
          pendingApproval = true;
        });
        return;
      }

      courierOnline = courier['is_online'] == true;
      final active = await data.client.rpc('get_active_courier_shipment');
      if (!mounted) return;

      setState(() {
        checking = false;
        allowed = true;
        pendingApproval = false;
        activeShipment = active == null
            ? null
            : Map<String, dynamic>.from(active as Map);
      });

      _watchCourierState();
      if (courierOnline) {
        unawaited(_startPresence());
      } else {
        heartbeatTimer?.cancel();
      }
    } catch (e) {
      heartbeatTimer?.cancel();
      await courierSub?.cancel();
      courierSub = null;
      if (!mounted) return;
      setState(() {
        checking = false;
        allowed = false;
        message = 'Kurye hesabı doğrulanamadı. Tekrar giriş yap.';
      });
    }
  }

  Future<void> _logout() async {
    heartbeatTimer?.cancel();
    await courierSub?.cancel();
    courierSub = null;
    try {
      if (data.isSignedIn && courierOnline) {
        await data.setCourierOnline(online: false);
      }
    } catch (_) {}
    await data.signOut();
    if (mounted) await _check();
  }

  Widget _activeJobOrChild() {
    final row = activeShipment;
    if (row == null) return widget.child;

    final shipmentId = (row['id'] ?? '').toString();
    if (shipmentId.isEmpty) return widget.child;

    return StreamBuilder<Map<String, dynamic>>(
      stream: data.watchShipment(shipmentId),
      initialData: row,
      builder: (context, snapshot) {
        final current = snapshot.data ?? row;
        final status = (current['status'] ?? '').toString();
        const activeStatuses = {
          'accepted',
          'at_pickup',
          'picked_up',
          'at_dropoff',
        };

        if (!activeStatuses.contains(status)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && activeShipment != null) {
              setState(() => activeShipment = null);
            }
          });
          return widget.child;
        }

        return CourierActiveJobRealtimePage(
          shipmentId: shipmentId,
          pickup: (current['pickup_address'] ?? '').toString(),
          dropoff: (current['dropoff_address'] ?? '').toString(),
          earning: ((current['courier_earning'] ??
                      current['estimated_price'] ??
                      0)
                  as num)
              .round(),
        );
      },
    );
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

    return _activeJobOrChild();
  }
}
