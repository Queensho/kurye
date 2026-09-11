from pathlib import Path

p = Path('lib/courier_home_page.dart')
s = p.read_text()
s = s.replace("import 'courier_active_job_page.dart';", "import 'courier_active_job_realtime_page.dart';")
old = """      await data.claimShipment(item['id'].toString());
      if (!mounted) return;
      await _loadDashboard();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CourierActiveJobPage(
            pickup: (item['pickup_address'] ?? '').toString(),
            dropoff: (item['dropoff_address'] ?? '').toString(),
            pickupKm: '0 km',
            totalKm: '${item['distance_km'] ?? 0} km',
            duration: '${item['duration_min'] ?? 0} dk',
            earning:
                ((item['courier_earning'] ?? item['estimated_price'] ?? 0)
                        as num)
                    .round(),
          ),
        ),
      );"""
new = """      final claimed = await data.claimShipment(item['id'].toString());
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
      );"""
if old not in s:
    raise SystemExit('courier_home claim block not found')
p.write_text(s.replace(old, new))

p = Path('lib/courier_assigned_jobs_page.dart')
s = p.read_text().replace("import 'courier_active_job_page.dart';", "import 'courier_active_job_realtime_page.dart';")
old = """    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourierActiveJobPage(
      shipmentId: item['id']?.toString(),
      pickup: (item['pickup_address'] ?? '').toString(),
      dropoff: (item['dropoff_address'] ?? '').toString(),
      pickupKm: '0 km',
      totalKm: '${item['distance_km'] ?? 0} km',
      duration: '${item['duration_min'] ?? 0} dk',
      earning: ((item['courier_earning'] ?? item['estimated_price'] ?? 0) as num?)?.round() ?? 0,
    )));"""
new = """    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourierActiveJobRealtimePage(
      shipmentId: item['id'].toString(),
      pickup: (item['pickup_address'] ?? '').toString(),
      dropoff: (item['dropoff_address'] ?? '').toString(),
      earning: ((item['courier_earning'] ?? item['estimated_price'] ?? 0) as num?)?.round() ?? 0,
    )));"""
if old not in s:
    raise SystemExit('assigned job block not found')
p.write_text(s.replace(old, new))

p = Path('lib/courier_search_page.dart')
s = p.read_text()
s = s.replace("  Timer? testStageTimer;\n", "")
s = s.replace("  int testStage = 0;\n", "")
s = s.replace("      _startTestStages();\n", "")
start = s.find("  void _startTestStages() {")
if start != -1:
    end = s.find("\n  void _listenShipment", start)
    if end == -1:
        raise SystemExit('test stage method end not found')
    s = s[:start] + s[end+1:]
s = s.replace("    testStageTimer?.cancel();\n", "")
s = s.replace("        Positioned(right: 17 * s, top: 50 * s, child: Container(padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 9 * s), decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(12 * s)), child: Text('Test akışı\\notomatik ilerliyor', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10.5 * s, height: 1.2, fontWeight: FontWeight.w800)))),\n", "")
ps = s.find("  Widget _progressCard(double s) {")
pe = s.find("\n  Widget _mapCard", ps)
if ps == -1 or pe == -1:
    raise SystemExit('progress card bounds not found')
progress = """  Widget _progressCard(double s) {
    return Container(
      height: 72 * s,
      margin: EdgeInsets.symmetric(horizontal: 13 * s),
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s), boxShadow: const [BoxShadow(color: Color(0x0A171052), blurRadius: 16, offset: Offset(0, 5))]),
      child: Row(children: [
        SizedBox(width: 26 * s, height: 26 * s, child: CircularProgressIndicator(strokeWidth: 3 * s, color: orange)),
        SizedBox(width: 12 * s),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Kurye aranıyor', style: TextStyle(color: navy, fontSize: 13 * s, fontWeight: FontWeight.w900)),
          SizedBox(height: 3 * s),
          Text('Gönderin uygun online kuryelerin havuzunda.', style: TextStyle(color: muted, fontSize: 10 * s, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
"""
s = s[:ps] + progress + s[pe:]
p.write_text(s)

p = Path('lib/customer_assigned_courier_page.dart')
s = p.read_text()
s = s.replace("  StreamSubscription<Map<String, dynamic>>? courierSub;", "  StreamSubscription<Map<String, dynamic>>? courierSub;\n  StreamSubscription<Map<String, dynamic>>? shipmentSub;")
marker = """      final courierId = value['courier_id']?.toString();
      if (courierId != null && courierId.isNotEmpty) {
        courierSub = data.watchCourierLocation(courierId).listen((row) {
          if (mounted) setState(() => courierLocation = row);
        });
      }"""
repl = marker + """
      shipmentSub = data.watchShipment(widget.shipmentId).listen((row) {
        if (!mounted || row.isEmpty) return;
        setState(() {
          info = <String, dynamic>{
            ...?info,
            'shipment_status': row['status'],
            'pickup_address': row['pickup_address'],
            'dropoff_address': row['dropoff_address'],
            'pickup_lat': row['pickup_lat'],
            'pickup_lng': row['pickup_lng'],
            'dropoff_lat': row['dropoff_lat'],
            'dropoff_lng': row['dropoff_lng'],
            'estimated_price': row['estimated_price'],
            'public_code': row['public_code'],
          };
        });
      });"""
if marker not in s:
    raise SystemExit('customer assigned load marker not found')
s = s.replace(marker, repl)
s = s.replace("    courierSub?.cancel();\n    super.dispose();", "    courierSub?.cancel();\n    shipmentSub?.cancel();\n    super.dispose();")
p.write_text(s)
