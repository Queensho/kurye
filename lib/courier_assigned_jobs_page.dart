import 'package:flutter/material.dart';

import 'courier_active_job_page.dart';
import 'courier_bottom_nav.dart';
import 'courier_earnings_page.dart';
import 'courier_home_page.dart';
import 'courier_profile_page.dart';
import 'data/app_data_service.dart';

class CourierAssignedJobsPage extends StatelessWidget {
  const CourierAssignedJobsPage({super.key});

  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF171052);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);

  void _replace(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  void _nav(BuildContext context, int index) {
    switch (index) {
      case 0:
        _replace(context, const CourierHomePage());
        break;
      case 2:
        _replace(context, const CourierEarningsPage());
        break;
      case 3:
        _replace(context, const CourierProfilePage());
        break;
    }
  }

  void _openJob(BuildContext context, Map<String, dynamic> item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourierActiveJobPage(
      pickup: (item['pickup_address'] ?? '').toString(),
      dropoff: (item['dropoff_address'] ?? '').toString(),
      pickupKm: '0 km',
      totalKm: '${item['distance_km'] ?? 0} km',
      duration: '${item['duration_min'] ?? 0} dk',
      earning: ((item['courier_earning'] ?? item['estimated_price'] ?? 0) as num?)?.round() ?? 0,
    )));
  }

  @override
  Widget build(BuildContext context) {
    final data = AppDataService.instance;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, constraints) {
          final s = (constraints.maxWidth / 390).clamp(.92, 1.08).toDouble();
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(18 * s, 18 * s, 18 * s, 14 * s),
                color: Colors.white,
                child: Text('Atananlar', style: TextStyle(color: navy, fontSize: 23 * s, fontWeight: FontWeight.w900)),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: data.client
                      .from('shipments')
                      .stream(primaryKey: ['id'])
                      .eq('courier_id', data.userId)
                      .order('created_at', ascending: false)
                      .map((rows) => List<Map<String, dynamic>>.from(rows.where((e) => !['delivered', 'cancelled'].contains((e['status'] ?? '').toString())))),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: orange));
                    }
                    final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                    if (rows.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(28 * s),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.work_outline_rounded, color: muted, size: 42 * s),
                            SizedBox(height: 10 * s),
                            Text('Atanmış aktif işin yok', style: TextStyle(color: navy, fontSize: 14 * s, fontWeight: FontWeight.w900)),
                            SizedBox(height: 4 * s),
                            Text('Havuzdan aldığın işler burada görünür.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 10 * s)),
                          ]),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(14 * s, 14 * s, 14 * s, 18 * s),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => SizedBox(height: 9 * s),
                      itemBuilder: (_, i) {
                        final item = rows[i];
                        final code = (item['public_code'] ?? 'Gönderi').toString();
                        final pickup = (item['pickup_address'] ?? '').toString();
                        final dropoff = (item['dropoff_address'] ?? '').toString();
                        final status = (item['status'] ?? '').toString();
                        return InkWell(
                          onTap: () => _openJob(context, item),
                          borderRadius: BorderRadius.circular(18 * s),
                          child: Container(
                            padding: EdgeInsets.all(13 * s),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s), boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 12, offset: Offset(0, 4))]),
                            child: Row(children: [
                              Container(width: 42 * s, height: 42 * s, decoration: BoxDecoration(color: const Color(0xFFFFEEE7), borderRadius: BorderRadius.circular(12 * s)), child: Icon(Icons.inventory_2_outlined, color: orange, size: 22 * s)),
                              SizedBox(width: 11 * s),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(code.startsWith('#') ? code : '#$code', style: TextStyle(color: navy, fontSize: 12 * s, fontWeight: FontWeight.w900)),
                                SizedBox(height: 3 * s),
                                Text(pickup, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 9.5 * s)),
                                Text(dropoff, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 9.5 * s)),
                              ])),
                              SizedBox(width: 8 * s),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('₺${((item['courier_earning'] ?? item['estimated_price'] ?? 0) as num?)?.round() ?? 0}', style: TextStyle(color: navy, fontSize: 14 * s, fontWeight: FontWeight.w900)),
                                SizedBox(height: 4 * s),
                                Text(status, style: TextStyle(color: orange, fontSize: 8.5 * s, fontWeight: FontWeight.w700)),
                              ]),
                            ]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              CourierBottomNav(currentIndex: 1, onTap: (i) => _nav(context, i)),
            ],
          );
        }),
      ),
    );
  }
}
