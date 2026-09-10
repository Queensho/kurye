import 'package:flutter/material.dart';

import 'create_shipment_page_v2.dart';
import 'data/app_data_service.dart';
import 'messages_page.dart';
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
  void _openMessages(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessagesPage()));
  void _openProfile(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _hero(context),
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _destinationCard(context),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _quickActions(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _promo(context),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _recent(context),
                    ),
                  ],
                ),
              ),
            ),
            _bottomNav(context),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return SizedBox(
      height: 385,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(34), bottomRight: Radius.circular(34)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFFAFAFD)),
            Positioned(
              right: -110,
              top: -165,
              child: Container(
                width: 390,
                height: 390,
                decoration: const BoxDecoration(color: purple, shape: BoxShape.circle),
              ),
            ),
            Positioned(
              right: -58,
              top: -127,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
              ),
            ),
            Positioned(
              left: -62,
              top: -145,
              child: Transform.rotate(
                angle: -.22,
                child: Container(
                  width: 122,
                  height: 360,
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: .42),
                    borderRadius: BorderRadius.circular(80),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 24,
              top: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'open', style: TextStyle(color: navy)),
                      TextSpan(text: '.', style: TextStyle(color: orange)),
                    ]),
                    style: TextStyle(fontSize: 47, height: .95, fontWeight: FontWeight.w900, letterSpacing: -2.4),
                  ),
                  SizedBox(height: 2),
                  Text('Her gönderi daha yakın', style: TextStyle(color: navy, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Positioned(
              right: -22,
              top: 67,
              width: 250,
              height: 260,
              child: Image.asset(
                'assets/images/kurye_header_hd.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                filterQuality: FilterQuality.high,
              ),
            ),
            const Positioned(
              left: 24,
              top: 145,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gönderin', style: TextStyle(color: navy, fontSize: 41, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1.8)),
                  SizedBox(height: 3),
                  Text('yola çıksın', style: TextStyle(color: orange, fontSize: 41, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1.8)),
                  SizedBox(height: 13),
                  Text('Hızlı, güvenli ve kolay\nteslimat çözümleri.', style: TextStyle(color: muted, fontSize: 17, height: 1.3, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        onTap: () => _openCreateShipment(context),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color(0x120F0A38), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Row(
            children: [
              Container(
                width: 53,
                height: 53,
                decoration: const BoxDecoration(color: Color(0xFFF3F1FA), shape: BoxShape.circle),
                child: const Icon(Icons.location_on_rounded, color: navy, size: 30),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nereye gönderiyorsun?', style: TextStyle(color: navy, fontSize: 16.5, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('Alıcı adresini gir', style: TextStyle(color: muted, fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9A99A8), size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    final actions = [
      (Icons.inventory_2_outlined, 'Gönderi\nOluştur', true, () => _openCreateShipment(context)),
      (Icons.receipt_long_outlined, 'Fiyat\nHesapla', false, () => _openCreateShipment(context)),
      (Icons.location_on_outlined, 'Canlı\nTakip', false, () => _openMyShipments(context)),
      (Icons.history_rounded, 'Geçmiş\nGönderiler', false, () => _openMyShipments(context)),
    ];
    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 9),
          Expanded(child: _actionCard(actions[i].$1, actions[i].$2, actions[i].$3, actions[i].$4)),
        ],
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, bool active, VoidCallback onTap) {
    return Material(
      color: active ? orange : Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          height: 118,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            boxShadow: active ? const [] : const [BoxShadow(color: Color(0x0D100A39), blurRadius: 18, offset: Offset(0, 7))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 31, color: active ? Colors.white : navy),
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : navy, fontSize: 13, height: 1.2, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promo(BuildContext context) {
    return InkWell(
      onTap: () => _openCreateShipment(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 156,
        padding: const EdgeInsets.fromLTRB(21, 20, 14, 16),
        decoration: BoxDecoration(
          color: purple,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x18170C52), blurRadius: 22, offset: Offset(0, 9))],
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              top: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aynı gün', style: TextStyle(color: Colors.white, fontSize: 27, height: 1, fontWeight: FontWeight.w900)),
                  SizedBox(height: 2),
                  Text('teslimat', style: TextStyle(color: orange, fontSize: 27, height: 1, fontWeight: FontWeight.w900)),
                  SizedBox(height: 9),
                  Text('Şehrinde hızlı ve güvenilir\nkurye deneyimi.', style: TextStyle(color: Color(0xFFD8D2F0), fontSize: 12.5, height: 1.3)),
                ],
              ),
            ),
            Positioned(
              right: -5,
              bottom: -10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: 45, height: 55, decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(9))),
                  const SizedBox(width: 6),
                  Container(width: 58, height: 73, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF3B2182), borderRadius: BorderRadius.circular(11)), child: const Text('open', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
                  const SizedBox(width: 7),
                  Container(width: 39, height: 43, decoration: BoxDecoration(color: const Color(0xFFFF7A3D), borderRadius: BorderRadius.circular(9))),
                ],
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(border: Border.all(color: orange, width: 1.5), borderRadius: BorderRadius.circular(18)),
                child: const Row(children: [Text('Hemen gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)), SizedBox(width: 7), Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white)]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recent(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Text('Son Gönderilerim', style: TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900))),
            InkWell(
              onTap: () => _openMyShipments(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [Text('Tümünü gör', style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600)), SizedBox(width: 3), Icon(Icons.chevron_right_rounded, color: muted, size: 20)]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: AppDataService.instance.watchShipments(),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <Map<String, dynamic>>[];
            if (snapshot.connectionState == ConnectionState.waiting && rows.isEmpty) {
              return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator(color: orange)));
            }
            if (rows.isEmpty) {
              return _emptyShipment(context);
            }
            return Column(
              children: rows.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _shipmentCard(context, item),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _emptyShipment(BuildContext context) {
    return InkWell(
      onTap: () => _openCreateShipment(context),
      borderRadius: BorderRadius.circular(21),
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21)),
        child: const Row(children: [
          CircleAvatar(radius: 25, backgroundColor: orangeSoft, child: Icon(Icons.inventory_2_outlined, color: orange)),
          SizedBox(width: 13),
          Expanded(child: Text('Henüz gönderin yok\nİlk gönderini oluştur', style: TextStyle(color: navy, fontWeight: FontWeight.w700, height: 1.35))),
          Icon(Icons.add_circle_outline_rounded, color: orange),
        ]),
      ),
    );
  }

  Widget _shipmentCard(BuildContext context, Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString();
    final code = (item['public_code'] ?? 'Gönderi').toString();
    final pickup = _shortAddress((item['pickup_address'] ?? '').toString());
    final dropoff = _shortAddress((item['dropoff_address'] ?? '').toString());
    final labels = <String, String>{
      'searching': 'Kurye aranıyor',
      'accepted': 'Kurye yolda',
      'at_pickup': 'Kurye alımda',
      'picked_up': 'Yolda',
      'at_dropoff': 'Teslimat noktasında',
      'delivered': 'Teslim edildi',
      'cancelled': 'İptal edildi',
    };
    final done = status == 'delivered';
    final cancelled = status == 'cancelled';
    final badgeColor = done ? green : cancelled ? const Color(0xFFD95353) : green;
    final badgeBg = done ? const Color(0xFFE2F6EF) : cancelled ? const Color(0xFFFFEAEA) : const Color(0xFFE2F6EF);
    return InkWell(
      onTap: () => _openMyShipments(context),
      borderRadius: BorderRadius.circular(21),
      child: Container(
        height: 91,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: done ? orangeSoft : const Color(0xFFF0EDFC),
              child: Icon(Icons.inventory_2_outlined, color: done ? orange : const Color(0xFF694DD1), size: 27),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code, style: const TextStyle(color: navy, fontSize: 14, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text('$pickup → $dropoff', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: navy, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(labels[status] ?? 'Gönderi güncelleniyor', style: const TextStyle(color: muted, fontSize: 11.5)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(labels[status] ?? status, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortAddress(String value) {
    final parts = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? '-' : parts.first;
  }

  Widget _bottomNav(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x110D082F), blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 'Ana Sayfa', true, () {}),
          _navItem(Icons.inventory_2_outlined, 'Gönderi', false, () => _openMyShipments(context)),
          _navItem(Icons.location_on_outlined, 'Takip', false, () => _openMyShipments(context)),
          _navItem(Icons.person_outline_rounded, 'Profil', false, () => _openProfile(context)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    final color = active ? orange : const Color(0xFF7C8192);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
