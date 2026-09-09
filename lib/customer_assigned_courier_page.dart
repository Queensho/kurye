import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/app_data_service.dart';
import 'shipment_chat_page.dart';

class CustomerAssignedCourierPage extends StatefulWidget {
  const CustomerAssignedCourierPage({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<CustomerAssignedCourierPage> createState() => _CustomerAssignedCourierPageState();
}

class _CustomerAssignedCourierPageState extends State<CustomerAssignedCourierPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF758198);
  static const green = Color(0xFF19C983);

  final data = AppDataService.instance;
  StreamSubscription<Map<String, dynamic>>? courierSub;
  Map<String, dynamic>? info;
  Map<String, dynamic> courierLocation = {};
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await data.client.rpc('get_assigned_courier_for_shipment', params: {'p_shipment_id': widget.shipmentId});
      if (raw == null) throw StateError('Kurye bilgisi henüz hazır değil.');
      final value = Map<String, dynamic>.from(raw as Map);
      if (!mounted) return;
      setState(() { info = value; loading = false; });
      final courierId = value['courier_id']?.toString();
      if (courierId != null && courierId.isNotEmpty) {
        courierSub = data.watchCourierLocation(courierId).listen((row) {
          if (mounted) setState(() => courierLocation = row);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString().replaceFirst('Bad state: ', ''); });
    }
  }

  @override
  void dispose() {
    courierSub?.cancel();
    super.dispose();
  }

  double? _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

  String _status(String value) => switch (value) {
    'accepted' => 'Alım noktasına gidiyor',
    'at_pickup' => 'Alım noktasında',
    'picked_up' => 'Gönderin yolda',
    'at_dropoff' => 'Teslimat noktasında',
    'delivered' => 'Teslim edildi',
    'cancelled' => 'İptal edildi',
    _ => 'Gönderi güncelleniyor',
  };

  Future<void> _call(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefon uygulaması açılamadı.')));
    }
  }

  void _openChat(String name) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ShipmentChatPage(shipmentId: widget.shipmentId, title: name),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (info == null) {
      return Scaffold(appBar: AppBar(title: const Text('Kurye')), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error ?? 'Kurye bilgisi alınamadı.'))));
    }

    final d = info!;
    final name = (d['full_name']?.toString().trim().isNotEmpty ?? false) ? d['full_name'].toString() : 'Kurye';
    final phone = d['phone']?.toString() ?? '';
    final vehicle = d['vehicle_type'] == 'car' ? 'Otomobil' : 'Motosiklet';
    final status = (d['shipment_status'] ?? '').toString();
    final courierLat = _num(courierLocation['latitude']) ?? _num(d['latitude']);
    final courierLng = _num(courierLocation['longitude']) ?? _num(d['longitude']);
    final pickupLat = _num(d['pickup_lat']);
    final pickupLng = _num(d['pickup_lng']);
    final dropoffLat = _num(d['dropoff_lat']);
    final dropoffLng = _num(d['dropoff_lng']);

    LatLng center = const LatLng(41.0082, 28.9784);
    if (courierLat != null && courierLng != null) center = LatLng(courierLat, courierLng);
    else if (pickupLat != null && pickupLng != null) center = LatLng(pickupLat, pickupLng);

    final markers = <Marker>[];
    if (pickupLat != null && pickupLng != null) markers.add(Marker(point: LatLng(pickupLat, pickupLng), width: 52, height: 52, child: _pin(blue, Icons.trip_origin_rounded)));
    if (courierLat != null && courierLng != null) markers.add(Marker(point: LatLng(courierLat, courierLng), width: 64, height: 64, child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB9DAFF), width: 2)), padding: const EdgeInsets.all(6), child: Image.asset('assets/images/motosiklet_hd.png', fit: BoxFit.contain))));
    if (dropoffLat != null && dropoffLng != null) markers.add(Marker(point: LatLng(dropoffLat, dropoffLng), width: 52, height: 52, child: _pin(green, Icons.location_on_rounded)));

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Row(children: [
              IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Kurye bulundu!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: navy)),
                Text(_status(status), style: const TextStyle(color: blue, fontWeight: FontWeight.w800)),
              ])),
            ]),
          ),
          Expanded(child: FlutterMap(options: MapOptions(initialCenter: center, initialZoom: 13.5, minZoom: 5, maxZoom: 18), children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.queensho.kurye'),
            MarkerLayer(markers: markers),
          ])),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const CircleAvatar(radius: 30, backgroundColor: Color(0xFFEAF4FF), child: Icon(Icons.person_rounded, color: blue, size: 34)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: navy)),
                  Text('$vehicle • ${_status(status)}', style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
                ])),
                IconButton.filledTonal(onPressed: () => _openChat(name), icon: const Icon(Icons.chat_bubble_rounded)),
                if (phone.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  IconButton.filled(onPressed: () => _call(phone), icon: const Icon(Icons.phone_rounded)),
                ],
              ]),
              const SizedBox(height: 14),
              _row('Gönderi', d['public_code'] ?? widget.shipmentId.substring(0, 8)),
              _row('Alım', d['pickup_address']),
              _row('Teslimat', d['dropoff_address']),
              _row('Ücret', d['estimated_price'] == null ? '-' : '₺${d['estimated_price']}'),
              const SizedBox(height: 8),
              const Text('Kurye konumu gerçek zamanlı güncellenir.', style: TextStyle(color: muted, fontSize: 12)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _pin(Color color, IconData icon) => Container(decoration: BoxDecoration(color: color.withValues(alpha: .18), shape: BoxShape.circle), alignment: Alignment.center, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 22)));
  Widget _row(String label, dynamic value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 76, child: Text(label, style: const TextStyle(color: muted, fontWeight: FontWeight.w700))), Expanded(child: Text('${value ?? '-'}', style: const TextStyle(color: navy, fontWeight: FontWeight.w700)))]));
}
