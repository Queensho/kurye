import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/app_data_service.dart';

class CourierActiveJobPage extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String pickupKm;
  final String totalKm;
  final String duration;
  final int earning;

  const CourierActiveJobPage({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.pickupKm,
    required this.totalKm,
    required this.duration,
    required this.earning,
  });

  @override
  State<CourierActiveJobPage> createState() => _CourierActiveJobPageState();
}

class _CourierActiveJobPageState extends State<CourierActiveJobPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF718198);
  static const green = Color(0xFF10B866);

  String? shipmentId;
  bool loading = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _loadActiveShipment();
  }

  Future<void> _loadActiveShipment() async {
    try {
      final row = await AppDataService.instance.client
          .from('couriers')
          .select('active_shipment_id')
          .eq('user_id', AppDataService.instance.userId)
          .single();
      if (!mounted) return;
      setState(() {
        shipmentId = row['active_shipment_id']?.toString();
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  int _step(String status) => switch (status) {
        'accepted' => 0,
        'at_pickup' => 1,
        'picked_up' => 2,
        'at_dropoff' => 3,
        'delivered' => 4,
        _ => 0,
      };

  String _action(String status) => switch (status) {
        'accepted' => 'Alım Noktasına Git',
        'at_pickup' => 'Teslim Aldım',
        'picked_up' => 'Teslimat Adresine Git',
        'at_dropoff' => 'Teslim Ettim',
        'delivered' => 'Teslim Edildi',
        _ => 'Devam Et',
      };

  Future<void> _openNavigation(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigasyon açılamadı.')),
      );
    }
  }

  Future<bool> _confirm(String title, String action) async {
    return await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: Text(title),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
              FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(action)),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _change(String status) async {
    final id = shipmentId;
    if (id == null) return;
    setState(() => busy = true);
    try {
      await AppDataService.instance.updateShipmentStatus(id, status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _advance(String status, String pickup, String dropoff) async {
    if (busy || status == 'delivered') return;
    if (status == 'accepted') {
      await _openNavigation(pickup);
      if (!mounted) return;
      if (await _confirm('Alım noktasına vardın mı?', 'Vardım')) {
        await _change('at_pickup');
      }
      return;
    }
    if (status == 'at_pickup') {
      await _change('picked_up');
      return;
    }
    if (status == 'picked_up') {
      await _openNavigation(dropoff);
      if (!mounted) return;
      if (await _confirm('Teslimat noktasına vardın mı?', 'Vardım')) {
        await _change('at_dropoff');
      }
      return;
    }
    if (status == 'at_dropoff') {
      if (await _confirm('Gönderiyi müşteriye teslim ettin mi?', 'Teslim Ettim')) {
        await _change('delivered');
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (d) => AlertDialog(
            icon: const Icon(Icons.check_circle_rounded, color: green, size: 52),
            title: const Text('Teslimat tamamlandı'),
            content: Text('₺${widget.earning} kazanç olarak işlendi.', textAlign: TextAlign.center),
            actionsAlignment: MainAxisAlignment.center,
            actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Tamam'))],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final id = shipmentId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aktif İş')),
        body: const Center(child: Text('Aktif gönderi bulunamadı.')),
      );
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: AppDataService.instance.watchShipment(id),
      builder: (context, snapshot) {
        final row = snapshot.data ?? const <String, dynamic>{};
        final status = (row['status'] ?? 'accepted').toString();
        final step = _step(status);
        final pickup = (row['pickup_address'] ?? widget.pickup).toString();
        final dropoff = (row['dropoff_address'] ?? widget.dropoff).toString();
        final code = (row['public_code'] ?? 'Aktif İş').toString();
        final earning = (row['estimated_price'] as num?)?.toInt() ?? widget.earning;

        return Scaffold(
          backgroundColor: const Color(0xFFF5FAFF),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Text(code, style: const TextStyle(color: navy, fontWeight: FontWeight.w900)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF168CF5), Color(0xFF55CFFF)]),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('İşin Aktif!', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                    SizedBox(height: 6),
                    Text('Her adım müşterinin ekranına anında yansır.', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _progress(step),
              const SizedBox(height: 18),
              _addressCard('Alım Noktası', pickup, blue, status == 'accepted' || status == 'at_pickup'),
              const SizedBox(height: 12),
              _addressCard('Teslimat Adresi', dropoff, const Color(0xFFFF4757), status == 'picked_up' || status == 'at_dropoff'),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                child: Row(
                  children: [
                    const Icon(Icons.route_rounded, color: blue),
                    const SizedBox(width: 8),
                    Text(widget.totalKm, style: const TextStyle(color: navy, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    const Icon(Icons.schedule_rounded, color: blue),
                    const SizedBox(width: 8),
                    Text(widget.duration, style: const TextStyle(color: navy, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                child: Row(
                  children: [
                    const Icon(Icons.payments_rounded, color: green),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Kurye Kazancı', style: TextStyle(color: muted))),
                    Text('₺$earning', style: const TextStyle(color: green, fontSize: 23, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: FilledButton.icon(
                onPressed: status == 'delivered' || busy ? null : () => _advance(status, pickup, dropoff),
                icon: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(status == 'at_pickup' || status == 'at_dropoff' ? Icons.check_circle_rounded : Icons.navigation_rounded),
                label: Text(_action(status)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: status == 'at_pickup' || status == 'at_dropoff' ? green : blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _progress(int step) {
    const labels = ['İşi Aldı', 'Alımda', 'Teslim Aldı', 'Teslimatta', 'Teslim Edildi'];
    return Row(
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: i <= step ? blue : const Color(0xFFDDE8F4),
                  child: i <= step ? const Icon(Icons.check, color: Colors.white, size: 17) : null,
                ),
                const SizedBox(height: 5),
                Text(labels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, color: i <= step ? blue : muted, fontWeight: i <= step ? FontWeight.w800 : FontWeight.w500)),
              ],
            ),
          ),
          if (i < labels.length - 1) Container(width: 10, height: 2, color: i < step ? blue : const Color(0xFFDDE8F4)),
        ],
      ],
    );
  }

  Widget _addressCard(String title, String address, Color color, bool active) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: active ? Border.all(color: color.withValues(alpha: .35)) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(Icons.location_on_rounded, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: navy, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(address, style: const TextStyle(color: muted, fontSize: 12)),
              ]),
            ),
            IconButton(onPressed: () => _openNavigation(address), icon: const Icon(Icons.navigation_rounded, color: blue)),
          ],
        ),
      );
}
