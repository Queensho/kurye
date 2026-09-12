import 'package:flutter/material.dart';

import 'courier_active_job_realtime_page.dart';
import 'courier_assigned_jobs_page.dart';
import 'courier_bottom_nav.dart';
import 'courier_earnings_page.dart';
import 'courier_profile_page.dart';
import 'courier_pool_job_detail_page.dart';
import 'data/app_data_service.dart';

class CourierHomePage extends StatefulWidget {
  const CourierHomePage({super.key});

  @override
  State<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends State<CourierHomePage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF171052);
  static const purple = Color(0xFF261168);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);
  static const green = Color(0xFF16B868);

  final data = AppDataService.instance;
  bool online = false;
  bool statusBusy = true;
  Map<String, dynamic> profile = {};
  Map<String, dynamic> earnings = {};
  List<Map<String, dynamic>> courierShipments = [];
  late final Stream<List<Map<String, dynamic>>> poolStream;
  final Set<String> hiddenPoolShipmentIds = <String>{};

  @override
  void initState() {
    super.initState();
    poolStream = data.watchCourierPool();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      if (!data.isSignedIn) {
        if (mounted)
          setState(() {
            online = false;
            statusBusy = false;
          });
        return;
      }
      final courier = await data.client
          .from('couriers')
          .select('is_online,active_shipment_id')
          .eq('user_id', data.userId)
          .maybeSingle();
      final p = await data.getProfile();
      Map<String, dynamic> e = {};
      try {
        e = await data.getCourierEarningsSummary();
      } catch (_) {}
      final rows = await data.client
          .from('shipments')
          .select()
          .eq('courier_id', data.userId)
          .order('created_at', ascending: false)
          .limit(100);
      if (!mounted) return;
      setState(() {
        online = courier?['is_online'] == true;
        profile = p;
        earnings = e;
        courierShipments = List<Map<String, dynamic>>.from(rows);
        statusBusy = false;
      });
    } catch (_) {
      if (mounted) setState(() => statusBusy = false);
    }
  }

  Future<void> _setOnline(bool value) async {
    if (statusBusy) return;
    final previous = online;
    setState(() {
      online = value;
      statusBusy = true;
    });
    try {
      await data.setCourierOnline(online: value, vehicleType: 'motorcycle');
      if (mounted) setState(() => statusBusy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        online = previous;
        statusBusy = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Durum güncellenemedi: $e')));
    }
  }

  String _money(dynamic value) {
    if (value is num) {
      final d = value.toDouble();
      return d == d.roundToDouble()
          ? '₺${d.toInt()}'
          : '₺${d.toStringAsFixed(2)}';
    }
    return '₺0';
  }

  String _shortAddress(dynamic raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return 'Adres belirtilmedi';
    final parts = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.take(2).join(', ');
  }

  String _typeLabel(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'document':
        return 'Evrak';
      case 'food':
        return 'Market';
      case 'gift':
        return 'Hediye';
      default:
        return 'Paket';
    }
  }

  IconData _typeIcon(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'document':
        return Icons.description_outlined;
      case 'food':
        return Icons.shopping_bag_outlined;
      case 'gift':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Future<void> _claim(Map<String, dynamic> item) async {
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşi almak için Online olmalısın.')),
      );
      return;
    }
    final shipmentId = item['id'].toString();
    if (mounted) {
      setState(() => hiddenPoolShipmentIds.add(shipmentId));
    }
    try {
      final claimed = await data.claimShipment(shipmentId);
      if (!mounted) return;
      await _loadDashboard();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CourierActiveJobRealtimePage(
            shipmentId: claimed['id'].toString(),
            pickup: (claimed['pickup_address'] ?? item['pickup_address'] ?? '').toString(),
            dropoff: (claimed['dropoff_address'] ?? item['dropoff_address'] ?? '').toString(),
            earning: ((claimed['courier_earning'] ?? claimed['estimated_price'] ?? item['courier_earning'] ?? item['estimated_price'] ?? 0) as num).round(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => hiddenPoolShipmentIds.remove(shipmentId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    }
  }

  void _openAssigned() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CourierAssignedJobsPage()));
  }

  void _navigateBottom(int index) {
    if (index == 0) return;
    final page = switch (index) {
      1 => const CourierAssignedJobsPage(),
      2 => const CourierEarningsPage(),
      3 => const CourierProfilePage(),
      _ => const CourierHomePage(),
    };
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final name = (profile['full_name'] ?? 'Kurye').toString().trim();
    final avatar = (profile['avatar_url'] ?? '').toString().trim();
    final today = DateTime.now();
    final todayJobs = courierShipments.where((e) {
      final d = DateTime.tryParse((e['created_at'] ?? '').toString())
          ?.toLocal();
      return d != null &&
          d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).length;
    final completed = courierShipments
        .where((e) => e['status'] == 'delivered')
        .length;
    final activeCount = courierShipments
        .where(
          (e) => ![
            'delivered',
            'cancelled',
          ].contains((e['status'] ?? '').toString()),
        )
        .length;
    final todayEarning =
        earnings['today_earnings'] ?? earnings['available_balance'] ?? 0;
    final performance = completed == 0 ? 0 : 100;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = (constraints.maxWidth / 390).clamp(.92, 1.08).toDouble();
            return Column(
              children: [
                _header(name, avatar, todayJobs, todayEarning, performance, s),
                _topTabs(activeCount, s),
                _filters(s),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: poolStream,
                    builder: (context, snapshot) {
                      final rawJobs =
                          snapshot.data ?? const <Map<String, dynamic>>[];
                      final jobs = online
                          ? rawJobs
                              .where(
                                (job) => !hiddenPoolShipmentIds.contains(
                                  (job['id'] ?? '').toString(),
                                ),
                              )
                              .toList(growable: false)
                          : const <Map<String, dynamic>>[];
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          online)
                        return const Center(
                          child: CircularProgressIndicator(color: orange),
                        );
                      if (!online) return _offlineState(s);
                      if (jobs.isEmpty) return _emptyPool(s);
                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          12 * s,
                          4 * s,
                          12 * s,
                          90 * s,
                        ),
                        itemCount: jobs.length,
                        itemBuilder: (_, i) => Padding(
                          padding: EdgeInsets.only(bottom: 8 * s),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              final claimed = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => CourierPoolJobDetailPage(shipment: jobs[i]),
                                ),
                              );
                              if (claimed == true) await _loadDashboard();
                            },
                            child: _jobCard(jobs[i], i, s),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _bottomNav(s),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(
    String name,
    String avatar,
    int todayJobs,
    dynamic todayEarning,
    int performance,
    double s,
  ) => Container(
    height: 137 * s,
    padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 14 * s, 9 * s),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2B1776), Color(0xFF171052)],
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20 * s),
        bottomRight: Radius.circular(20 * s),
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 48 * s,
              height: 48 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white12,
                image: avatar.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(avatar),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatar.isEmpty
                  ? Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28 * s,
                    )
                  : null,
            ),
            SizedBox(width: 10 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Kurye' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17 * s,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  Row(
                    children: [
                      Container(
                        width: 8 * s,
                        height: 8 * s,
                        decoration: BoxDecoration(
                          color: online ? green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5 * s),
                      Text(
                        online ? 'Online • Hazır' : 'Offline',
                        style: TextStyle(
                          color: const Color(0xFFDAD4F2),
                          fontSize: 10.5 * s,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 39 * s,
              height: 39 * s,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 23 * s,
              ),
            ),
            SizedBox(width: 10 * s),
            Container(
              height: 38 * s,
              padding: EdgeInsets.only(left: 12 * s, right: 4 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22 * s),
              ),
              child: Row(
                children: [
                  Text(
                    online ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: online ? green : muted,
                      fontSize: 11 * s,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Transform.scale(
                    scale: .78,
                    child: Switch(
                      value: online,
                      onChanged: statusBusy ? null : _setOnline,
                      activeThumbColor: Colors.white,
                      activeTrackColor: green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 9 * s),
        Row(
          children: [
            Expanded(child: _headerStat('Bugün', '$todayJobs', 'Paket', s)),
            SizedBox(width: 7 * s),
            Expanded(child: _headerStat('Kazanç', _money(todayEarning), '', s)),
            SizedBox(width: 7 * s),
            Expanded(child: _headerStat('Performans', '%$performance', '', s)),
            SizedBox(width: 7 * s),
            Expanded(
              child: Container(
                height: 49 * s,
                padding: EdgeInsets.symmetric(horizontal: 8 * s),
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: .20),
                  borderRadius: BorderRadius.circular(13 * s),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: const Color(0xFFFFC85E),
                      size: 20 * s,
                    ),
                    SizedBox(width: 5 * s),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daha fazla kazan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.8 * s,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Avantajları gör',
                            style: TextStyle(
                              color: const Color(0xFFE2DDF1),
                              fontSize: 7.5 * s,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _headerStat(String title, String value, String suffix, double s) =>
      Container(
        height: 49 * s,
        padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 6 * s),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(13 * s),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFFE0DCF0),
                fontSize: 8.5 * s,
              ),
            ),
            SizedBox(height: 2 * s),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * s,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (suffix.isNotEmpty) ...[
                  SizedBox(width: 3 * s),
                  Text(
                    suffix,
                    style: TextStyle(
                      color: const Color(0xFFBBB5CF),
                      fontSize: 7.5 * s,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );

  Widget _topTabs(int activeCount, double s) => Container(
    height: 54 * s,
    color: Colors.white,
    child: Row(
      children: [
        _topTab(Icons.layers_rounded, 'Havuz', true, 0, s, () {}),
        _topTab(
          Icons.work_outline_rounded,
          'Atananlar',
          false,
          activeCount,
          s,
          _openAssigned,
        ),
        _topTab(
          Icons.play_arrow_outlined,
          'Devam Eden',
          false,
          0,
          s,
          _openAssigned,
        ),
        _topTab(
          Icons.check_circle_outline_rounded,
          'Tamamlanan',
          false,
          0,
          s,
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CourierEarningsPage()),
          ),
        ),
      ],
    ),
  );

  Widget _topTab(
    IconData icon,
    String label,
    bool active,
    int badge,
    double s,
    VoidCallback onTap,
  ) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: active ? orange : navy.withValues(alpha: .68),
                size: 21 * s,
              ),
              if (badge > 0)
                Positioned(
                  right: -9 * s,
                  top: -6 * s,
                  child: Container(
                    constraints: BoxConstraints(minWidth: 15 * s),
                    height: 15 * s,
                    padding: EdgeInsets.symmetric(horizontal: 3 * s),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: orange,
                      borderRadius: BorderRadius.circular(8 * s),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7 * s,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 3 * s),
          Text(
            label,
            style: TextStyle(
              color: active ? orange : muted,
              fontSize: 8.5 * s,
              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          SizedBox(height: 5 * s),
          Container(
            height: 2 * s,
            width: 50 * s,
            color: active ? orange : Colors.transparent,
          ),
        ],
      ),
    ),
  );

  Widget _filters(double s) => Padding(
    padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 8 * s),
    child: Row(
      children: [
        _filter(Icons.navigation_outlined, 'Konumum', s),
        SizedBox(width: 7 * s),
        _filter(Icons.grid_view_rounded, 'Tümü', s),
        const Spacer(),
        _filter(Icons.swap_vert_rounded, 'Yakınlık', s),
      ],
    ),
  );

  Widget _filter(IconData icon, String label, double s) => Container(
    height: 35 * s,
    padding: EdgeInsets.symmetric(horizontal: 11 * s),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11 * s),
      border: Border.all(color: const Color(0xFFE9E7F0)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: navy, size: 16 * s),
        SizedBox(width: 6 * s),
        Text(
          label,
          style: TextStyle(
            color: navy,
            fontSize: 9 * s,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 7 * s),
        Icon(Icons.keyboard_arrow_down_rounded, color: navy, size: 16 * s),
      ],
    ),
  );

  Widget _jobCard(Map<String, dynamic> item, int index, double s) {
    final type = _typeLabel(item['package_type']);
    final weight = (item['weight_label'] ?? '').toString();
    final size = (item['size_label'] ?? '').toString();
    final distance = item['distance_km'];
    final duration = item['duration_min'];
    final price = item['courier_earning'] ?? item['estimated_price'];
    final code = (item['public_code'] ?? '').toString();
    final pickup = _shortAddress(item['pickup_address']);
    final dropoff = _shortAddress(item['dropoff_address']);
    final tag = index % 4 == 1
        ? 'Avantajlı'
        : index % 4 == 2
        ? 'Yakın'
        : index % 4 == 3
        ? 'Uzun Mesafe'
        : 'Yakın';
    final tagColor = tag == 'Avantajlı'
        ? purple
        : tag == 'Uzun Mesafe'
        ? const Color(0xFFE65353)
        : orange;

    return Container(
      height: 103 * s,
      padding: EdgeInsets.fromLTRB(10 * s, 9 * s, 9 * s, 9 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15 * s),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45 * s,
            height: 45 * s,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1FF),
              borderRadius: BorderRadius.circular(12 * s),
            ),
            child: Icon(
              _typeIcon(item['package_type']),
              color: index == 0 ? orange : navy,
              size: 24 * s,
            ),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code.isEmpty ? 'Gönderi' : '#$code',
                  style: TextStyle(
                    color: navy,
                    fontSize: 11 * s,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2 * s),
                Text(
                  '$type${weight.isEmpty ? '' : ' • $weight'}${size.isEmpty ? '' : ' • $size'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: 8.8 * s),
                ),
                SizedBox(height: 5 * s),
                Row(
                  children: [
                    Icon(Icons.circle, color: orange, size: 8 * s),
                    SizedBox(width: 6 * s),
                    Expanded(
                      child: Text(
                        pickup,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 8.7 * s),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3 * s),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: navy, size: 11 * s),
                    SizedBox(width: 4 * s),
                    Expanded(
                      child: Text(
                        dropoff,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 8.7 * s),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.route_rounded, color: muted, size: 13 * s),
                    SizedBox(width: 3 * s),
                    Text(
                      distance == null ? '— km' : '$distance km',
                      style: TextStyle(color: muted, fontSize: 8.5 * s),
                    ),
                    SizedBox(width: 12 * s),
                    Icon(Icons.schedule_rounded, color: muted, size: 13 * s),
                    SizedBox(width: 3 * s),
                    Text(
                      duration == null ? '— dk' : '$duration dk',
                      style: TextStyle(color: muted, fontSize: 8.5 * s),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * s),
          SizedBox(
            width: 78 * s,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * s,
                    vertical: 4 * s,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(10 * s),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 7.8 * s,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _money(price),
                  style: TextStyle(
                    color: navy,
                    fontSize: 17 * s,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6 * s),
                SizedBox(
                  width: 75 * s,
                  height: 29 * s,
                  child: FilledButton(
                    onPressed: () => _claim(item),
                    style: FilledButton.styleFrom(
                      backgroundColor: orange,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * s),
                      ),
                    ),
                    child: Text(
                      'Al',
                      style: TextStyle(
                        fontSize: 10 * s,
                        fontWeight: FontWeight.w900,
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

  Widget _offlineState(double s) => LayoutBuilder(
    builder: (context, constraints) => SizedBox.expand(
      child: Image.asset(
        'assets/images/Ofline.png',
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.high,
      ),
    ),
  );

  Widget _emptyPool(double s) => LayoutBuilder(
    builder: (context, constraints) => SizedBox.expand(
      child: Image.asset(
        'assets/images/Bos.png',
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.high,
      ),
    ),
  );

  Widget _bottomNav(double s) =>
      CourierBottomNav(currentIndex: 0, onTap: _navigateBottom);
}
