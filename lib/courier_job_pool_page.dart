import 'package:flutter/material.dart';

class CourierJobPoolPage extends StatefulWidget {
  const CourierJobPoolPage({super.key});

  @override
  State<CourierJobPoolPage> createState() => _CourierJobPoolPageState();
}

class _CourierJobPoolPageState extends State<CourierJobPoolPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF7B8797);
  static const green = Color(0xFF20C875);
  static const bg = Color(0xFFF4F9FD);

  bool online = true;
  bool mapMode = false;
  int selectedFilter = 0;

  final jobs = const [
    _PoolJob(company: 'Burger Yiyelim', pickup: 'Mecidiyeköy Mah. Büyükdere Cd. No:12', dropoff: 'Şişli, Osmanbey Mah. 19 Mayıs Cd. No:8', pickupKm: '1.2 km', totalKm: '3.8 km', duration: '18 dk', package: '1 paket', packageType: 'Yemek', earning: 125, age: '12 dk önce', category: 'Restoran', icon: Icons.restaurant_rounded, accent: Color(0xFFFF922D), light: Color(0xFFFFF2E6)),
    _PoolJob(company: 'Migros', pickup: 'Fulya Mah. Abide-i Hürriyet Cd. No:154', dropoff: 'Şişli, Halide Edip Adıvar Mah. No:22', pickupKm: '0.8 km', totalKm: '4.1 km', duration: '22 dk', package: '3 paket', packageType: 'Market', earning: 98, age: '23 dk önce', category: 'Market', icon: Icons.shopping_cart_rounded, accent: Color(0xFF19C978), light: Color(0xFFE8FBF2)),
    _PoolJob(company: 'Trendyol Express', pickup: 'Kağıthane, Axis AVM', dropoff: 'Beşiktaş, Levent Mah. Nispetiye Cd.', pickupKm: '2.4 km', totalKm: '6.7 km', duration: '28 dk', package: '1 paket', packageType: 'Kargo', earning: 135, age: '31 dk önce', category: 'Kargo', icon: Icons.inventory_2_rounded, accent: Color(0xFF7657F6), light: Color(0xFFF1EDFF)),
    _PoolJob(company: 'Dürümcü Emmi', pickup: 'Gayrettepe Mah. Yıldız Posta Cd. No:7', dropoff: 'Zincirlikuyu Mah. Eski Büyükdere Cd. No:48', pickupKm: '1.9 km', totalKm: '5.2 km', duration: '24 dk', package: '2 paket', packageType: 'Yemek', earning: 110, age: '40 dk önce', category: 'Restoran', icon: Icons.restaurant_rounded, accent: Color(0xFFFF922D), light: Color(0xFFFFF2E6)),
    _PoolJob(company: 'CarrefourSA', pickup: 'Fulya Mah. Ortaklar Cd. No:18', dropoff: 'Beşiktaş, Dikilitaş Mah. No:41', pickupKm: '2.1 km', totalKm: '5.9 km', duration: '26 dk', package: '2 paket', packageType: 'Market', earning: 90, age: '46 dk önce', category: 'Market', icon: Icons.shopping_basket_rounded, accent: Color(0xFF19C978), light: Color(0xFFE8FBF2)),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleJobs = jobs.where((job) {
      if (selectedFilter == 1) return double.parse(job.pickupKm.split(' ').first) <= 1.5;
      if (selectedFilter == 2) return job.earning >= 120;
      if (selectedFilter == 3) return job.duration == '18 dk' || job.duration == '22 dk';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _filters(),
            Expanded(
              child: mapMode
                  ? _mapPlaceholder()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                      itemCount: visibleJobs.length,
                      itemBuilder: (_, index) => _jobCard(visibleJobs[index]),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF269FFF), Color(0xFF168CF5)]),
        ),
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white)),
                const SizedBox(width: 3),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('İş Havuzu', style: TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w900, height: 1)),
                    SizedBox(height: 5),
                    Text('Uygun işleri gör ve hemen al', style: TextStyle(color: Color(0xE8FFFFFF), fontSize: 13)),
                  ]),
                ),
                Container(
                  height: 48,
                  padding: const EdgeInsets.only(left: 13, right: 5),
                  decoration: BoxDecoration(color: online ? const Color(0xFF1ED36F) : const Color(0xFF8CA0B2), borderRadius: BorderRadius.circular(30)),
                  child: Row(children: [
                    Container(width: 18, height: 18, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(online ? 'Online' : 'Offline', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(width: 5),
                    Switch(value: online, onChanged: (v) => setState(() => online = v), activeThumbColor: Colors.white, activeTrackColor: Colors.white24, inactiveThumbColor: Colors.white, inactiveTrackColor: Colors.white24),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              height: 54,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), borderRadius: BorderRadius.circular(28)),
              child: Row(children: [
                Expanded(child: _modeButton(false, Icons.format_list_bulleted_rounded, 'Liste Görünümü')),
                Expanded(child: _modeButton(true, Icons.map_outlined, 'Harita Görünümü')),
              ]),
            ),
          ],
        ),
      );

  Widget _modeButton(bool value, IconData icon, String text) {
    final selected = mapMode == value;
    return InkWell(
      onTap: () => setState(() => mapMode = value),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected ? const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 3))] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? blue : const Color(0xFF3F5D7D), size: 24),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: selected ? navy : const Color(0xFF3F5D7D), fontWeight: FontWeight.w900, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _filters() {
    const labels = ['Tümü', 'Yakınımdakiler', 'Yüksek Kazançlı', 'Hızlı Teslimat'];
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final selected = selectedFilter == index;
          return InkWell(
            onTap: () => setState(() => selectedFilter = index),
            borderRadius: BorderRadius.circular(23),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: selected ? blue : Colors.white, borderRadius: BorderRadius.circular(23), boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 4))]),
              child: Text(labels[index], style: TextStyle(color: selected ? Colors.white : const Color(0xFF314A67), fontSize: 12.5, fontWeight: selected ? FontWeight.w900 : FontWeight.w700)),
            ),
          );
        },
      ),
    );
  }

  Widget _jobCard(_PoolJob job) => Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 6))]),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(color: job.accent, shape: BoxShape.circle), child: Icon(job.icon, color: Colors.white, size: 27)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(job.company, style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                _addressRow(const Color(0xFF168CF5), Icons.circle, job.pickup),
                const SizedBox(height: 5),
                _addressRow(const Color(0xFFFF334D), Icons.location_on_rounded, job.dropoff),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(14)), child: Text(job.age, style: const TextStyle(color: blue, fontSize: 10, fontWeight: FontWeight.w800))),
              const SizedBox(height: 4),
              Text('₺${job.earning}', style: const TextStyle(color: Color(0xFF05A65A), fontSize: 25, fontWeight: FontWeight.w900)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: job.light, borderRadius: BorderRadius.circular(12)), child: Text(job.category, style: TextStyle(color: job.accent, fontSize: 9.5, fontWeight: FontWeight.w800))),
            ]),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(color: const Color(0xFFF0F7FF), borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              _metric(Icons.location_on_rounded, job.pickupKm, 'Alımına'), _divider(),
              _metric(Icons.route_rounded, job.totalKm, 'Toplam'), _divider(),
              _metric(Icons.schedule_rounded, job.duration, 'Tahmini Süre'), _divider(),
              _metric(Icons.inventory_2_outlined, job.package, job.packageType),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _showDetails(job), icon: const Icon(Icons.description_outlined), label: const Text('Detaylar'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: const Color(0xFF284B73), side: BorderSide.none, backgroundColor: const Color(0xFFF0F7FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(onPressed: online ? () => _takeJob(job) : null, icon: const Icon(Icons.bolt_rounded), label: Text(online ? 'İşi Al' : 'Offline'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: blue, disabledBackgroundColor: const Color(0xFFB3C3D4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)))),
          ]),
        ]),
      );

  Widget _addressRow(Color color, IconData icon, String text) => Row(children: [
        Icon(icon, color: color, size: icon == Icons.circle ? 11 : 16),
        const SizedBox(width: 6),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF5E7085), fontSize: 11.5, fontWeight: FontWeight.w600))),
      ]);

  Widget _metric(IconData icon, String value, String label) => Expanded(
        child: Column(children: [
          Icon(icon, color: const Color(0xFF24578A), size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: navy, fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 1),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 8.5)),
        ]),
      );

  Widget _divider() => Container(width: 1, height: 39, color: const Color(0xFFDDE8F4));

  Widget _mapPlaceholder() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFE6EEF6), borderRadius: BorderRadius.circular(26)),
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(radius: 34, backgroundColor: Colors.white, child: Icon(Icons.map_rounded, color: blue, size: 34)),
              SizedBox(height: 12),
              Text('Harita Görünümü', style: TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w900)),
              SizedBox(height: 5),
              Text('Havuzdaki işleri harita üzerinde görüntüle.', style: TextStyle(color: muted, fontSize: 12)),
            ]),
          ),
        ),
      );

  void _showDetails(_PoolJob job) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(job.company, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: navy)),
          const SizedBox(height: 14),
          Text('Alım: ${job.pickup}', style: const TextStyle(color: navy, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Teslimat: ${job.dropoff}', style: const TextStyle(color: navy, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Text('Kazanç: ₺${job.earning}', style: const TextStyle(color: green, fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  void _takeJob(_PoolJob job) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const CircleAvatar(radius: 26, backgroundColor: Color(0xFFE8FBF2), child: Icon(Icons.check_rounded, color: green, size: 30)),
        title: const Text('İş Senin!', textAlign: TextAlign.center),
        content: Text('${job.company} işi sana ayrıldı.\nAlım noktasına doğru yola çıkabilirsin.', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [FilledButton(onPressed: () => Navigator.pop(context), style: FilledButton.styleFrom(backgroundColor: blue), child: const Text('Tamam'))],
      ),
    );
  }

  Widget _bottomNav() {
    final items = const [(Icons.home_rounded, 'Ana Sayfa'), (Icons.format_list_bulleted_rounded, 'İş Havuzu'), (Icons.map_outlined, 'Harita'), (Icons.person_outline_rounded, 'Profilim')];
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Color(0x17000000), blurRadius: 20, offset: Offset(0, 7))]),
        child: Row(children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (i == 0) Navigator.maybePop(context);
                  if (i == 2) setState(() => mapMode = true);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(items[i].$1, color: i == 1 ? blue : const Color(0xFF78899E), size: 26),
                    const SizedBox(height: 3),
                    Text(items[i].$2, style: TextStyle(color: i == 1 ? blue : const Color(0xFF78899E), fontSize: 9.5, fontWeight: i == 1 ? FontWeight.w900 : FontWeight.w700)),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _PoolJob {
  final String company;
  final String pickup;
  final String dropoff;
  final String pickupKm;
  final String totalKm;
  final String duration;
  final String package;
  final String packageType;
  final int earning;
  final String age;
  final String category;
  final IconData icon;
  final Color accent;
  final Color light;

  const _PoolJob({required this.company, required this.pickup, required this.dropoff, required this.pickupKm, required this.totalKm, required this.duration, required this.package, required this.packageType, required this.earning, required this.age, required this.category, required this.icon, required this.accent, required this.light});
}
