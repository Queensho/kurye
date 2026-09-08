import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'courier_found_page.dart';

class CourierSearchPage extends StatefulWidget {
  const CourierSearchPage({super.key});

  @override
  State<CourierSearchPage> createState() => _CourierSearchPageState();
}

class _CourierSearchPageState extends State<CourierSearchPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF758198);
  static const center = LatLng(41.0678, 28.9951);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CourierFoundPage()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              Padding(
                padding: EdgeInsets.fromLTRB(16 * s, 6 * s, 16 * s, 0),
                child: Column(children: [
                  Row(children: [
                    _round(s, Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
                    const Spacer(),
                  ]),
                  SizedBox(height: 4 * s),
                  SizedBox(
                    height: 178 * s,
                    child: Stack(children: [
                      Positioned(
                        left: 0,
                        top: 12 * s,
                        right: 125 * s,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Gönderin oluşturuldu!', style: TextStyle(fontSize: 27 * s, height: 1.05, fontWeight: FontWeight.w900, color: navy)),
                          SizedBox(height: 5 * s),
                          Text('Sana en uygun kurye aranıyor...', style: TextStyle(fontSize: 18 * s, fontWeight: FontWeight.w800, color: blue)),
                          SizedBox(height: 8 * s),
                          Text('Yakındaki kuryelere bildirildi.\nEn kısa sürede bir kurye kabul edecek.', style: TextStyle(fontSize: 12 * s, height: 1.45, color: muted, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                      Positioned(
                        right: -4 * s,
                        bottom: 8 * s,
                        width: 145 * s,
                        height: 160 * s,
                        child: Image.asset('assets/images/kurye_header_hd.png', fit: BoxFit.contain, alignment: Alignment.bottomRight),
                      ),
                    ]),
                  ),
                  SizedBox(height: 8 * s),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12 * s),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(19 * s),
                      boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 15, offset: Offset(0, 5))],
                    ),
                    child: Row(children: [
                      Expanded(child: _feature(s, Icons.bolt_rounded, 'Hızlı\nEşleşme')),
                      _vline(s),
                      Expanded(child: _feature(s, Icons.shield_outlined, 'Güvenli\nTeslimat')),
                      _vline(s),
                      Expanded(child: _feature(s, Icons.location_on_rounded, 'Canlı\nTakip')),
                    ]),
                  ),
                ]),
              ),
              _connector(s),
              _map(s),
              SizedBox(height: 14 * s),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * s),
                child: Container(
                  padding: EdgeInsets.all(14 * s),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24 * s), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 5))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('Gönderi Detayları', style: TextStyle(fontSize: 20 * s, fontWeight: FontWeight.w900, color: navy))),
                      Text('#12458', style: TextStyle(fontSize: 12 * s, color: muted, fontWeight: FontWeight.w700)),
                    ]),
                    SizedBox(height: 12 * s),
                    Row(children: [
                      Container(width: 42 * s, height: 42 * s, decoration: const BoxDecoration(color: Color(0xFFEAF4FF), shape: BoxShape.circle), child: Icon(Icons.inventory_2_rounded, color: blue, size: 22 * s)),
                      SizedBox(width: 10 * s),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Paket', style: TextStyle(fontSize: 14 * s, fontWeight: FontWeight.w800, color: navy)),
                        Text('Tahmini 0–5 kg', style: TextStyle(fontSize: 11 * s, color: muted)),
                      ])),
                      Text('₺120 – 150', style: TextStyle(fontSize: 16 * s, fontWeight: FontWeight.w900, color: blue)),
                    ]),
                  ]),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _connector(double s) => SizedBox(
    height: 22 * s,
    child: Center(child: Column(children: [
      Container(width: 7 * s, height: 7 * s, decoration: const BoxDecoration(color: blue, shape: BoxShape.circle)),
      Expanded(child: Container(width: 2 * s, color: blue.withValues(alpha: .55))),
    ])),
  );

  Widget _round(double s, IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18 * s),
    child: Container(
      width: 44 * s,
      height: 44 * s,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17 * s), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 15, offset: Offset(0, 5))]),
      child: Icon(icon, color: const Color(0xFF173C84), size: 25 * s),
    ),
  );

  Widget _feature(double s, IconData icon, String text) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(width: 34 * s, height: 34 * s, decoration: const BoxDecoration(color: Color(0xFFEAF4FF), shape: BoxShape.circle), child: Icon(icon, color: blue, size: 20 * s)),
      SizedBox(width: 7 * s),
      Text(text, style: TextStyle(fontSize: 10.5 * s, height: 1.2, color: const Color(0xFF40506A), fontWeight: FontWeight.w700)),
    ],
  );

  Widget _vline(double s) => Container(width: 1, height: 32 * s, color: const Color(0xFFE6ECF4));

  Widget _map(double s) {
    const couriers = [
      LatLng(41.0744, 28.9885),
      LatLng(41.0710, 29.0047),
      LatLng(41.0607, 29.0074),
    ];

    return SizedBox(
      height: 330 * s,
      width: double.infinity,
      child: Stack(children: [
        FlutterMap(
          options: const MapOptions(initialCenter: center, initialZoom: 13.8, minZoom: 10, maxZoom: 18),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.queensho.kurye'),
            MarkerLayer(markers: [
              Marker(
                point: center,
                width: 84 * s,
                height: 84 * s,
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: blue.withValues(alpha: .18)),
                  alignment: Alignment.center,
                  child: Container(width: 48 * s, height: 48 * s, decoration: const BoxDecoration(shape: BoxShape.circle, color: blue), child: Icon(Icons.location_on_rounded, color: Colors.white, size: 28 * s)),
                ),
              ),
              ...couriers.map((p) => Marker(point: p, width: 62 * s, height: 62 * s, child: _courier(s))),
            ]),
          ],
        ),
        Positioned(
          left: 16 * s,
          top: 14 * s,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 9 * s),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15 * s), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 12)]),
            child: Row(children: [
              Icon(Icons.radar_rounded, color: blue, size: 20 * s),
              SizedBox(width: 7 * s),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kuryeler bölgede', style: TextStyle(fontSize: 10.5 * s, fontWeight: FontWeight.w800, color: navy)),
                Text('3 kurye yakınında', style: TextStyle(fontSize: 9.5 * s, color: muted)),
              ]),
            ]),
          ),
        ),
        Positioned(right: 6 * s, bottom: 5 * s, child: Container(padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 3 * s), color: Colors.white.withValues(alpha: .88), child: Text('© OpenStreetMap katkıda bulunanlar', style: TextStyle(fontSize: 7.5 * s, color: const Color(0xFF59677B))))),
      ]),
    );
  }

  Widget _courier(double s) => Container(
    width: 58 * s,
    height: 58 * s,
    padding: EdgeInsets.all(5 * s),
    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB9DAFF), width: 2), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)]),
    child: Image.asset('assets/images/motosiklet_hd.png', fit: BoxFit.contain),
  );
}
