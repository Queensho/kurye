import 'package:flutter/material.dart';

class CourierProfilePage extends StatefulWidget {
  const CourierProfilePage({super.key});

  @override
  State<CourierProfilePage> createState() => _CourierProfilePageState();
}

class _CourierProfilePageState extends State<CourierProfilePage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF718198);
  static const green = Color(0xFF16B96B);
  static const bg = Color(0xFFF5FAFF);

  bool available = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                child: Column(
                  children: [
                    _header(),
                    const SizedBox(height: 24),
                    _profileHeader(),
                    const SizedBox(height: 20),
                    _stats(),
                    const SizedBox(height: 16),
                    _vehicleCard(),
                    const SizedBox(height: 16),
                    _workStatus(),
                    const SizedBox(height: 16),
                    _menuCard(),
                    const SizedBox(height: 16),
                    _logoutButton(),
                  ],
                ),
              ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Row(
        children: [
          _roundButton(Icons.arrow_back_rounded, () => Navigator.maybePop(context)),
          const Expanded(
            child: Column(
              children: [
                Text('Kurye Profilim', style: TextStyle(color: navy, fontSize: 25, fontWeight: FontWeight.w900)),
                SizedBox(height: 3),
                Text('Hesabını yönet, bilgilerini güncelle.', style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ),
          _roundButton(Icons.settings_rounded, () => _showInfo('Uygulama Ayarları')),
        ],
      );

  Widget _roundButton(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 5))],
          ),
          child: Icon(icon, color: navy),
        ),
      );

  Widget _profileHeader() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F2FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 6))],
                ),
                child: const Icon(Icons.person_rounded, color: blue, size: 68),
              ),
              Positioned(
                right: -2,
                bottom: 4,
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: navy,
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Flexible(child: Text('Ahmet Yılmaz', style: TextStyle(color: navy, fontSize: 22, fontWeight: FontWeight.w900))),
                  const SizedBox(width: 7),
                  const Icon(Icons.verified_rounded, color: blue, size: 21),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(color: const Color(0xFFE7FAF0), borderRadius: BorderRadius.circular(18)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [
                      CircleAvatar(radius: 5, backgroundColor: green),
                      SizedBox(width: 6),
                      Text('Aktif', style: TextStyle(color: green, fontSize: 12, fontWeight: FontWeight.w900)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, color: green, size: 17),
                    ]),
                  ),
                ]),
                const SizedBox(height: 5),
                const Text('+90 555 123 45 67', style: TextStyle(color: muted, fontSize: 14)),
                const SizedBox(height: 10),
                Row(children: const [
                  Icon(Icons.star_rounded, color: Color(0xFFFFB900), size: 21),
                  Icon(Icons.star_rounded, color: Color(0xFFFFB900), size: 21),
                  Icon(Icons.star_rounded, color: Color(0xFFFFB900), size: 21),
                  Icon(Icons.star_rounded, color: Color(0xFFFFB900), size: 21),
                  Icon(Icons.star_rounded, color: Color(0xFFFFB900), size: 21),
                  SizedBox(width: 5),
                  Text('4.9', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
                  SizedBox(width: 4),
                  Text('(320 değerlendirme)', style: TextStyle(color: muted, fontSize: 11)),
                ]),
              ],
            ),
          ),
        ],
      );

  Widget _stats() {
    final items = [
      (Icons.inventory_2_rounded, '1.248', 'Toplam Teslimat'),
      (Icons.emoji_events_rounded, '%98', 'Başarı Oranı'),
      (Icons.schedule_rounded, '4.9', 'Müşteri Puanı'),
    ];
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(
            child: Container(
              height: 96,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23)),
              child: Row(children: [
                CircleAvatar(radius: 22, backgroundColor: const Color(0xFFEAF5FF), child: Icon(items[i].$1, color: blue)),
                const SizedBox(width: 9),
                Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(items[i].$2, style: const TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w900)),
                  Text(items[i].$3, style: const TextStyle(color: muted, fontSize: 10)),
                ])),
              ]),
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _vehicleCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
        child: Row(children: [
          Container(
            width: 92,
            height: 70,
            decoration: BoxDecoration(color: const Color(0xFFEAF5FF), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.two_wheeler_rounded, color: blue, size: 50),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Yamaha NMAX 125', style: TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.w900)),
            SizedBox(height: 5),
            Text('34 ABC 123', style: TextStyle(color: muted, fontSize: 14)),
          ])),
          FilledButton(
            onPressed: () => _showInfo('Araç Bilgilerini Düzenle'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEAF5FF), foregroundColor: blue, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Araç Bilgilerini\nDüzenle', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)), SizedBox(width: 4), Icon(Icons.chevron_right_rounded)]),
          ),
        ]),
      );

  Widget _workStatus() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE9F5FF), Color(0xFFF4FAFF)]),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Çalışma Durumu', style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(available ? 'Şu anda yeni iş alabilirsin.' : 'Şu anda iş almıyorsun.', style: const TextStyle(color: muted, fontSize: 12)),
            ])),
            Switch(value: available, onChanged: (v) => setState(() => available = v), activeThumbColor: Colors.white, activeTrackColor: blue),
          ]),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => setState(() => available = !available),
            icon: Icon(available ? Icons.play_arrow_rounded : Icons.pause_rounded),
            label: Text(available ? 'İşe Hazırım' : 'Çevrimdışıyım'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ]),
      );

  Widget _menuCard() {
    final items = [
      (Icons.person_outline_rounded, 'Kişisel Bilgiler', 'Ad, soyad, telefon, e-posta'),
      (Icons.description_outlined, 'Ehliyet & Belgeler', 'Ehliyet, ruhsat, sigorta'),
      (Icons.credit_card_rounded, 'Ödeme Bilgileri', 'Banka hesabı ve kazanç ayarları'),
      (Icons.settings_outlined, 'Uygulama Ayarları', 'Bildirimler, harita, dil'),
      (Icons.help_outline_rounded, 'Yardım & Destek', 'Sık sorulan sorular'),
    ];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(children: [
        for (int i = 0; i < items.length; i++) ...[
          InkWell(
            onTap: () => _showInfo(items[i].$2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(children: [
                CircleAvatar(radius: 23, backgroundColor: const Color(0xFFEAF5FF), child: Icon(items[i].$1, color: blue)),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(items[i].$2, style: const TextStyle(color: navy, fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(items[i].$3, style: const TextStyle(color: muted, fontSize: 11)),
                ])),
                const Icon(Icons.chevron_right_rounded, color: muted),
              ]),
            ),
          ),
          if (i < items.length - 1) const Divider(height: 1, indent: 72, endIndent: 16, color: Color(0xFFE9EFF5)),
        ],
      ]),
    );
  }

  Widget _logoutButton() => FilledButton.icon(
        onPressed: _logoutDialog,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Çıkış Yap'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58), backgroundColor: const Color(0xFFFFEDEE), foregroundColor: const Color(0xFFFF4D55), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      );

  Widget _bottomNav() {
    final items = const [
      (Icons.home_outlined, 'Anasayfa'),
      (Icons.inventory_2_outlined, 'İşler'),
      (Icons.bar_chart_rounded, 'Kazançlar'),
      (Icons.person_rounded, 'Profil'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 18, offset: Offset(0, 7))]),
      child: Row(children: [
        for (int i = 0; i < items.length; i++)
          Expanded(
            child: InkWell(
              onTap: () {
                if (i == 0) Navigator.maybePop(context);
                if (i != 0 && i != 3) _showInfo(items[i].$2);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(items[i].$1, color: i == 3 ? blue : const Color(0xFF7F8DA0), size: 25),
                  const SizedBox(height: 3),
                  Text(items[i].$2, style: TextStyle(color: i == 3 ? blue : const Color(0xFF7F8DA0), fontSize: 9.5, fontWeight: i == 3 ? FontWeight.w900 : FontWeight.w600)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  void _showInfo(String title) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: navy, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text('Bu bölüm gerçek kurye hesabı verileriyle bağlandığında düzenlenebilir olacak.', style: TextStyle(color: muted, fontSize: 13, height: 1.4)),
        ]),
      ),
    );
  }

  void _logoutDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Çıkış yapmak istiyor musun?'),
        content: const Text('Kurye hesabından çıkış yapılacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF4D55)), child: const Text('Çıkış Yap')),
        ],
      ),
    );
  }
}
