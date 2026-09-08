import 'package:flutter/material.dart';

class CreateShipmentPage extends StatefulWidget {
  const CreateShipmentPage({super.key});

  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF7C879C);
  int vehicle = 0;
  int detail = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final s = c.maxWidth / 390;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16*s, 14*s, 16*s, 24*s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(s),
                  SizedBox(height: 16*s),
                  _infoBanner(s),
                  SizedBox(height: 20*s),
                  _sectionTitle(s, 'Taşıma Türü', trailing: 'Hangisini seçmeliyim?'),
                  SizedBox(height: 10*s),
                  Row(children: [
                    Expanded(child: _vehicleCard(s, 0, 'Motosiklet', 'Hızlı ve pratik', 'Genellikle 10–30 dk', 'assets/images/motosiklet_hd.png')),
                    SizedBox(width: 10*s),
                    Expanded(child: _vehicleCard(s, 1, 'Araç', 'Daha büyük gönderiler', 'Genellikle 20–60 dk', 'assets/images/arac_hd.png')),
                  ]),
                  SizedBox(height: 16*s),
                  _addressCard(s),
                  SizedBox(height: 16*s),
                  _detailsCard(s),
                  SizedBox(height: 16*s),
                  _cta(s),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(double s) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roundButton(s, Icons.arrow_back_rounded, () => Navigator.maybePop(context)),
          SizedBox(width: 14*s),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2*s),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Gönderi Oluştur', style: TextStyle(fontSize: 25*s, fontWeight: FontWeight.w900, color: navy, letterSpacing: -.5)),
                SizedBox(height: 3*s),
                Text('Hızlı, güvenli ve kolay', style: TextStyle(fontSize: 14*s, color: muted, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
          SizedBox(width: 8*s),
          _roundButton(s, Icons.help_outline_rounded, () {}),
        ],
      );

  Widget _roundButton(double s, IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20*s),
        child: Container(
          width: 44*s,
          height: 44*s,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17*s),
            boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 15, offset: Offset(0, 5))],
          ),
          child: Icon(icon, color: const Color(0xFF173C84), size: 25*s),
        ),
      );

  Widget _infoBanner(double s) => Container(
        height: 70*s,
        decoration: BoxDecoration(
          color: const Color(0xFFE9F4FF),
          borderRadius: BorderRadius.circular(18*s),
        ),
        child: Stack(
          children: [
            Positioned(left: 12*s, top: 15*s, child: Container(width: 40*s, height: 40*s, decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(13*s)), child: Icon(Icons.bolt_rounded, color: Colors.white, size: 27*s))),
            Positioned(left: 63*s, top: 13*s, right: 140*s, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Dakikalar içinde kurye yola çıksın!', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.2*s, fontWeight: FontWeight.w800, color: const Color(0xFF163C80))),
              SizedBox(height: 4*s),
              Text('İhtiyacın ne olursa olsun yanındayız.', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5*s, color: const Color(0xFF31578D))),
            ])),
            Positioned(right: -4*s, bottom: -5*s, width: 150*s, height: 92*s, child: Image.asset('assets/images/kurye_hd.png', fit: BoxFit.contain, alignment: Alignment.bottomRight, filterQuality: FilterQuality.high)),
          ],
        ),
      );

  Widget _sectionTitle(double s, String title, {String? trailing}) => Row(
        children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 19*s, fontWeight: FontWeight.w900, color: navy))),
          if (trailing != null) ...[
            Text(trailing, style: TextStyle(fontSize: 11*s, color: blue, fontWeight: FontWeight.w600)),
            Icon(Icons.chevron_right_rounded, size: 18*s, color: blue),
          ]
        ],
      );

  Widget _vehicleCard(double s, int index, String title, String sub, String time, String asset) {
    final selected = vehicle == index;
    return GestureDetector(
      onTap: () => setState(() => vehicle = index),
      child: Container(
        height: 168*s,
        padding: EdgeInsets.fromLTRB(10*s, 8*s, 10*s, 9*s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20*s),
          border: Border.all(color: selected ? blue : const Color(0xFFE7EDF5), width: selected ? 1.5 : 1),
          boxShadow: const [BoxShadow(color: Color(0x0E000000), blurRadius: 16, offset: Offset(0, 5))],
        ),
        child: Stack(
          children: [
            Positioned(right: 2*s, top: 0, child: Container(width: 24*s, height: 24*s, decoration: BoxDecoration(color: selected ? blue : Colors.white, shape: BoxShape.circle, border: Border.all(color: selected ? blue : const Color(0xFFD2DAE6), width: 1.4)), child: selected ? Icon(Icons.check_rounded, size: 17*s, color: Colors.white) : null)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 7*s), child: Image.asset(asset, fit: BoxFit.contain, filterQuality: FilterQuality.high)))),
              Text(title, style: TextStyle(fontSize: 16*s, fontWeight: FontWeight.w900, color: navy)),
              SizedBox(height: 1*s),
              Text(sub, style: TextStyle(fontSize: 11*s, color: muted)),
              SizedBox(height: 6*s),
              Container(padding: EdgeInsets.symmetric(horizontal: 9*s, vertical: 5*s), decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(14*s)), child: Text(time, style: TextStyle(fontSize: 9.5*s, color: blue, fontWeight: FontWeight.w700))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _addressCard(double s) => _card(
        s,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Adres Bilgileri', style: TextStyle(fontSize: 18*s, fontWeight: FontWeight.w900, color: navy))),
            Icon(Icons.map_outlined, color: blue, size: 19*s),
            SizedBox(width: 5*s),
            Text('Haritadan Seç', style: TextStyle(fontSize: 11.5*s, color: blue, fontWeight: FontWeight.w700)),
          ]),
          SizedBox(height: 14*s),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 31*s, child: Column(children: [
              Container(width: 12*s, height: 12*s, decoration: const BoxDecoration(color: blue, shape: BoxShape.circle)),
              Container(width: 1.4*s, height: 44*s, color: const Color(0xFFB7C8DF)),
              Container(width: 12*s, height: 12*s, decoration: const BoxDecoration(color: Color(0xFF14D789), shape: BoxShape.circle)),
            ])),
            SizedBox(width: 8*s),
            Expanded(child: Column(children: [
              _addressField(s, 'Alım Adresi', 'Detaylı adresini gir'),
              SizedBox(height: 10*s),
              _addressField(s, 'Teslimat Adresi', 'Detaylı adresini gir'),
            ])),
          ]),
          SizedBox(height: 10*s),
          Container(height: 43*s, padding: EdgeInsets.symmetric(horizontal: 12*s), decoration: BoxDecoration(color: const Color(0xFFF1F5FA), borderRadius: BorderRadius.circular(14*s)), child: Row(children: [
            Container(width: 26*s, height: 26*s, decoration: const BoxDecoration(color: Color(0xFF6EB5FF), shape: BoxShape.circle), child: Icon(Icons.add_rounded, color: Colors.white, size: 19*s)),
            SizedBox(width: 10*s),
            Text('Ara durak ekle (isteğe bağlı)', style: TextStyle(fontSize: 11.5*s, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ])),
        ]),
      );

  Widget _addressField(double s, String title, String sub) => Container(
        height: 58*s,
        padding: EdgeInsets.symmetric(horizontal: 11*s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15*s), border: Border.all(color: const Color(0xFFE7ECF3))),
        child: Row(children: [
          Container(width: 32*s, height: 32*s, decoration: const BoxDecoration(color: Color(0xFFF2F6FA), shape: BoxShape.circle), child: Icon(Icons.location_on_outlined, color: const Color(0xFF64748B), size: 20*s)),
          SizedBox(width: 10*s),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 12*s, fontWeight: FontWeight.w800, color: navy)),
            SizedBox(height: 2*s),
            Text(sub, style: TextStyle(fontSize: 10.5*s, color: const Color(0xFFA0A9B9))),
          ])),
          Icon(Icons.chevron_right_rounded, color: const Color(0xFF69778B), size: 21*s),
        ]),
      );

  Widget _detailsCard(double s) => _card(
        s,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Gönderi Detayları', style: TextStyle(fontSize: 18*s, fontWeight: FontWeight.w900, color: navy)),
          SizedBox(height: 12*s),
          Row(children: [
            Expanded(child: _detailChip(s, 0, Icons.inventory_2_outlined, 'Paket')),
            SizedBox(width: 7*s),
            Expanded(child: _detailChip(s, 1, Icons.restaurant_rounded, 'Yiyecek')),
            SizedBox(width: 7*s),
            Expanded(child: _detailChip(s, 2, Icons.description_outlined, 'Belge')),
            SizedBox(width: 7*s),
            Expanded(child: _detailChip(s, 3, Icons.grid_view_rounded, 'Diğer')),
          ]),
          SizedBox(height: 10*s),
          Row(children: [
            Expanded(child: _selectBox(s, Icons.scale_outlined, 'Tahmini Ağırlık', 'Seçiniz')),
            SizedBox(width: 10*s),
            Expanded(child: _selectBox(s, Icons.deployed_code_outlined, 'Tahmini Boyut', 'Seçiniz')),
          ]),
          SizedBox(height: 10*s),
          Container(height: 64*s, padding: EdgeInsets.symmetric(horizontal: 12*s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15*s), border: Border.all(color: const Color(0xFFE7ECF3))), child: Row(children: [
            Container(width: 31*s, height: 31*s, decoration: const BoxDecoration(color: Color(0xFFF2F6FA), shape: BoxShape.circle), child: Icon(Icons.chat_bubble_outline_rounded, color: const Color(0xFF65748A), size: 18*s)),
            SizedBox(width: 10*s),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ek Not (isteğe bağlı)', style: TextStyle(fontSize: 11*s, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
              SizedBox(height: 2*s),
              Text('Örn: Dikkatli taşınsın, kapıya bırakın, arayın...', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5*s, color: const Color(0xFFA0A9B9))),
            ])),
          ])),
        ]),
      );

  Widget _detailChip(double s, int index, IconData icon, String label) {
    final selected = detail == index;
    return GestureDetector(
      onTap: () => setState(() => detail = index),
      child: Container(
        height: 48*s,
        decoration: BoxDecoration(color: selected ? const Color(0xFFF3F9FF) : Colors.white, borderRadius: BorderRadius.circular(14*s), border: Border.all(color: selected ? blue : const Color(0xFFE5EAF2), width: selected ? 1.3 : 1)),
        child: Stack(children: [
          Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: selected ? blue : const Color(0xFF607089), size: 18*s), SizedBox(width: 5*s), Text(label, style: TextStyle(fontSize: 10*s, color: selected ? blue : const Color(0xFF607089), fontWeight: FontWeight.w700))])),
          if (selected) Positioned(right: 3*s, top: 3*s, child: Container(width: 14*s, height: 14*s, decoration: const BoxDecoration(color: blue, shape: BoxShape.circle), child: Icon(Icons.check_rounded, color: Colors.white, size: 10*s))),
        ]),
      ),
    );
  }

  Widget _selectBox(double s, IconData icon, String title, String value) => Container(
        height: 58*s,
        padding: EdgeInsets.symmetric(horizontal: 10*s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15*s), border: Border.all(color: const Color(0xFFE7ECF3))),
        child: Row(children: [
          Container(width: 31*s, height: 31*s, decoration: const BoxDecoration(color: Color(0xFFF2F6FA), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF65748A), size: 18*s)),
          SizedBox(width: 8*s),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 9.4*s, color: const Color(0xFF64748B))),
            SizedBox(height: 2*s),
            Text(value, style: TextStyle(fontSize: 10.5*s, color: const Color(0xFF9AA4B5), fontWeight: FontWeight.w500)),
          ])),
          Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF56657B), size: 20*s),
        ]),
      );

  Widget _card(double s, {required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(12*s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20*s), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 5))]),
        child: child,
      );

  Widget _cta(double s) => SizedBox(
        width: double.infinity,
        height: 60*s,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1287FF), Color(0xFF0D76F4)]), borderRadius: BorderRadius.circular(20*s), boxShadow: const [BoxShadow(color: Color(0x251489FF), blurRadius: 18, offset: Offset(0, 8))]),
          child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.near_me_rounded, color: Colors.white, size: 24*s), SizedBox(width: 11*s), Text('Gönderi Oluştur', style: TextStyle(color: Colors.white, fontSize: 18*s, fontWeight: FontWeight.w800))])),
        ),
      );
}
