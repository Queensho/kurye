import 'package:flutter/material.dart';

import 'courier_job_pool_page.dart';

class CourierHomePage extends StatefulWidget {
  const CourierHomePage({super.key});

  @override
  State<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends State<CourierHomePage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const lime = Color(0xFFD7FF45);
  static const green = Color(0xFF20D985);
  static const muted = Color(0xFF7B8797);

  bool online = true;
  int selectedTab = 0;

  void _openJobPool() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CourierJobPoolPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _hero(),
                    const SizedBox(height: 14),
                    _quickCards(),
                    const SizedBox(height: 14),
                    _stats(),
                    const SizedBox(height: 14),
                    _bonusBanner(),
                    const SizedBox(height: 18),
                    _sectionTitle('Aktif İşim', trailing: 'Tümünü Gör'),
                    const SizedBox(height: 10),
                    _activeJob(),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Hızlı Erişim',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: navy),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _shortcuts(),
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

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF269FFF), Color(0xFF55CFFF)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Kurye', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 5, 6),
                decoration: BoxDecoration(
                  color: online ? const Color(0xFF16CE73) : const Color(0xFF90A1B4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(online ? Icons.check_circle_rounded : Icons.pause_circle_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(online ? 'Online' : 'Offline', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 7),
                    Switch(
                      value: online,
                      onChanged: (v) => setState(() => online = v),
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.white24,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const CircleAvatar(
                    radius: 21,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_rounded, color: blue, size: 28),
                  ),
                  Positioned(
                    right: -2,
                    top: -4,
                    child: Container(
                      width: 17,
                      height: 17,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: Colors.white, size: 27),
              SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('İstanbul', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('Şişli, Mecidiyeköy', style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 205,
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  top: 0,
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kazancın', style: TextStyle(color: Colors.white, fontSize: 35, height: .95, fontWeight: FontWeight.w900)),
                      Text('Senin Elinde!', style: TextStyle(color: lime, fontSize: 35, height: 1.0, fontWeight: FontWeight.w900)),
                      SizedBox(height: 12),
                      Text('İstediğin işi seç, kendi rotanı oluştur.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
                    ],
                  ),
                ),
                Positioned(
                  right: -12,
                  bottom: -14,
                  width: 190,
                  height: 190,
                  child: Image.asset('assets/images/kurye_header_hd.png', fit: BoxFit.contain),
                ),
                Positioned(
                  left: 0,
                  bottom: 6,
                  child: InkWell(
                    onTap: _openJobPool,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(backgroundColor: blue, radius: 18, child: Icon(Icons.format_list_bulleted_rounded, color: Colors.white, size: 20)),
                          SizedBox(width: 11),
                          Text('İş Havuzuna Git', style: TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900)),
                          SizedBox(width: 14),
                          Icon(Icons.arrow_forward_ios_rounded, color: blue, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 6))]),
        child: Row(
          children: [
            Expanded(child: _quick(Icons.format_list_bulleted_rounded, 'İş Havuzu', 'Uygun işleri gör\nve hemen al', blue, _openJobPool)),
            const SizedBox(width: 10),
            Expanded(child: _quick(Icons.location_on_rounded, 'Harita', 'Bölgedeki işleri\nharitada gör', green, () => setState(() => selectedTab = 2))),
          ],
        ),
      ),
    );
  }

  Widget _quick(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: .07), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            CircleAvatar(radius: 23, backgroundColor: color, child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: navy, fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: muted, fontSize: 10.5, height: 1.3)),
            ])),
            Icon(Icons.chevron_right_rounded, color: color),
          ]),
        ),
      );

  Widget _stats() {
    final items = [
      (Icons.account_balance_wallet_rounded, '₺1.250', 'Bugünkü Kazanç', green),
      (Icons.inventory_2_rounded, '8', 'Tamamlanan İş', const Color(0xFF7B61FF)),
      (Icons.schedule_rounded, '6.5 saat', 'Aktif Süre', const Color(0xFFFFA51D)),
      (Icons.route_rounded, '103 km', 'Toplam Mesafe', blue),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(
                child: Column(children: [
                  Icon(items[i].$1, color: items[i].$4, size: 21),
                  const SizedBox(height: 5),
                  Text(items[i].$2, style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(items[i].$3, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 9.5)),
                ]),
              ),
              if (i != items.length - 1) Container(width: 1, height: 46, color: const Color(0xFFE7EDF4)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bonusBanner() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF168CF5), Color(0xFF51C8FF)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Bu hafta', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('her 10 teslimata', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('+₺100 bonus!', style: TextStyle(color: lime, fontSize: 24, fontWeight: FontWeight.w900)),
              ]),
            ),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.savings_rounded, color: Colors.white, size: 50),
            ),
          ]),
        ),
      );

  Widget _sectionTitle(String title, {String? trailing}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: navy)),
          const Spacer(),
          if (trailing != null) Text(trailing, style: const TextStyle(color: blue, fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _activeJob() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 5))]),
          child: Row(children: [
            Container(width: 58, height: 58, decoration: const BoxDecoration(color: Color(0xFFFFF3E4), shape: BoxShape.circle), child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFE49C35), size: 30)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('#12458', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
                Text('Şişli → Kadıköy', style: TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 14, color: muted),
                  SizedBox(width: 2),
                  Text('2.4 km', style: TextStyle(color: muted, fontSize: 10)),
                  SizedBox(width: 8),
                  Icon(Icons.schedule_rounded, size: 14, color: muted),
                  SizedBox(width: 2),
                  Text('18 dk', style: TextStyle(color: muted, fontSize: 10)),
                ]),
              ]),
            ),
            Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE9FBF2), borderRadius: BorderRadius.circular(14)),
                child: const Text('Teslimatta', style: TextStyle(color: green, fontSize: 10.5, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 8),
              const CircleAvatar(radius: 17, backgroundColor: Color(0xFFEAF4FF), child: Icon(Icons.chevron_right_rounded, color: blue)),
            ]),
          ]),
        ),
      );

  Widget _shortcuts() {
    final items = [
      (Icons.account_balance_wallet_rounded, 'Kazançlarım', const Color(0xFF7A61FF)),
      (Icons.bar_chart_rounded, 'İstatistikler', green),
      (Icons.settings_rounded, 'Ayarlar', const Color(0xFFFFA52A)),
      (Icons.support_agent_rounded, 'Yardım', const Color(0xFFFF5A66)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: Container(
                height: 112,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CircleAvatar(radius: 24, backgroundColor: items[i].$3.withValues(alpha: .12), child: Icon(items[i].$1, color: items[i].$3)),
                  const SizedBox(height: 9),
                  Text(items[i].$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: navy, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
            if (i != items.length - 1) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }

  Widget _bottomNav() {
    final items = const [
      (Icons.home_rounded, 'Ana Sayfa'),
      (Icons.format_list_bulleted_rounded, 'İş Havuzu'),
      (Icons.map_outlined, 'Harita'),
      (Icons.person_outline_rounded, 'Profilim'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 7))]),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (i == 1) {
                    _openJobPool();
                  } else {
                    setState(() => selectedTab = i);
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(items[i].$1, color: selectedTab == i ? blue : const Color(0xFF8A96A4), size: 25),
                    const SizedBox(height: 3),
                    Text(items[i].$2, style: TextStyle(color: selectedTab == i ? blue : const Color(0xFF8A96A4), fontSize: 9.5, fontWeight: selectedTab == i ? FontWeight.w900 : FontWeight.w600)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
