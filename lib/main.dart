import 'package:flutter/material.dart';

void main() {
  runApp(const KuryeApp());
}

class KuryeApp extends StatelessWidget {
  const KuryeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kurye',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF168CF5)),
      ),
      home: const CustomerHomePage(),
    );
  }
}

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;

  static const _blue = Color(0xFF168CF5);
  static const _deepBlue = Color(0xFF0E3E8E);
  static const _text = Color(0xFF11182A);
  static const _muted = Color(0xFF7A8390);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHero()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Transform.translate(
                        offset: const Offset(0, -14),
                        child: _buildVehicleSection(),
                      ),
                      const SizedBox(height: 0),
                      _buildPromo(),
                      const SizedBox(height: 26),
                      _buildRecentHeader(),
                      const SizedBox(height: 14),
                      _buildRecentOrder(),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      height: 620,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF62C8F8), Color(0xFF8BDCF8), Color(0xFFDDF7FF)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 75,
            top: 75,
            child: Opacity(
              opacity: .72,
              child: Icon(Icons.location_on_rounded, size: 215, color: Colors.white),
            ),
          ),
          Positioned(
            left: 28,
            top: 58,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white, size: 40),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Text('İstanbul', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _deepBlue)),
                        SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2489DD)),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text('Şişli, Mecidiyeköy', style: TextStyle(fontSize: 16, color: Color(0xFF174E91), fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 24,
            top: 58,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.7),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/profil_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: _blue, size: 34),
                    ),
                  ),
                ),
                Positioned(
                  right: -1,
                  top: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(color: Color(0xFFFF4A3D), shape: BoxShape.circle),
                    child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 28,
            top: 180,
            width: 305,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white, Color(0xFF168CF5)],
                  ).createShader(bounds),
                  child: const Text(
                    'Hızlı\nGüvenli\nTeslimat',
                    style: TextStyle(
                      height: .88,
                      fontSize: 50,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.3,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Color(0x550A58C7), blurRadius: 3, offset: Offset(0, 3)),
                        Shadow(color: Color(0x33000000), blurRadius: 9, offset: Offset(0, 5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'İhtiyacın ne olursa olsun\nyanındayız.',
                  style: TextStyle(color: Colors.white, fontSize: 18, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Positioned(
            right: -12,
            top: 155,
            width: 330,
            height: 350,
            child: Image.asset(
              'assets/images/3d_kurye.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            left: 28,
            bottom: 34,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () => _showShipmentSheet(context),
              child: Container(
                height: 76,
                width: 372,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 18),
                    const Expanded(
                      child: Text('Gönderi Oluştur', style: TextStyle(color: _deepBlue, fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _blue, size: 34),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [BoxShadow(color: const Color(0xFF85BDE7).withOpacity(.12), blurRadius: 26, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _vehicleCard(
              title: 'Araç',
              subtitle: 'Daha büyük gönderiler\niçin ideal',
              asset: 'assets/images/arac.png',
              onTap: () => _showShipmentSheet(context, type: 'Araç'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _vehicleCard(
              title: 'Motosiklet',
              subtitle: 'Hızlı ve pratik\nteslimat',
              asset: 'assets/images/motosiklet.png',
              onTap: () => _showShipmentSheet(context, type: 'Motosiklet'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard({required String title, required String subtitle, required String asset, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        height: 285,
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Color(0xFFF1F9FF)]),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(title == 'Araç' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded, size: 100, color: _blue),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: _text)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 15, height: 1.35, color: _muted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(color: Color(0xFFDDF3FF), shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_right_rounded, color: _blue, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromo() {
    return Container(
      height: 195,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF4BB8F1), Color(0xFF54C6F8)]),
        boxShadow: [BoxShadow(color: const Color(0xFF4BB8F1).withOpacity(.18), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('İlk gönderinde', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                const Text('%20 indirim!', style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.w900)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('KOD: MERHABA20', style: TextStyle(fontWeight: FontWeight.w900, color: _deepBlue)),
                      SizedBox(width: 9),
                      Icon(Icons.copy_rounded, size: 18, color: _blue),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 9,
            bottom: 9,
            width: 245,
            child: Image.asset(
              'assets/images/indirim_banner.png',
              alignment: Alignment.centerRight,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard_rounded, size: 120, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      children: [
        const Expanded(child: Text('Son Gönderilerim', style: TextStyle(color: _text, fontSize: 26, fontWeight: FontWeight.w900))),
        TextButton.icon(
          onPressed: () {},
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.chevron_right_rounded, size: 24),
          label: const Text('Tümünü Gör', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildRecentOrder() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: Color(0xFFF7F4EF), shape: BoxShape.circle),
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/images/koli.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_rounded, color: Color(0xFFD69A50), size: 42),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#12458', style: TextStyle(fontSize: 18, color: Color(0xFF404756), fontWeight: FontWeight.w700)),
                SizedBox(height: 3),
                Text('Şişli → Kadıköy', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _text)),
                SizedBox(height: 4),
                Text('Teslim edildi', style: TextStyle(fontSize: 15, color: _muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Dün 14:32', style: TextStyle(color: _muted, fontSize: 14)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(color: const Color(0xFFDDF8E4), borderRadius: BorderRadius.circular(22)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF12A64A), size: 22),
                    SizedBox(width: 6),
                    Text('Tamamlandı', style: TextStyle(color: Color(0xFF14964A), fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = <({IconData icon, String label})>[
      (icon: Icons.home_rounded, label: 'Ana Sayfa'),
      (icon: Icons.receipt_long_rounded, label: 'Gönderilerim'),
      (icon: Icons.chat_bubble_outline_rounded, label: 'Mesajlar'),
      (icon: Icons.person_outline_rounded, label: 'Profilim'),
    ];

    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.96),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [BoxShadow(color: const Color(0xFF16385D).withOpacity(.12), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final active = index == _selectedIndex;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () => setState(() => _selectedIndex = index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(items[index].icon, size: 31, color: active ? _blue : const Color(0xFF7D8490)),
                  const SizedBox(height: 3),
                  Text(items[index].label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? _blue : const Color(0xFF6E7480))),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showShipmentSheet(BuildContext context, {String? type}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFD9DFE6), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(type == null ? 'Gönderi oluştur' : '$type ile gönderi', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _text)),
              const SizedBox(height: 10),
              const Text('Adres ve gönderi detaylarını bir sonraki adımda gireceksin.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: _muted, height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Devam Et', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
