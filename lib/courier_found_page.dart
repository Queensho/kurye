import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CourierFoundPage extends StatelessWidget {
  const CourierFoundPage({super.key});

  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF758198);
  static const green = Color(0xFF19C983);

  static const pickup = LatLng(41.0672, 28.9867);
  static const courier = LatLng(41.0668, 28.9975);
  static const dropoff = LatLng(41.0640, 29.0182);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final s = c.maxWidth / 390;
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 18 * s),
            child: Column(children: [
              _hero(context, s),
              _progress(s),
              _map(s),
              Transform.translate(
                offset: Offset(0, -8 * s),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12 * s),
                  child: Column(children: [
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

  Widget _hero(BuildContext context, double s) => Container(
        padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF4FAFF), Color(0xFFEAF5FF)]),
        ),
        child: Column(children: [
          Row(children: [
            _roundButton(s, Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 9 * s),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 12)]),
              child: Row(children: [Icon(Icons.headset_mic_outlined, color: const Color(0xFF173C84), size: 18 * s), SizedBox(width: 6 * s), Text('Yardım', style: TextStyle(fontSize: 11 * s, color: navy, fontWeight: FontWeight.w700))]),
            ),
          ]),
          SizedBox(height: 6 * s),
          SizedBox(
            height: 145 * s,
            child: Stack(children: [
              Positioned(
                left: 0,
                top: 16 * s,
                right: 150 * s,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Kurye bulundu!', style: TextStyle(fontSize: 27 * s, height: 1.0, fontWeight: FontWeight.w900, color: navy)),
                  SizedBox(height: 6 * s),
                  Text('Kurye alım noktasına geliyor.', style: TextStyle(fontSize: 16 * s, fontWeight: FontWeight.w800, color: blue)),
                  SizedBox(height: 6 * s),
                  Text('Tahmini 3 dakika içinde adresinde olacak.', style: TextStyle(fontSize: 11 * s, height: 1.35, color: muted, fontWeight: FontWeight.w500)),
                ]),
              ),
              Positioned(right: -4 * s, bottom: -8 * s, width: 165 * s, height: 150 * s, child: Image.asset('assets/images/kurye_header_hd.png', fit: BoxFit.contain, alignment: Alignment.bottomRight)),
            ]),
          ),
        ]),
      );

  Widget _progress(double s) => Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(20 * s, 10 * s, 20 * s, 12 * s),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _step(s, true, Icons.check_rounded, 'Kurye Bulundu'),
          _line(s),
          _step(s, false, Icons.inventory_2_outlined, 'Alımda'),
          _line(s),
          _step(s, false, Icons.local_shipping_outlined, 'Teslimatta'),
          _line(s),
          _step(s, false, Icons.flag_outlined, 'Teslim Edildi'),
        ]),
      );

  Widget _step(double s, bool active, IconData icon, String label) => SizedBox(
        width: 72 * s,
        child: Column(children: [
          Container(width: 34 * s, height: 34 * s, decoration: BoxDecoration(shape: BoxShape.circle, color: active ? blue : const Color(0xFFE9EEF6)), child: Icon(icon, color: active ? Colors.white : const Color(0xFF8A96AA), size: 18 * s)),
          SizedBox(height: 5 * s),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.4 * s, color: active ? navy : muted, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _line(double s) => Expanded(child: Padding(padding: EdgeInsets.only(top: 16 * s), child: Container(height: 2 * s, color: const Color(0xFFD7E0EC))));

  Widget _map(double s) => SizedBox(
        height: 315 * s,
        width: double.infinity,
        child: Stack(children: [
          FlutterMap(
            options: const MapOptions(initialCenter: LatLng(41.067, 29.002), initialZoom: 13.4, minZoom: 10, maxZoom: 18),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.queensho.kurye'),
              PolylineLayer(polylines: [Polyline(points: const [pickup, LatLng(41.0665, 28.9915), courier, LatLng(41.0652, 29.0080), dropoff], strokeWidth: 5 * s, color: blue)]),
              MarkerLayer(markers: [
                Marker(point: pickup, width: 54 * s, height: 54 * s, child: _mapPin(s, blue, Icons.circle, 18)),
                Marker(point: courier, width: 68 * s, height: 68 * s, child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB9DAFF), width: 2)), padding: EdgeInsets.all(5 * s), child: Image.asset('assets/images/motosiklet_hd.png', fit: BoxFit.contain))),
                Marker(point: dropoff, width: 54 * s, height: 54 * s, child: _mapPin(s, green, Icons.location_on_rounded, 28)),
              ]),
            ],
          ),
          Positioned(left: 14 * s, top: 12 * s, child: _metricCard(s)),
          Positioned(right: 14 * s, top: 14 * s, child: Container(padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 9 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16 * s), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12)]), child: Row(children: [Icon(Icons.wifi_tethering_rounded, color: blue, size: 18 * s), SizedBox(width: 6 * s), Text('Canlı Takip', style: TextStyle(fontSize: 10.5 * s, color: navy, fontWeight: FontWeight.w700))]))),
          Positioned(left: 15 * s, bottom: 18 * s, child: _labelBubble(s, 'Alım Noktası', 'Büyükdere Cd. No:120')),
          Positioned(right: 12 * s, top: 145 * s, child: _labelBubble(s, 'Teslimat Noktası', 'Bağdat Cd. No:345')),
          Positioned(right: 6 * s, bottom: 4 * s, child: Container(color: Colors.white.withValues(alpha: .88), padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 2 * s), child: Text('© OpenStreetMap katkıda bulunanlar', style: TextStyle(fontSize: 7 * s, color: muted)))),
        ]),
      );

  Widget _metricCard(double s) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17 * s), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12)]),
        child: Row(children: [
          Icon(Icons.schedule_rounded, color: blue, size: 22 * s), SizedBox(width: 7 * s),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tahmini varış', style: TextStyle(fontSize: 8.5 * s, color: muted)), Text('3 dk', style: TextStyle(fontSize: 17 * s, color: blue, fontWeight: FontWeight.w900))]),
          SizedBox(width: 13 * s), Container(width: 1, height: 32 * s, color: const Color(0xFFE5EAF2)), SizedBox(width: 13 * s),
          Icon(Icons.location_on_rounded, color: blue, size: 22 * s), SizedBox(width: 7 * s),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Mesafe', style: TextStyle(fontSize: 8.5 * s, color: muted)), Text('1.2 km', style: TextStyle(fontSize: 15 * s, color: navy, fontWeight: FontWeight.w900))]),
        ]),
      );

  Widget _mapPin(double s, Color c, IconData icon, double size) => Container(decoration: BoxDecoration(color: c.withValues(alpha: .16), shape: BoxShape.circle), alignment: Alignment.center, child: Container(width: 34 * s, height: 34 * s, decoration: BoxDecoration(color: c, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: size * s)));

  Widget _labelBubble(double s, String title, String sub) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 7 * s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13 * s), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 9.5 * s, color: navy, fontWeight: FontWeight.w800)), Text(sub, style: TextStyle(fontSize: 8.5 * s, color: muted))]),
      );

  Widget _courierCard(double s) => Container(
        padding: EdgeInsets.all(12 * s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24 * s), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 5))]),
        child: Column(children: [
          Row(children: [
            Stack(children: [
              Container(width: 64 * s, height: 64 * s, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAF4FF)), child: Icon(Icons.person_rounded, color: blue, size: 36 * s)),
              Positioned(right: 1 * s, top: 1 * s, child: Container(width: 13 * s, height: 13 * s, decoration: const BoxDecoration(shape: BoxShape.circle, color: green, border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2))))),
            ]),
            SizedBox(width: 10 * s),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Emre K.', style: TextStyle(fontSize: 20 * s, color: navy, fontWeight: FontWeight.w900)), SizedBox(height: 4 * s), Row(children: [Icon(Icons.star_rounded, color: const Color(0xFFFFB400), size: 17 * s), SizedBox(width: 3 * s), Text('4.8', style: TextStyle(fontSize: 12 * s, color: navy, fontWeight: FontWeight.w800)), SizedBox(width: 5 * s), Text('(320)', style: TextStyle(fontSize: 11 * s, color: muted))])])),
            Container(padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 9 * s), decoration: BoxDecoration(color: const Color(0xFFF1F6FC), borderRadius: BorderRadius.circular(15 * s)), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('Honda PCX', style: TextStyle(fontSize: 10 * s, color: muted, fontWeight: FontWeight.w700)), Text('34 KYA 728', style: TextStyle(fontSize: 11 * s, color: navy, fontWeight: FontWeight.w900))])),
          ]),
          SizedBox(height: 11 * s),
          Container(padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 9 * s), decoration: BoxDecoration(color: const Color(0xFFF2F7FD), borderRadius: BorderRadius.circular(15 * s)), child: Row(children: [Icon(Icons.route_rounded, color: const Color(0xFF5F6F84), size: 17 * s), SizedBox(width: 7 * s), Expanded(child: Text('“Yoldayım, 3 dakika içinde oradayım.”', style: TextStyle(fontSize: 10.5 * s, color: const Color(0xFF53627A), fontWeight: FontWeight.w600))), Text('09:38', style: TextStyle(fontSize: 9 * s, color: muted))])),
          SizedBox(height: 10 * s),
          Row(children: [
            Expanded(child: _action(s, Icons.phone_rounded, 'Ara', green, Colors.white)), SizedBox(width: 8 * s),
            Expanded(child: _action(s, Icons.chat_bubble_rounded, 'Mesaj Gönder', const Color(0xFFEAF4FF), blue)), SizedBox(width: 8 * s),
            Expanded(child: _action(s, Icons.list_alt_rounded, 'Detaylar', const Color(0xFFEAF4FF), blue)),
          ]),
        ]),
      );

  Widget _shipmentCard(double s) => Container(
        padding: EdgeInsets.all(12 * s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22 * s), boxShadow: const [BoxShadow(color: Color(0x0E000000), blurRadius: 14)]),
        child: Row(children: [
          Container(width: 44 * s, height: 44 * s, decoration: const BoxDecoration(color: Color(0xFFEAF4FF), shape: BoxShape.circle), child: Icon(Icons.inventory_2_rounded, color: blue, size: 23 * s)),
          SizedBox(width: 10 * s),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Gönderi Detayları', style: TextStyle(fontSize: 14 * s, color: navy, fontWeight: FontWeight.w900)), Text('Paket • 0–5 kg', style: TextStyle(fontSize: 10.5 * s, color: muted)), SizedBox(height: 5 * s), Text('Alım: Büyükdere Cd. No:120, Şişli', style: TextStyle(fontSize: 9.5 * s, color: const Color(0xFF53627A))), Text('Teslimat: Bağdat Cd. No:345, Kadıköy', style: TextStyle(fontSize: 9.5 * s, color: const Color(0xFF53627A))) ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('#12458', style: TextStyle(fontSize: 10 * s, color: muted, fontWeight: FontWeight.w700)), SizedBox(height: 5 * s), Text('₺120 – 150', style: TextStyle(fontSize: 16 * s, color: blue, fontWeight: FontWeight.w900)), SizedBox(height: 7 * s), Icon(Icons.chevron_right_rounded, color: navy, size: 22 * s)]),
        ]),
      );

  Widget _action(double s, IconData icon, String label, Color bg, Color fg) => Container(
        height: 48 * s,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16 * s)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: fg, size: 18 * s), SizedBox(width: 6 * s), Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5 * s, color: fg, fontWeight: FontWeight.w800)))]),
      );

  Widget _roundButton(double s, IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18 * s),
        child: Container(width: 44 * s, height: 44 * s, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17 * s), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 15, offset: Offset(0, 5))]), child: Icon(icon, color: const Color(0xFF173C84), size: 25 * s)),
      );
}
