import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'courier_found_page_v2.dart' show CourierChatPage;

class PickupStatusPage extends StatefulWidget {
  const PickupStatusPage({super.key});

  @override
  State<PickupStatusPage> createState() => _PickupStatusPageState();
}

class _PickupStatusPageState extends State<PickupStatusPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF758198);
  static const green = Color(0xFF19C983);
  static const pickup = LatLng(41.0672, 28.9867);
  static const dropoff = LatLng(41.0640, 29.0182);

  bool pickedUp = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => pickedUp = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _callCourier() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Emre K. aranıyor'),
        content: const Text(
          'Kurye ile telefon görüşmesi başlatılacak.\n\nTest numarası: +90 555 123 45 67',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Arama başlatıldı')),
              );
            },
            child: const Text('Ara'),
          ),
        ],
      ),
    );
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CourierChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final s = c.maxWidth / 390;
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 20 * s),
            child: Column(children: [
              _header(context, s),
              _progress(s),
              _map(s),
              Transform.translate(
                offset: Offset(0, -10 * s),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14 * s),
                  child: Column(children: [
                    _statusCard(s),
                    SizedBox(height: 10 * s),
                    _courierCard(s),
                    SizedBox(height: 10 * s),
                    _shipmentCard(s),
                  ]),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _header(BuildContext context, double s) => Container(
        padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 14 * s),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFF4FAFF), Color(0xFFEAF5FF)]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _round(s, Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
            const Spacer(),
            _pill(s, Icons.headset_mic_outlined, 'Yardım'),
          ]),
          SizedBox(height: 14 * s),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pickedUp ? 'Paket teslim alındı!' : 'Kurye alım noktasında!', style: TextStyle(fontSize: 27 * s, height: 1.05, fontWeight: FontWeight.w900, color: navy)),
              SizedBox(height: 7 * s),
              Text(pickedUp ? 'Gönderin teslimat adresine doğru yola çıktı.' : 'Kurye paketi teslim almak için seni bekliyor.', style: TextStyle(fontSize: 15 * s, height: 1.25, fontWeight: FontWeight.w800, color: blue)),
              SizedBox(height: 7 * s),
              Text(pickedUp ? 'Canlı olarak takip edebilirsin.' : 'Paket teslim edildiğinde durum otomatik güncellenecek.', style: TextStyle(fontSize: 11 * s, color: muted, height: 1.35)),
            ])),
            SizedBox(width: 8 * s),
            Container(width: 105 * s, height: 105 * s, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18)]), padding: EdgeInsets.all(10 * s), child: Image.asset('assets/images/kurye_header_hd.png', fit: BoxFit.contain)),
          ]),
        ]),
      );

  Widget _progress(double s) => Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 12 * s),
        child: Row(children: [
          _step(s, true, Icons.check_rounded, 'Kurye Bulundu'),
          _line(s, true),
          _step(s, true, pickedUp ? Icons.check_rounded : Icons.inventory_2_outlined, 'Alımda'),
          _line(s, pickedUp),
          _step(s, pickedUp, Icons.local_shipping_outlined, 'Teslimatta'),
          _line(s, false),
          _step(s, false, Icons.flag_outlined, 'Teslim Edildi'),
        ]),
      );

  Widget _step(double s, bool active, IconData icon, String label) => SizedBox(
        width: 70 * s,
        child: Column(children: [
          Container(width: 34 * s, height: 34 * s, decoration: BoxDecoration(shape: BoxShape.circle, color: active ? blue : const Color(0xFFE9EEF6)), child: Icon(icon, color: active ? Colors.white : const Color(0xFF8A96AA), size: 18 * s)),
          SizedBox(height: 5 * s),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 8.2 * s, color: active ? navy : muted, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _line(double s, bool active) => Expanded(child: Container(height: 2 * s, color: active ? blue : const Color(0xFFD7E0EC)));

  Widget _map(double s) => SizedBox(
        height: 285 * s,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(initialCenter: pickedUp ? const LatLng(41.0658, 29.004) : pickup, initialZoom: 13.8, minZoom: 10, maxZoom: 18),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.queensho.kurye'),
            if (pickedUp)
              PolylineLayer(polylines: [Polyline(points: const [pickup, LatLng(41.0660, 28.9980), LatLng(41.0650, 29.0080), dropoff], strokeWidth: 5 * s, color: blue)]),
            MarkerLayer(markers: [
              Marker(point: pickup, width: 58 * s, height: 58 * s, child: _pin(s, pickedUp ? green : blue, pickedUp ? Icons.check_rounded : Icons.inventory_2_rounded)),
              Marker(point: pickedUp ? const LatLng(41.0660, 28.9980) : pickup, width: 68 * s, height: 68 * s, child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB9DAFF), width: 2)), padding: EdgeInsets.all(6 * s), child: Image.asset('assets/images/motosiklet_hd.png', fit: BoxFit.contain))),
              if (pickedUp) Marker(point: dropoff, width: 58 * s, height: 58 * s, child: _pin(s, green, Icons.location_on_rounded)),
            ]),
          ],
        ),
      );

  Widget _pin(double s, Color c, IconData icon) => Container(decoration: BoxDecoration(color: c.withValues(alpha: .16), shape: BoxShape.circle), alignment: Alignment.center, child: Container(width: 36 * s, height: 36 * s, decoration: BoxDecoration(color: c, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20 * s)));

  Widget _statusCard(double s) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(14 * s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23 * s), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 6))]),
        child: Row(children: [
          Container(width: 54 * s, height: 54 * s, decoration: BoxDecoration(color: (pickedUp ? green : blue).withValues(alpha: .12), shape: BoxShape.circle), child: Icon(pickedUp ? Icons.local_shipping_rounded : Icons.inventory_2_rounded, color: pickedUp ? green : blue, size: 28 * s)),
          SizedBox(width: 12 * s),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pickedUp ? 'Teslimata çıkıldı' : 'Kurye paketi bekliyor', style: TextStyle(fontSize: 16 * s, color: navy, fontWeight: FontWeight.w900)),
            SizedBox(height: 4 * s),
            Text(pickedUp ? 'Tahmini teslimat süresi: 18 dk' : 'Büyükdere Cd. No:120, Şişli', style: TextStyle(fontSize: 11 * s, color: muted, fontWeight: FontWeight.w600)),
          ])),
          if (!pickedUp)
            GestureDetector(
              onTap: () {
                _timer?.cancel();
                setState(() => pickedUp = true);
              },
              child: Container(padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 9 * s), decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(14 * s)), child: Text('Paket Alındı', style: TextStyle(fontSize: 10 * s, color: Colors.white, fontWeight: FontWeight.w800))),
            ),
        ]),
      );

  Widget _courierCard(double s) => Container(
        padding: EdgeInsets.all(12 * s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22 * s)),
        child: Row(children: [
          Container(width: 54 * s, height: 54 * s, decoration: const BoxDecoration(color: Color(0xFFEAF4FF), shape: BoxShape.circle), child: Icon(Icons.person_rounded, color: blue, size: 31 * s)),
          SizedBox(width: 10 * s),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Emre K.', style: TextStyle(fontSize: 17 * s, color: navy, fontWeight: FontWeight.w900)), Text('Honda PCX • 34 KYA 728', style: TextStyle(fontSize: 10.5 * s, color: muted))])),
          _smallAction(s, Icons.phone_rounded, green, _callCourier),
          SizedBox(width: 7 * s),
          _smallAction(s, Icons.chat_bubble_rounded, blue, _openChat),
        ]),
      );

  Widget _shipmentCard(double s) => Container(
        padding: EdgeInsets.all(13 * s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22 * s)),
        child: Row(children: [
          Container(width: 44 * s, height: 44 * s, decoration: const BoxDecoration(color: Color(0xFFEAF4FF), shape: BoxShape.circle), child: Icon(Icons.inventory_2_rounded, color: blue, size: 23 * s)),
          SizedBox(width: 10 * s),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Gönderi #12458', style: TextStyle(fontSize: 14 * s, color: navy, fontWeight: FontWeight.w900)), Text('Paket • 0–5 kg', style: TextStyle(fontSize: 10.5 * s, color: muted)), Text('Teslimat: Bağdat Cd. No:345, Kadıköy', style: TextStyle(fontSize: 9.5 * s, color: const Color(0xFF53627A)))])),
          Text('₺120–150', style: TextStyle(fontSize: 14 * s, color: blue, fontWeight: FontWeight.w900)),
        ]),
      );

  Widget _round(double s, IconData icon, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18 * s), child: Container(width: 44 * s, height: 44 * s, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17 * s), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 12)]), child: Icon(icon, color: const Color(0xFF173C84), size: 24 * s)));
  Widget _pill(double s, IconData icon, String label) => Container(padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 9 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s)), child: Row(children: [Icon(icon, color: const Color(0xFF173C84), size: 17 * s), SizedBox(width: 5 * s), Text(label, style: TextStyle(fontSize: 10.5 * s, color: navy, fontWeight: FontWeight.w700))]));
  Widget _smallAction(double s, IconData icon, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14 * s),
        child: Container(
          width: 40 * s,
          height: 40 * s,
          decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(14 * s)),
          child: Icon(icon, color: color, size: 20 * s),
        ),
      );
}
