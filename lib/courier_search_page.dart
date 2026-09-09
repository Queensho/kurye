import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'customer_assigned_courier_page.dart';
import 'data/app_data_service.dart';

class CourierSearchPage extends StatefulWidget {
  const CourierSearchPage({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<CourierSearchPage> createState() => _CourierSearchPageState();
}

class _CourierSearchPageState extends State<CourierSearchPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF758198);

  final data = AppDataService.instance;
  StreamSubscription<Map<String, dynamic>>? shipmentSub;
  Map<String, dynamic> shipment = {};
  bool openingCourier = false;

  @override
  void initState() {
    super.initState();
    shipmentSub = data.watchShipment(widget.shipmentId).listen((row) {
      if (!mounted || row.isEmpty) return;
      setState(() => shipment = row);
      final courierId = row['courier_id']?.toString();
      if (!openingCourier && courierId != null && courierId.isNotEmpty) {
        openingCourier = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => CustomerAssignedCourierPage(shipmentId: widget.shipmentId)),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    shipmentSub?.cancel();
    super.dispose();
  }

  double? _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

  @override
  Widget build(BuildContext context) {
    final pickupLat = _num(shipment['pickup_lat']);
    final pickupLng = _num(shipment['pickup_lng']);
    final center = (pickupLat != null && pickupLng != null) ? LatLng(pickupLat, pickupLng) : const LatLng(41.0082, 28.9784);
    final code = shipment['public_code']?.toString() ?? widget.shipmentId.substring(0, 8);
    final price = shipment['estimated_price'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconButton.filledTonal(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded)),
                  const Spacer(),
                ]),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Gönderin oluşturuldu!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: navy)),
                    SizedBox(height: 5),
                    Text('Kurye bekleniyor...', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: blue)),
                    SizedBox(height: 6),
                    Text('Gönderi gerçek iş havuzunda. Bir kurye işi aldığında bu ekran otomatik değişecek.', style: TextStyle(color: muted, height: 1.4)),
                  ])),
                  SizedBox(width: 120, height: 120, child: Image.asset('assets/images/kurye_header_hd.png', fit: BoxFit.contain)),
                ]),
              ]),
            ),
            Expanded(
              child: Stack(children: [
                FlutterMap(
                  options: MapOptions(initialCenter: center, initialZoom: pickupLat == null ? 11 : 14, minZoom: 5, maxZoom: 18),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.queensho.kurye'),
                    if (pickupLat != null && pickupLng != null)
                      MarkerLayer(markers: [Marker(point: center, width: 64, height: 64, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: blue.withValues(alpha: .18)), alignment: Alignment.center, child: Container(width: 42, height: 42, decoration: const BoxDecoration(shape: BoxShape.circle, color: blue), child: const Icon(Icons.location_on_rounded, color: Colors.white))))]),
                  ],
                ),
                Positioned(
                  top: 14,
                  left: 18,
                  right: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 14)]),
                    child: const Row(children: [
                      SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3)),
                      SizedBox(width: 12),
                      Expanded(child: Text('Online kuryeler iş havuzundan bu gönderiyi görebilir.', style: TextStyle(fontWeight: FontWeight.w800, color: navy))),
                    ]),
                  ),
                ),
              ]),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: Row(children: [
                const CircleAvatar(radius: 25, backgroundColor: Color(0xFFEAF4FF), child: Icon(Icons.inventory_2_rounded, color: blue)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Gönderi iş havuzunda', style: TextStyle(fontWeight: FontWeight.w900, color: navy)),
                  Text('#$code', style: const TextStyle(color: muted)),
                ])),
                if (price != null) Text('₺$price', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: blue)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
