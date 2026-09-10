import 'package:flutter/material.dart';

import 'create_shipment_page_v2.dart';
import 'data/app_data_service.dart';
import 'my_shipments_page.dart';
import 'profile_page.dart';

class HomePixelPreview extends StatelessWidget {
  const HomePixelPreview({super.key});

  static const orange = Color(0xFFFF5A1F);
  static const orangeSoft = Color(0xFFFFEEE7);
  static const navy = Color(0xFF171052);
  static const purple = Color(0xFF261168);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);
  static const green = Color(0xFF149C69);

  void _openCreateShipment(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateShipmentPage()));
  void _openMyShipments(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyShipmentsPage()));
  void _openProfile(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final s = (w / 390).clamp(.92, 1.12).toDouble();
            final compact = constraints.maxHeight < 760;
            final v = compact ? .88 : 1.0;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 16 * v),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _hero(context, s, v),
                        Transform.translate(offset: Offset(0, -18 * v), child: Padding(padding: EdgeInsets.symmetric(horizontal: 17 * s), child: _destinationCard(context, s, v))),
                        Transform.translate(offset: Offset(0, -4 * v), child: Padding(padding: EdgeInsets.symmetric(horizontal: 17 * s), child: _quickActions(context, s, v))),
                        SizedBox(height: 6 * v),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 17 * s), child: _promo(context, s, v)),
                        SizedBox(height: 20 * v),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 17 * s), child: _recent(context, s, v)),
                      ],
                    ),
                  ),
                ),
                _bottomNav(context, s, v),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, double s, double v) {
    final h = 292 * v;
    return SizedBox(
      height: h,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(26 * s), bottomRight: Radius.circular(26 * s)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFFAFAFD)),
            Positioned(
              left: 22 * s,
              top: 12 * v,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(const TextSpan(children: [TextSpan(text: 'open', style: TextStyle(color: navy)), TextSpan(text: '.', style: TextStyle(color: orange))]), style: TextStyle(fontSize: 36 * s, height: .95, fontWeight: FontWeight.w900, letterSpacing: -1.8 * s)),
                SizedBox(height: 2 * v),
                Text('Her gönderi daha yakın', style: TextStyle(color: navy, fontSize: 10.5 * s, fontWeight: FontWeight.w600)),
              ]),
            ),
            Positioned(
              right: -82 * s,
              top: -34 * v,
              bottom: -34 * v,
              width: 440 * s,
              child: Image.asset(
                'assets/images/3d_kurye.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              left: 22 * s,
              top: 113 * v,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Gönderin', style: TextStyle(color: navy, fontSize: 31 * s, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1.2 * s)),
                SizedBox(height: 2 * v),
                Text('yola çıksın', style: TextStyle(color: orange, fontSize: 31 * s, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1.2 * s)),
                SizedBox(height: 10 * v),
                Text('Hızlı, güvenli ve kolay\nteslimat çözümleri.', style: TextStyle(color: muted, fontSize: 13 * s, height: 1.28, fontWeight: FontWeight.w500)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationCard(BuildContext context, double s, double v) {
    return Material(color: Colors.white, borderRadius: BorderRadius.circular(19 * s), child: InkWell(onTap: () => _openCreateShipment(context), borderRadius: BorderRadius.circular(19 * s), child: Container(height: 66 * v, padding: EdgeInsets.symmetric(horizontal: 14 * s), decoration: BoxDecoration(borderRadius: BorderRadius.circular(19 * s), boxShadow: const [BoxShadow(color: Color(0x120F0A38), blurRadius: 20, offset: Offset(0, 8))]), child: Row(children: [
      Container(width: 43 * s, height: 43 * s, decoration: const BoxDecoration(color: Color(0xFFF3F1FA), shape: BoxShape.circle), child: Icon(Icons.location_on_rounded, color: navy, size: 25 * s)),
      SizedBox(width: 12 * s),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Nereye gönderiyorsun?', style: TextStyle(color: navy, fontSize: 14 * s, fontWeight: FontWeight.w800)), SizedBox(height: 2 * v), Text('Alıcı adresini gir', style: TextStyle(color: muted, fontSize: 12 * s))])),
      Icon(Icons.chevron_right_rounded, color: const Color(0xFF9A99A8), size: 24 * s),
    ]))));
  }

  Widget _quickActions(BuildContext context, double s, double v) {
    final actions = [
      (Icons.inventory_2_outlined, 'Gönderi\nOluştur', true, () => _openCreateShipment(context)),
      (Icons.receipt_long_outlined, 'Fiyat\nHesapla', false, () => _openCreateShipment(context)),
      (Icons.location_on_outlined, 'Canlı\nTakip', false, () => _openMyShipments(context)),
      (Icons.history_rounded, 'Geçmiş\nGönderiler', false, () => _openMyShipments(context)),
    ];
    return Row(children: [for (int i = 0; i < actions.length; i++) ...[if (i > 0) SizedBox(width: 8 * s), Expanded(child: _actionCard(actions[i].$1, actions[i].$2, actions[i].$3, actions[i].$4, s, v))]]);
  }

  Widget _actionCard(IconData icon, String label, bool active, VoidCallback onTap, double s, double v) {
    return Material(color: active ? orange : Colors.white, borderRadius: BorderRadius.circular(17 * s), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17 * s), child: Container(height: 94 * v, padding: EdgeInsets.symmetric(horizontal: 4 * s, vertical: 12 * v), decoration: BoxDecoration(borderRadius: BorderRadius.circular(17 * s), boxShadow: active ? const [] : const [BoxShadow(color: Color(0x0D100A39), blurRadius: 15, offset: Offset(0, 6))]), child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, size: 25 * s, color: active ? Colors.white : navy), Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : navy, fontSize: 11 * s, height: 1.15, fontWeight: FontWeight.w700))]))));
  }

  Widget _promo(BuildContext context, double s, double v) {
    return InkWell(onTap: () => _openCreateShipment(context), borderRadius: BorderRadius.circular(20 * s), child: Container(height: 126 * v, padding: EdgeInsets.fromLTRB(18 * s, 16 * v, 12 * s, 13 * v), decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(20 * s), boxShadow: const [BoxShadow(color: Color(0x18170C52), blurRadius: 18, offset: Offset(0, 7))]), child: Stack(children: [
      Positioned(left: 0, top: 0, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Aynı gün', style: TextStyle(color: Colors.white, fontSize: 22 * s, height: 1, fontWeight: FontWeight.w900)), SizedBox(height: 2 * v), Text('teslimat', style: TextStyle(color: orange, fontSize: 22 * s, height: 1, fontWeight: FontWeight.w900)), SizedBox(height: 7 * v), Text('Şehrinde hızlı ve güvenilir\nkurye deneyimi.', style: TextStyle(color: const Color(0xFFD8D2F0), fontSize: 10.5 * s, height: 1.25))])),
      Positioned(right: -3 * s, bottom: -8 * v, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(width: 36 * s, height: 43 * v, decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(8 * s))), SizedBox(width: 5 * s), Container(width: 47 * s, height: 58 * v, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF3B2182), borderRadius: BorderRadius.circular(9 * s)), child: Text('open', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13 * s))), SizedBox(width: 6 * s), Container(width: 31 * s, height: 34 * v, decoration: BoxDecoration(color: const Color(0xFFFF7A3D), borderRadius: BorderRadius.circular(8 * s)))])),
      Positioned(left: 0, bottom: 0, child: Container(padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 5 * v), decoration: BoxDecoration(border: Border.all(color: orange, width: 1.3), borderRadius: BorderRadius.circular(16 * s)), child: Row(children: [Text('Hemen gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10 * s)), SizedBox(width: 5 * s), Icon(Icons.arrow_forward_rounded, size: 14 * s, color: Colors.white)]))),
    ])));
  }

  Widget _recent(BuildContext context, double s, double v) {
    return Column(children: [
      Row(children: [Expanded(child: Text('Son Gönderilerim', style: TextStyle(color: navy, fontSize: 18 * s, fontWeight: FontWeight.w900))), InkWell(onTap: () => _openMyShipments(context), child: Padding(padding: EdgeInsets.symmetric(vertical: 5 * v), child: Row(children: [Text('Tümünü gör', style: TextStyle(color: muted, fontSize: 11 * s, fontWeight: FontWeight.w600)), SizedBox(width: 2 * s), Icon(Icons.chevron_right_rounded, color: muted, size: 17 * s)])))]),
      SizedBox(height: 10 * v),
      StreamBuilder<List<Map<String, dynamic>>>(stream: AppDataService.instance.watchShipments(), builder: (context, snapshot) {
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        if (snapshot.connectionState == ConnectionState.waiting && rows.isEmpty) return SizedBox(height: 74 * v, child: const Center(child: CircularProgressIndicator(color: orange)));
        if (rows.isEmpty) return _emptyShipment(context, s, v);
        return Column(children: rows.take(2).map((item) => Padding(padding: EdgeInsets.only(bottom: 8 * v), child: _shipmentCard(context, item, s, v))).toList());
      }),
    ]);
  }

  Widget _emptyShipment(BuildContext context, double s, double v) {
    return InkWell(onTap: () => _openCreateShipment(context), borderRadius: BorderRadius.circular(18 * s), child: Container(height: 76 * v, padding: EdgeInsets.symmetric(horizontal: 15 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s)), child: Row(children: [CircleAvatar(radius: 21 * s, backgroundColor: orangeSoft, child: Icon(Icons.inventory_2_outlined, color: orange, size: 22 * s)), SizedBox(width: 11 * s), Expanded(child: Text('Henüz gönderin yok\nİlk gönderini oluştur', style: TextStyle(color: navy, fontSize: 12 * s, fontWeight: FontWeight.w700, height: 1.3))), Icon(Icons.add_circle_outline_rounded, color: orange, size: 22 * s)])));
  }

  Widget _shipmentCard(BuildContext context, Map<String, dynamic> item, double s, double v) {
    final status = (item['status'] ?? '').toString();
    final code = (item['public_code'] ?? 'Gönderi').toString();
    final pickup = _shortAddress((item['pickup_address'] ?? '').toString());
    final dropoff = _shortAddress((item['dropoff_address'] ?? '').toString());
    final labels = <String, String>{'searching': 'Kurye aranıyor', 'accepted': 'Kurye yolda', 'at_pickup': 'Kurye alımda', 'picked_up': 'Yolda', 'at_dropoff': 'Teslimat noktasında', 'delivered': 'Teslim edildi', 'cancelled': 'İptal edildi'};
    final done = status == 'delivered';
    final cancelled = status == 'cancelled';
    final badgeColor = cancelled ? const Color(0xFFD95353) : green;
    final badgeBg = cancelled ? const Color(0xFFFFEAEA) : const Color(0xFFE2F6EF);
    return InkWell(onTap: () => _openMyShipments(context), borderRadius: BorderRadius.circular(18 * s), child: Container(height: 76 * v, padding: EdgeInsets.symmetric(horizontal: 12 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s)), child: Row(children: [
      CircleAvatar(radius: 21 * s, backgroundColor: done ? orangeSoft : const Color(0xFFF0EDFC), child: Icon(Icons.inventory_2_outlined, color: done ? orange : const Color(0xFF694DD1), size: 22 * s)),
      SizedBox(width: 10 * s),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(code, style: TextStyle(color: navy, fontSize: 12 * s, fontWeight: FontWeight.w900)), SizedBox(height: 1 * v), Text('$pickup → $dropoff', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: navy, fontSize: 11.5 * s, fontWeight: FontWeight.w700)), SizedBox(height: 1 * v), Text(labels[status] ?? 'Gönderi güncelleniyor', style: TextStyle(color: muted, fontSize: 9.5 * s))])),
      Container(padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 5 * v), decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(14 * s)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 7 * s, height: 7 * s, decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle)), SizedBox(width: 5 * s), Text(labels[status] ?? status, style: TextStyle(color: badgeColor, fontSize: 9.5 * s, fontWeight: FontWeight.w700))])),
    ])));
  }

  String _shortAddress(String value) {
    final parts = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? '-' : parts.first;
  }

  Widget _bottomNav(BuildContext context, double s, double v) {
    return Container(height: 68 * v, padding: EdgeInsets.fromLTRB(14 * s, 7 * v, 14 * s, 10 * v), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24 * s), topRight: Radius.circular(24 * s)), boxShadow: const [BoxShadow(color: Color(0x110D082F), blurRadius: 18, offset: Offset(0, -4))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_navItem(Icons.home_rounded, 'Ana Sayfa', true, () {}, s, v), _navItem(Icons.inventory_2_outlined, 'Gönderi', false, () => _openMyShipments(context), s, v), _navItem(Icons.location_on_outlined, 'Takip', false, () => _openMyShipments(context), s, v), _navItem(Icons.person_outline_rounded, 'Profil', false, () => _openProfile(context), s, v)]));
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap, double s, double v) {
    final color = active ? orange : const Color(0xFF7C8192);
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14 * s), child: Padding(padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 3 * v), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 21 * s), SizedBox(height: 3 * v), Text(label, style: TextStyle(color: color, fontSize: 9.5 * s, fontWeight: active ? FontWeight.w800 : FontWeight.w500))])));
  }
}
