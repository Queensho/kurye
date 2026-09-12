import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'courier_assigned_jobs_page.dart';
import 'courier_route_map_page.dart';
import 'data/app_data_service.dart';

class CourierPoolJobDetailPage extends StatefulWidget {
  const CourierPoolJobDetailPage({super.key, required this.shipment});

  final Map<String, dynamic> shipment;

  @override
  State<CourierPoolJobDetailPage> createState() => _CourierPoolJobDetailPageState();
}

class _CourierPoolJobDetailPageState extends State<CourierPoolJobDetailPage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF171052);
  static const purple = Color(0xFF2B1776);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);
  static const green = Color(0xFF16B868);

  final data = AppDataService.instance;
  bool claiming = false;

  Map<String, dynamic> get item => widget.shipment;

  String _text(String key, [String fallback = '—']) {
    final value = item[key];
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _money(dynamic value) {
    if (value is num) {
      final d = value.toDouble();
      return d == d.roundToDouble() ? '₺${d.toInt()}' : '₺${d.toStringAsFixed(2)}';
    }
    return '₺0';
  }

  String _typeLabel(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'document': return 'Evrak';
      case 'food': return 'Market';
      case 'gift': return 'Hediye';
      default: return 'Paket';
    }
  }

  double? _number(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse((raw ?? '').toString().trim());
  }

  LatLng? _pickupPoint() {
    final lat = _number(item['pickup_lat'] ?? item['pickup_latitude']);
    final lng = _number(item['pickup_lng'] ?? item['pickup_longitude'] ?? item['pickup_lon']);
    return lat != null && lng != null ? LatLng(lat, lng) : null;
  }

  LatLng? _dropoffPoint() {
    final lat = _number(item['dropoff_lat'] ?? item['dropoff_latitude']);
    final lng = _number(item['dropoff_lng'] ?? item['dropoff_longitude'] ?? item['dropoff_lon']);
    return lat != null && lng != null ? LatLng(lat, lng) : null;
  }

  Future<void> _openRoute() async {
    final pickup = _pickupPoint();
    final dropoff = _dropoffPoint();
    if (pickup == null || dropoff == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu gönderinin harita koordinatları bulunamadı.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourierRouteMapPage(
          title: 'Gönderi Rotası',
          destinationLabel: 'Alım → Teslimat',
          origin: pickup,
          destination: dropoff,
        ),
      ),
    );
  }

  Future<void> _claim() async {
    if (claiming) return;
    setState(() => claiming = true);
    try {
      await data.claimShipment(item['id'].toString());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CourierAssignedJobsPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _text('public_code', 'Gönderi');
    final distance = item['distance_km'];
    final duration = item['duration_min'];
    final earning = item['courier_earning'] ?? item['estimated_price'];
    final desc = _text('description', 'Açıklama belirtilmedi');
    final weight = _text('weight_label');
    final size = _text('size_label');

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 128,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [purple, navy],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _roundButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                      const Expanded(
                        child: Text('Gönderi Detayı', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('#$code', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        Text(_typeLabel(item['package_type']), style: const TextStyle(color: Color(0xFFD9D2F3), fontSize: 12)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(18)),
                        child: Text(_money(earning), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  _routeCard(),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _metric(Icons.route_rounded, 'Mesafe', distance == null ? '—' : '$distance km')),
                    const SizedBox(width: 9),
                    Expanded(child: _metric(Icons.schedule_rounded, 'Tahmini Süre', duration == null ? '—' : '$duration dk')),
                  ]),
                  const SizedBox(height: 12),
                  _section('Paket Bilgileri', [
                    _info(Icons.inventory_2_outlined, 'Tür', _typeLabel(item['package_type'])),
                    _info(Icons.scale_outlined, 'Ağırlık', weight),
                    _info(Icons.straighten_rounded, 'Boyut', size),
                    _info(Icons.notes_rounded, 'Açıklama', desc),
                  ]),
                  const SizedBox(height: 12),
                  _section('Gönderi Bilgileri', [
                    _info(Icons.payments_outlined, 'Kurye Kazancı', _money(earning), valueColor: green),
                    _info(Icons.local_shipping_outlined, 'Durum', 'Havuzda'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: claiming ? null : _claim,
              style: FilledButton.styleFrom(backgroundColor: orange, disabledBackgroundColor: orange.withValues(alpha: .45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: claiming
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('İşi Al', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white.withValues(alpha: .12),
    shape: const CircleBorder(),
    child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: SizedBox(width: 42, height: 42, child: Icon(icon, color: Colors.white, size: 24))),
  );

  Widget _routeCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      _addressRow(orange, 'Alım Adresi', _text('pickup_address')),
      Padding(padding: const EdgeInsets.only(left: 7), child: Align(alignment: Alignment.centerLeft, child: Container(width: 2, height: 24, color: const Color(0xFFE1DDEA)))),
      _addressRow(navy, 'Teslimat Adresi', _text('dropoff_address')),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        height: 44,
        child: FilledButton.tonalIcon(
          onPressed: _openRoute,
          icon: const Icon(Icons.map_outlined, size: 20),
          label: const Text('Rotayı Gör', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF1EDFF),
            foregroundColor: purple,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ]),
  );

  Widget _addressRow(Color color, String title, String address) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(width: 16, height: 16, margin: const EdgeInsets.only(top: 3), decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: muted, fontSize: 10.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(address, style: const TextStyle(color: navy, fontSize: 12.5, height: 1.25, fontWeight: FontWeight.w700)),
      ])),
    ],
  );

  Widget _metric(IconData icon, String label, String value) => Container(
    height: 78,
    padding: const EdgeInsets.symmetric(horizontal: 13),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFF1EDFF), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: purple, size: 21)),
      const SizedBox(width: 10),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 9.5)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: navy, fontSize: 13, fontWeight: FontWeight.w900)),
      ])),
    ]),
  );

  Widget _section(String title, List<Widget> rows) => Container(
    padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: navy, fontSize: 14, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      ...rows,
    ]),
  );

  Widget _info(IconData icon, String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: muted, size: 19),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 11))),
      const SizedBox(width: 12),
      Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: valueColor ?? navy, fontSize: 11.5, fontWeight: FontWeight.w800))),
    ]),
  );
}
