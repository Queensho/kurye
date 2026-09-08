import 'package:flutter/material.dart';
import 'create_shipment_page_v2.dart';

class HomePixelPreview extends StatelessWidget {
  const HomePixelPreview({super.key});

  static const blue = Color(0xFF178EF4);
  static const deepBlue = Color(0xFF0E3E8E);
  static const muted = Color(0xFF7A8390);

  void _openCreateShipment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateShipmentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: LayoutBuilder(builder: (context, c) {
        final sx = c.maxWidth / 390;
        final targetHeight = 735 * sx;
        final vy = c.maxHeight < targetHeight ? c.maxHeight / targetHeight : 1.0;
        final y = sx * vy;
        final fs = sx * (0.94 + 0.06 * vy);

        return Column(children: [
          _hero(context, sx, y, fs),
          Transform.translate(
            offset: Offset(0, -7 * y),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10 * sx),
              child: _vehicles(context, sx, y, fs),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -2 * y),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10 * sx),
              child: _promo(sx, y),
            ),
          ),
          SizedBox(height: 7 * y),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12 * sx),
            child: _recent(sx, y, fs),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(10 * sx, 0, 10 * sx, 8 * y),
            child: _nav(sx, y, fs),
          ),
        ]);
      }),
    );
  }

  Widget _hero(BuildContext context, double sx, double y, double fs) => SizedBox(
        height: 300 * y,
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF58C5F5), Color(0xFF7DD8F8), Color(0xFFD9F7FF)],
            ),
          ),
          child: Stack(children: [
            Positioned(
              left: 18 * sx,
              top: 18 * y,
              child: Row(children: [
                Icon(Icons.location_on_rounded, color: Colors.white, size: 25 * fs),
                SizedBox(width: 7 * sx),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('İstanbul', style: TextStyle(fontSize: 17 * fs, fontWeight: FontWeight.w800, color: deepBlue)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18 * fs, color: const Color(0xFF2A91DA)),
                  ]),
                  Text('Şişli, Mecidiyeköy', style: TextStyle(fontSize: 11 * fs, color: const Color(0xFF245891))),
                ]),
              ]),
            ),
            Positioned(
              right: 16 * sx,
              top: 17 * y,
              child: CircleAvatar(
                radius: 22 * sx,
                backgroundColor: Colors.white.withOpacity(.72),
                child: ClipOval(child: Image.asset('assets/images/kurye_hd.png', fit: BoxFit.cover)),
              ),
            ),
            Positioned(
              right: 72 * sx,
              top: 38 * y,
              child: Opacity(opacity: .7, child: Icon(Icons.location_on_rounded, size: 112 * fs, color: Colors.white)),
            ),
            Positioned(
              left: 17 * sx,
              top: 73 * y,
              width: 172 * sx,
              height: 115 * y,
              child: Image.asset('assets/images/hero_text_hd.png', fit: BoxFit.contain, alignment: Alignment.centerLeft),
            ),
            Positioned(
              left: 20 * sx,
              top: 183 * y,
              child: Text('İhtiyacın ne olursa olsun\nyanındayız.', style: TextStyle(fontSize: 12 * fs, height: 1.4, color: Colors.white, fontWeight: FontWeight.w500)),
            ),
            Positioned(
              right: -4 * sx,
              top: 55 * y,
              width: 210 * sx,
              height: 198 * y,
              child: Image.asset('assets/images/kurye_hd.png', fit: BoxFit.contain, filterQuality: FilterQuality.high),
            ),
            Positioned(
              left: 18 * sx,
              right: 18 * sx,
              bottom: 16 * y,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openCreateShipment(context),
                  borderRadius: BorderRadius.circular(26 * sx),
                  child: Container(
                    height: 48 * y,
                    padding: EdgeInsets.symmetric(horizontal: 10 * sx),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26 * sx), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 15, offset: Offset(0, 5))]),
                    child: Row(children: [
                      Container(width: 36 * sx, height: 36 * sx, decoration: const BoxDecoration(color: blue, shape: BoxShape.circle), child: Icon(Icons.add_rounded, size: 25 * fs, color: Colors.white)),
                      SizedBox(width: 10 * sx),
                      Expanded(child: Text('Gönderi Oluştur', style: TextStyle(fontSize: 16 * fs, fontWeight: FontWeight.w800, color: deepBlue))),
                      Icon(Icons.chevron_right_rounded, size: 25 * fs, color: blue),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );

  Widget _vehicles(BuildContext context, double sx, double y, double fs) => Container(
        height: 154 * y,
        padding: EdgeInsets.all(7 * sx),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23 * sx), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))]),
        child: Row(children: [
          Expanded(child: _vehicle(context, sx, y, fs, 'Araç', 'Daha büyük gönderiler\niçin ideal', 'assets/images/arac_hd.png')),
          SizedBox(width: 7 * sx),
          Expanded(child: _vehicle(context, sx, y, fs, 'Motosiklet', 'Hızlı ve pratik\nteslimat', 'assets/images/motosiklet_hd.png')),
        ]),
      );

  Widget _vehicle(BuildContext context, double sx, double y, double fs, String title, String subtitle, String asset) => InkWell(
        onTap: () => _openCreateShipment(context),
        borderRadius: BorderRadius.circular(19 * sx),
        child: Container(
          padding: EdgeInsets.fromLTRB(9 * sx, 4 * y, 8 * sx, 8 * y),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF0F9FF)]), borderRadius: BorderRadius.circular(19 * sx)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Center(child: Image.asset(asset, fit: BoxFit.contain, filterQuality: FilterQuality.high))),
            Text(title, style: TextStyle(fontSize: 15 * fs, fontWeight: FontWeight.w900, color: const Color(0xFF11182A))),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: Text(subtitle, style: TextStyle(fontSize: 9.5 * fs, height: 1.25, color: muted))),
              Container(width: 28 * sx, height: 28 * sx, decoration: const BoxDecoration(color: Color(0xFFDDF3FF), shape: BoxShape.circle), child: Icon(Icons.chevron_right_rounded, color: blue, size: 21 * fs)),
            ]),
          ]),
        ),
      );

  Widget _promo(double sx, double y) => ClipRRect(
        borderRadius: BorderRadius.circular(18 * sx),
        child: SizedBox(
          height: 96 * y,
          width: double.infinity,
          child: Image.asset('assets/images/promo_hd.png', fit: BoxFit.cover, filterQuality: FilterQuality.high),
        ),
      );

  Widget _recent(double sx, double y, double fs) => Column(children: [
        Row(children: [
          Expanded(child: Text('Son Gönderilerim', style: TextStyle(fontSize: 16 * fs, fontWeight: FontWeight.w900))),
          Text('Tümünü Gör', style: TextStyle(fontSize: 10 * fs, color: blue, fontWeight: FontWeight.w700)),
          Icon(Icons.chevron_right_rounded, size: 15 * fs, color: const Color(0xFF8C939B)),
        ]),
        SizedBox(height: 6 * y),
        Container(
          height: 66 * y,
          padding: EdgeInsets.all(8 * sx),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * sx)),
          child: Row(children: [
            CircleAvatar(radius: 24 * sx, backgroundColor: const Color(0xFFF7F4EF), child: Icon(Icons.inventory_2_rounded, size: 27 * fs, color: const Color(0xFFD69A50))),
            SizedBox(width: 8 * sx),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#12458', style: TextStyle(fontSize: 10 * fs, fontWeight: FontWeight.w700)),
              Text('Şişli → Kadıköy', style: TextStyle(fontSize: 12 * fs, fontWeight: FontWeight.w800)),
              Text('Teslim edildi', style: TextStyle(fontSize: 9 * fs, color: muted)),
            ])),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Dün 14:32', style: TextStyle(fontSize: 8 * fs, color: muted)),
              SizedBox(height: 6 * y),
              Container(padding: EdgeInsets.symmetric(horizontal: 7 * sx, vertical: 4 * y), decoration: BoxDecoration(color: const Color(0xFFDDF8E4), borderRadius: BorderRadius.circular(12 * sx)), child: Text('✓ Tamamlandı', style: TextStyle(fontSize: 8 * fs, color: const Color(0xFF11843A), fontWeight: FontWeight.w700))),
            ]),
          ]),
        ),
      ]);

  Widget _nav(double sx, double y, double fs) => Container(
        height: 60 * y,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25 * sx), boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 16, offset: Offset(0, 5))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _navItem(fs, Icons.home_rounded, 'Ana Sayfa', true),
          _navItem(fs, Icons.receipt_long_rounded, 'Gönderilerim', false),
          _navItem(fs, Icons.chat_bubble_outline_rounded, 'Mesajlar', false),
          _navItem(fs, Icons.person_outline_rounded, 'Profilim', false),
        ]),
      );

  Widget _navItem(double fs, IconData icon, String label, bool active) {
    final color = active ? blue : muted;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 21 * fs, color: color),
      Text(label, style: TextStyle(fontSize: 8.5 * fs, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: color)),
    ]);
  }
}
