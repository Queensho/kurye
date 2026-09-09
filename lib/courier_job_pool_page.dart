import 'package:flutter/material.dart';

class CourierJobPoolPage extends StatefulWidget {
  const CourierJobPoolPage({super.key});

  @override
  State<CourierJobPoolPage> createState() => _CourierJobPoolPageState();
}

class _CourierJobPoolPageState extends State<CourierJobPoolPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const green = Color(0xFF20D985);
  static const muted = Color(0xFF7B8797);
  static const bg = Color(0xFFF4F9FD);

  bool online = true;
  int filter = 0;
  bool mapMode = false;
  String? takingJob;

  final jobs = const [
    _PoolJob(
      id: '#12521',
      pickup: 'Mecidiyeköy, Şişli',
      dropoff: 'Caddebostan, Kadıköy',
      pickupKm: 1.2,
      deliveryKm: 9.6,
      duration: 32,
      earning: 245,
      type: 'Paket',
      weight: '0–3 kg',
      vehicle: 'Motosiklet',
      payment: 'Online',
      hot: true,
    ),
    _PoolJob(
      id: '#12520',
      pickup: 'Gayrettepe, Beşiktaş',
      dropoff: 'Maslak, Sarıyer',
      pickupKm: 2.4,
      deliveryKm: 7.8,
      duration: 27,
      earning: 190,
      type: 'Belge',
      weight: 'Küçük',
      vehicle: 'Motosiklet',
      payment: 'Nakit',
    ),
    _PoolJob(
      id: '#12518',
      pickup: 'Nişantaşı, Şişli',
      dropoff: 'Ataköy, Bakırköy',
      pickupKm: 3.1,
      deliveryKm: 15.4,
      duration: 44,
      earning: 325,
      type: 'Paket',
      weight: '3–5 kg',
      vehicle: 'Motosiklet',
      payment: 'Online',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = filter == 0
        ? jobs
        : filter == 1
            ? jobs.where((j) => j.pickupKm <= 2.5).toList()
            : jobs.where((j) => j.earning >= 220).toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _statusStrip(),
            _filters(),
            Expanded(
              child: mapMode ? _mapPlaceholder(visible.length) : _jobList(visible),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFFEAF4FF), foregroundColor: blue),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('İş Havuzu', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: navy)),
                      Text('Uygun işi seç ve hemen al', style: TextStyle(fontSize: 11.5, color: muted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
                  decoration: BoxDecoration(
                    color: online ? const Color(0xFFE8FBF2) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: online ? green : muted, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(online ? 'Online' : 'Offline', style: TextStyle(color: online ? const Color(0xFF14995E) : muted, fontSize: 11, fontWeight: FontWeight.w900)),
                    Switch(
                      value: online,
                      onChanged: (v) => setState(() => online = v),
                      activeThumbColor: green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFF0F5FA), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Expanded(child: _modeButton(false, Icons.view_agenda_rounded, 'Liste')),
                Expanded(child: _modeButton(true, Icons.map_rounded, 'Harita')),
              ]),
            ),
          ],
        ),
      );

  Widget _modeButton(bool value, IconData icon, String text) {
    final selected = mapMode == value;
    return InkWell(
      onTap: () => setState(() => mapMode = value),
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: selected ? const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3))] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 19, color: selected ? blue : muted),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: selected ? navy : muted, fontWeight: FontWeight.w800, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _statusStrip() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF168CF5), Color(0xFF49B7FF)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(children: [
            CircleAvatar(backgroundColor: Color(0x33FFFFFF), child: Icon(Icons.bolt_rounded, color: Colors.white)),
            SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('3 yeni iş havuzda', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
              SizedBox(height: 2),
              Text('İlk alan kurye işi üstlenir.', style: TextStyle(color: Color(0xE8FFFFFF), fontSize: 10.5)),
            ])),
            Text('Canlı', style: TextStyle(color: Color(0xFFD7FF45), fontWeight: FontWeight.w900)),
          ]),
        ),
      );

  Widget _filters() {
    const names = ['Tümü', 'Yakınımdakiler', 'Yüksek Kazanç'];
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ChoiceChip(
          label: Text(names[i]),
          selected: filter == i,
          onSelected: (_) => setState(() => filter = i),
          selectedColor: const Color(0xFFE5F3FF),
          side: BorderSide(color: filter == i ? blue : const Color(0xFFE1E8F0)),
          labelStyle: TextStyle(color: filter == i ? blue : muted, fontSize: 11, fontWeight: FontWeight.w800),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _jobList(List<_PoolJob> visible) => RefreshIndicator(
        onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 500)),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: visible.length,
          itemBuilder: (_, i) => _jobCard(visible[i]),
        ),
      );

  Widget _jobCard(_PoolJob job) {
    final busy = takingJob == job.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: job.hot ? Border.all(color: const Color(0xFFFFC84B), width: 1.2) : null,
        boxShadow: const [BoxShadow(color: Color(0x0E000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (job.hot)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFFFF4D9), borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFFFA300)), SizedBox(width: 3), Text('Popüler', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFFB86E00)))]),
            ),
          if (job.hot) const SizedBox(width: 7),
          Text(job.id, style: const TextStyle(color: muted, fontSize: 10.5, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('₺${job.earning}', style: const TextStyle(color: blue, fontSize: 24, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 14),
        _routeLine(blue, Icons.trip_origin_rounded, 'Alım', job.pickup, '${job.pickupKm.toStringAsFixed(1)} km uzakta'),
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Container(width: 2, height: 18, color: const Color(0xFFD9E7F4)),
        ),
        _routeLine(green, Icons.location_on_rounded, 'Teslimat', job.dropoff, '${job.deliveryKm.toStringAsFixed(1)} km rota'),
        const SizedBox(height: 14),
        Wrap(spacing: 7, runSpacing: 7, children: [
          _tag(Icons.schedule_rounded, '${job.duration} dk'),
          _tag(Icons.inventory_2_outlined, '${job.type} • ${job.weight}'),
          _tag(Icons.two_wheeler_rounded, job.vehicle),
          _tag(job.payment == 'Nakit' ? Icons.payments_rounded : Icons.credit_card_rounded, job.payment),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showDetails(job),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), side: const BorderSide(color: Color(0xFFCFE5FA)), foregroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Detaylar', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: online && !busy ? () => _takeJob(job) : null,
              icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Icon(Icons.flash_on_rounded),
              label: Text(online ? (busy ? 'Alınıyor...' : 'İşi Al') : 'Önce Online Ol'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _routeLine(Color color, IconData icon, String label, String address, String meta) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: .11), shape: BoxShape.circle), child: Icon(icon, size: 18, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 9.5, color: muted, fontWeight: FontWeight.w700)),
            Text(address, style: const TextStyle(fontSize: 13.5, color: navy, fontWeight: FontWeight.w900)),
          ])),
          Text(meta, style: const TextStyle(fontSize: 9.5, color: muted, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _tag(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFFF3F7FB), borderRadius: BorderRadius.circular(11)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: muted), const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 9.5, color: navy, fontWeight: FontWeight.w700))]),
      );

  Widget _mapPlaceholder(int count) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F1F7),
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: NetworkImage('https://basemaps.cartocdn.com/rastertiles/voyager/13/4845/3080.png'),
              fit: BoxFit.cover,
              opacity: .55,
            ),
          ),
          child: Stack(children: [
            Positioned(top: 18, left: 18, child: _mapBubble('$count iş', Icons.inventory_2_rounded, blue)),
            const Positioned(top: 155, left: 72, child: _MapPin(text: '₺245')),
            const Positioned(top: 265, right: 74, child: _MapPin(text: '₺190')),
            const Positioned(bottom: 135, left: 138, child: _MapPin(text: '₺325')),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16)]),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, color: blue),
                  SizedBox(width: 9),
                  Expanded(child: Text('Haritadaki fiyat balonuna dokunarak işi görüntüleyebilirsin.', style: TextStyle(color: navy, fontSize: 11, fontWeight: FontWeight.w700))),
                ]),
              ),
            ),
          ]),
        ),
      );

  Widget _mapBubble(String text, IconData icon, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 10)]),
        child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 6), Text(text, style: const TextStyle(color: navy, fontWeight: FontWeight.w900))]),
      );

  Future<void> _takeJob(_PoolJob job) async {
    setState(() => takingJob = job.id);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => takingJob = null);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE7FAF1), child: Icon(Icons.check_rounded, color: green, size: 36)),
          const SizedBox(height: 12),
          const Text('İş Senin!', style: TextStyle(color: navy, fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('${job.id} • ${job.pickup} → ${job.dropoff}', textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Alım Noktasına Git'))),
        ]),
      ),
    );
  }

  void _showDetails(_PoolJob job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('${job.id} İş Detayı', style: const TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w900))), Text('₺${job.earning}', style: const TextStyle(color: blue, fontSize: 22, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 14),
          _routeLine(blue, Icons.trip_origin_rounded, 'Alım noktası', job.pickup, '${job.pickupKm.toStringAsFixed(1)} km'),
          const SizedBox(height: 12),
          _routeLine(green, Icons.location_on_rounded, 'Teslimat noktası', job.dropoff, '${job.deliveryKm.toStringAsFixed(1)} km'),
          const SizedBox(height: 16),
          const Text('İşi aldığında diğer kuryelerin havuzundan anında kaldırılır.', style: TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: online ? () { Navigator.pop(context); _takeJob(job); } : null, icon: const Icon(Icons.flash_on_rounded), label: const Text('İşi Al'))),
        ]),
      ),
    );
  }

  Widget _bottomBar() => Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 7))]),
        child: Row(children: [
          _navItem(Icons.home_rounded, 'Ana Sayfa', false, () => Navigator.maybePop(context)),
          _navItem(Icons.format_list_bulleted_rounded, 'İş Havuzu', true, () {}),
          _navItem(Icons.map_outlined, 'Harita', false, () => setState(() => mapMode = true)),
          _navItem(Icons.person_outline_rounded, 'Profilim', false, () {}),
        ]),
      );

  Widget _navItem(IconData icon, String label, bool selected, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: selected ? blue : const Color(0xFF8A96A4), size: 25),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: selected ? blue : const Color(0xFF8A96A4), fontSize: 9.5, fontWeight: selected ? FontWeight.w900 : FontWeight.w600)),
            ]),
          ),
        ),
      );
}

class _PoolJob {
  const _PoolJob({
    required this.id,
    required this.pickup,
    required this.dropoff,
    required this.pickupKm,
    required this.deliveryKm,
    required this.duration,
    required this.earning,
    required this.type,
    required this.weight,
    required this.vehicle,
    required this.payment,
    this.hot = false,
  });

  final String id;
  final String pickup;
  final String dropoff;
  final double pickupKm;
  final double deliveryKm;
  final int duration;
  final int earning;
  final String type;
  final String weight;
  final String vehicle;
  final String payment;
  final bool hot;
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFF168CF5), borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x33168CF5), blurRadius: 12)]),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      );
}
