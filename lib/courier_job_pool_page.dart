import 'package:flutter/material.dart';

import 'courier_active_job_page.dart';
import 'data/app_data_service.dart';

class CourierJobPoolPage extends StatefulWidget {
  const CourierJobPoolPage({super.key});

  @override
  State<CourierJobPoolPage> createState() => _CourierJobPoolPageState();
}

class _CourierJobPoolPageState extends State<CourierJobPoolPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF7B8797);
  static const bg = Color(0xFFF4F9FD);

  bool online = false;
  bool statusLoading = true;
  bool mapMode = false;
  int selectedFilter = 0;
  String? claimingId;
  late Stream<List<Map<String, dynamic>>> poolStream;

  @override
  void initState() {
    super.initState();
    poolStream = AppDataService.instance.watchCourierPool();
    _loadCourierState();
  }

  Future<void> _loadCourierState() async {
    final data = AppDataService.instance;
    try {
      if (!data.isSignedIn) {
        if (mounted) setState(() { online = false; statusLoading = false; });
        return;
      }
      final row = await data.client
          .from('couriers')
          .select('is_online')
          .eq('user_id', data.userId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        online = row?['is_online'] == true;
        statusLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() { online = false; statusLoading = false; });
    }
  }

  Future<void> _setOnline(bool value) async {
    final previous = online;
    setState(() {
      online = value;
      statusLoading = true;
    });
    try {
      await AppDataService.instance.setCourierOnline(
        online: value,
        vehicleType: 'motorcycle',
      );
      if (!mounted) return;
      setState(() {
        statusLoading = false;
        poolStream = AppDataService.instance.watchCourierPool();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        online = previous;
        statusLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Durum güncellenemedi: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> rows) {
    return rows.where((row) {
      final price = (row['estimated_price'] as num?)?.toInt() ?? 0;
      final duration = (row['duration_min'] as num?)?.toInt() ?? 0;
      final distance = (row['distance_km'] as num?)?.toDouble() ?? 0;
      if (selectedFilter == 1) return distance > 0 && distance <= 5;
      if (selectedFilter == 2) return price >= 120;
      if (selectedFilter == 3) return duration > 0 && duration <= 25;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _filters(),
            Expanded(
              child: statusLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !online
                      ? _stateMessage(
                          Icons.power_settings_new_rounded,
                          'Çevrimdışısın',
                          'İş havuzundaki siparişleri görmek için Online ol.',
                        )
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: poolStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return _stateMessage(
                                Icons.cloud_off_rounded,
                                'İş havuzu yüklenemedi',
                                snapshot.error.toString(),
                              );
                            }
                            final jobs = _applyFilter(snapshot.data ?? const []);
                            if (jobs.isEmpty) {
                              return _stateMessage(
                                Icons.inbox_outlined,
                                'Şu an uygun iş yok',
                                'Müşteri yeni bir gönderi oluşturduğunda burada anında görünecek.',
                              );
                            }
                            if (mapMode) return _mapPlaceholder(jobs.length);
                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                              itemCount: jobs.length,
                              itemBuilder: (_, i) => _jobCard(jobs[i]),
                            );
                          },
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF269FFF), Color(0xFF168CF5)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('İş Havuzu', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
                      SizedBox(height: 3),
                      Text('Yeni müşteri gönderileri gerçek zamanlı gelir', style: TextStyle(color: Color(0xE8FFFFFF), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 10, right: 3),
                  decoration: BoxDecoration(
                    color: online ? const Color(0xFF1ED36F) : const Color(0xFF8CA0B2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Text(online ? 'Online' : 'Offline', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                      Switch(
                        value: online,
                        onChanged: statusLoading ? null : _setOnline,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.white24,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(26)),
              child: Row(
                children: [
                  Expanded(child: _mode(false, Icons.format_list_bulleted_rounded, 'Liste')),
                  Expanded(child: _mode(true, Icons.map_outlined, 'Harita')),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _mode(bool value, IconData icon, String label) {
    final selected = mapMode == value;
    return InkWell(
      onTap: online ? () => setState(() => mapMode = value) : null,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected ? const [BoxShadow(color: Color(0x12000000), blurRadius: 8)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? blue : muted, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? navy : muted, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    const labels = ['Tümü', 'Yakınımdakiler', 'Yüksek Kazanç', 'Hızlı'];
    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = selectedFilter == i;
          return InkWell(
            onTap: online ? () => setState(() => selectedFilter = i) : null,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? blue : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(labels[i], style: TextStyle(color: selected ? Colors.white : navy, fontSize: 11.5, fontWeight: FontWeight.w800)),
            ),
          );
        },
      ),
    );
  }

  Widget _jobCard(Map<String, dynamic> job) {
    final pickup = (job['pickup_address'] ?? '').toString();
    final dropoff = (job['dropoff_address'] ?? '').toString();
    final totalKm = (job['distance_km'] as num?)?.toDouble();
    final duration = (job['duration_min'] as num?)?.toInt();
    final earning = (job['estimated_price'] as num?)?.toInt() ?? 0;
    final packageType = (job['package_type'] ?? 'Evrak').toString();
    final code = (job['public_code'] ?? 'Gönderi').toString();
    final id = job['id'].toString();
    final busy = claimingId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x0E000000), blurRadius: 16, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 28, backgroundColor: Color(0xFFEAF4FF), child: Icon(Icons.description_outlined, color: blue, size: 28)),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code, style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    _addressRow(blue, pickup),
                    const SizedBox(height: 5),
                    _addressRow(const Color(0xFFFF334D), dropoff),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₺$earning', style: const TextStyle(color: Color(0xFF05A65A), fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(12)),
                    child: Text(packageType, style: const TextStyle(color: blue, fontSize: 9.5, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF0F7FF), borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                _metric(Icons.route_rounded, totalKm == null ? '—' : '${totalKm.toStringAsFixed(1)} km', 'Toplam'),
                _divider(),
                _metric(Icons.schedule_rounded, duration == null ? '—' : '$duration dk', 'Tahmini'),
                _divider(),
                _metric(Icons.payments_outlined, '₺$earning', 'Kazanç'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy || !online ? null : () => _takeJob(job),
            icon: busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.bolt_rounded),
            label: Text(busy ? 'Alınıyor...' : 'İşi Al'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takeJob(Map<String, dynamic> job) async {
    if (!online) return;
    final id = job['id'].toString();
    setState(() => claimingId = id);
    try {
      final claimed = await AppDataService.instance.claimShipment(id);
      if (!mounted) return;
      setState(() => claimingId = null);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CourierActiveJobPage(
            pickup: (claimed['pickup_address'] ?? '').toString(),
            dropoff: (claimed['dropoff_address'] ?? '').toString(),
            pickupKm: '—',
            totalKm: '${((claimed['distance_km'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} km',
            duration: '${(claimed['duration_min'] as num?)?.toInt() ?? 0} dk',
            earning: (claimed['estimated_price'] as num?)?.toInt() ?? 0,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => claimingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10213E),
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  Widget _addressRow(Color color, String text) => Row(
        children: [
          Icon(Icons.location_on_rounded, color: color, size: 15),
          const SizedBox(width: 5),
          Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF5E7085), fontSize: 12))),
        ],
      );

  Widget _metric(IconData icon, String value, String label) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF24578A), size: 19),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: navy, fontSize: 12.5, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: muted, fontSize: 8.5)),
          ],
        ),
      );

  Widget _divider() => Container(width: 1, height: 38, color: const Color(0xFFDDE8F4));

  Widget _mapPlaceholder(int count) => _stateMessage(
        Icons.map_rounded,
        'Harita görünümü',
        '$count uygun iş var. Gerçek harita pinleri sonraki adımda bağlanacak.',
      );

  Widget _stateMessage(IconData icon, String title, String subtitle) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 34, backgroundColor: Colors.white, child: Icon(icon, color: blue, size: 34)),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      );

  Widget _bottomNav() => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Row(
            children: [
              _nav(Icons.home_rounded, 'Ana Sayfa', false, () => Navigator.maybePop(context)),
              _nav(Icons.format_list_bulleted_rounded, 'İş Havuzu', true, () => setState(() => mapMode = false)),
              _nav(Icons.map_outlined, 'Harita', mapMode, () => online ? setState(() => mapMode = true) : null),
              _nav(Icons.person_outline_rounded, 'Profilim', false, () => Navigator.maybePop(context)),
            ],
          ),
        ),
      );

  Widget _nav(IconData icon, String label, bool selected, VoidCallback tap) => Expanded(
        child: InkWell(
          onTap: tap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? blue : muted, size: 23),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: selected ? blue : muted, fontSize: 9.5, fontWeight: selected ? FontWeight.w900 : FontWeight.w600)),
            ],
          ),
        ),
      );
}
