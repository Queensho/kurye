import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'courier_route_map_page.dart';
import 'data/app_data_service.dart';

class CourierActiveJobPage extends StatefulWidget {
  final String? shipmentId;
  final String pickup;
  final String dropoff;
  final String pickupKm;
  final String totalKm;
  final String duration;
  final int earning;

  const CourierActiveJobPage({
    super.key,
    this.shipmentId,
    required this.pickup,
    required this.dropoff,
    required this.pickupKm,
    required this.totalKm,
    required this.duration,
    required this.earning,
  });

  @override
  State<CourierActiveJobPage> createState() => _CourierActiveJobPageState();
}

class _CourierActiveJobPageState extends State<CourierActiveJobPage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF1B1255);
  static const muted = Color(0xFF7D7A91);
  static const bg = Color(0xFFF7F7FA);
  static const green = Color(0xFF12A861);
  static const purple = Color(0xFF4025C7);

  String? shipmentId;
  bool loading = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _resolveShipment();
  }

  Future<void> _resolveShipment() async {
    if (widget.shipmentId != null && widget.shipmentId!.isNotEmpty) {
      if (mounted) setState(() { shipmentId = widget.shipmentId; loading = false; });
      return;
    }
    try {
      final rows = await AppDataService.instance.client
          .from('shipments')
          .select('id,claimed_at,created_at')
          .eq('courier_id', AppDataService.instance.userId)
          .inFilter('status', ['accepted','at_pickup','picked_up','at_dropoff'])
          .order('claimed_at', ascending: false)
          .limit(1);
      if (!mounted) return;
      setState(() {
        shipmentId = rows.isEmpty ? null : rows.first['id']?.toString();
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  int _step(String status) => switch (status) {
    'accepted' => 0,
    'at_pickup' => 1,
    'picked_up' => 2,
    'at_dropoff' => 3,
    'delivered' => 4,
    _ => 0,
  };

  String _action(String status) => switch (status) {
    'accepted' => 'Alım Noktasına Git',
    'at_pickup' => 'Teslim Aldım',
    'picked_up' => 'Teslimat Adresine Git',
    'at_dropoff' => 'Teslim Ettim',
    'delivered' => 'Teslim Edildi',
    _ => 'Devam Et',
  };

  double? _number(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse((raw ?? '').toString());
  }

  Future<void> _openRouteMap({
    required String title,
    required String destinationLabel,
    required LatLng destination,
    LatLng? origin,
    bool useCurrentLocation = false,
  }) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourierRouteMapPage(
      title: title,
      destinationLabel: destinationLabel,
      destination: destination,
      origin: origin,
      useCurrentLocation: useCurrentLocation,
    )));
  }

  void _missingCoordinates() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu gönderinin harita koordinatları bulunamadı.')));
  }

  Future<void> _openNavigation(String address) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}&travelmode=driving');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigasyon açılamadı.')));
    }
  }

  Future<void> _openFullRoute(String pickup, String dropoff) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(pickup)}&destination=${Uri.encodeComponent(dropoff)}&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rota açılamadı.')));
    }
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Müşteri telefon numarası bulunamadı.')));
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone.trim()));
  }

  Future<bool> _confirm(String title, String action) async =>
      await showDialog<bool>(context: context, builder: (d) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: orange), onPressed: () => Navigator.pop(d, true), child: Text(action)),
        ],
      )) ?? false;

  Future<void> _change(String status) async {
    final id = shipmentId;
    if (id == null) return;
    setState(() => busy = true);
    try {
      await AppDataService.instance.updateShipmentStatus(id, status);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _advance(String status, String pickup, String dropoff) async {
    if (busy || status == 'delivered') return;
    if (status == 'accepted') {
      await _openNavigation(pickup);
      if (mounted && await _confirm('Alım noktasına vardın mı?', 'Vardım')) await _change('at_pickup');
    } else if (status == 'at_pickup') {
      await _change('picked_up');
    } else if (status == 'picked_up') {
      await _openNavigation(dropoff);
      if (mounted && await _confirm('Teslimat noktasına vardın mı?', 'Vardım')) await _change('at_dropoff');
    } else if (status == 'at_dropoff') {
      if (await _confirm('Gönderiyi müşteriye teslim ettin mi?', 'Teslim Ettim')) await _change('delivered');
    }
  }

  String _distance(dynamic raw) {
    if (raw is num) {
      final d = raw.toDouble();
      return '${d == d.roundToDouble() ? d.toInt() : d.toStringAsFixed(1)} km';
    }
    final t = (raw ?? '').toString().trim();
    return t.isEmpty ? widget.totalKm : (t.contains('km') ? t : '$t km');
  }

  String _duration(dynamic raw) {
    if (raw is num) return '${raw.round()} dk';
    final t = (raw ?? '').toString().trim();
    return t.isEmpty ? widget.duration : (t.contains('dk') ? t : '$t dk');
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: bg, body: Center(child: CircularProgressIndicator(color: orange)));
    final id = shipmentId;
    if (id == null) return const Scaffold(backgroundColor: bg, body: SafeArea(child: Center(child: Text('Aktif gönderi bulunamadı.'))));

    return StreamBuilder<Map<String, dynamic>>(
      stream: AppDataService.instance.watchShipment(id),
      builder: (context, snapshot) {
        final row = snapshot.data ?? const <String,dynamic>{};
        final status = (row['status'] ?? 'accepted').toString();
        final pickup = (row['pickup_address'] ?? widget.pickup).toString();
        final dropoff = (row['dropoff_address'] ?? widget.dropoff).toString();
        final code = (row['public_code'] ?? 'Aktif İş').toString();
        final earningRaw = row['courier_earning'] ?? row['estimated_price'];
        final earning = earningRaw is num ? earningRaw.round() : widget.earning;
        final phone = (row['customer_phone'] ?? row['receiver_phone'])?.toString();
        final distance = _distance(row['distance_km']);
        final duration = _duration(row['duration_min']);
        final pickupLat = _number(row['pickup_lat'] ?? row['pickup_latitude']);
        final pickupLng = _number(row['pickup_lng'] ?? row['pickup_longitude'] ?? row['pickup_lon']);
        final dropoffLat = _number(row['dropoff_lat'] ?? row['dropoff_latitude']);
        final dropoffLng = _number(row['dropoff_lng'] ?? row['dropoff_longitude'] ?? row['dropoff_lon']);
        final pickupPoint = pickupLat != null && pickupLng != null ? LatLng(pickupLat, pickupLng) : null;
        final dropoffPoint = dropoffLat != null && dropoffLng != null ? LatLng(dropoffLat, dropoffLng) : null;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            bottom: false,
            child: Column(children: [
              _header(code),
              Expanded(child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                children: [
                  _progress(_step(status)),
                  const SizedBox(height: 18),
                  _routeOverview(pickup, dropoff, distance, duration),
                  const SizedBox(height: 12),
                  _addressCard('Alım Noktası', pickup, orange, onRoute: () {
                    if (pickupPoint == null) return _missingCoordinates();
                    _openRouteMap(title: 'Alım Noktasına Rota', destinationLabel: 'Bulunduğun yer → Alım adresi', destination: pickupPoint, useCurrentLocation: true);
                  }),
                  const SizedBox(height: 10),
                  _addressCard('Teslimat Adresi', dropoff, purple, onRoute: () {
                    if (pickupPoint == null || dropoffPoint == null) return _missingCoordinates();
                    _openRouteMap(title: 'Teslimat Rotası', destinationLabel: 'Alım adresi → Teslimat adresi', origin: pickupPoint, destination: dropoffPoint);
                  }),
                  const SizedBox(height: 12),
                  _earningCard(earning),
                ],
              )),
              _bottomAction(status, pickup, dropoff, phone),
            ]),
          ),
        );
      },
    );
  }

  Widget _header(String code) => Container(
    height: 92,
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF2B1776), Color(0xFF171052)]),
      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(26), bottomRight: Radius.circular(26)),
    ),
    child: Row(children: [
      IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
      const SizedBox(width: 6),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Sipariş Detayı', style: TextStyle(color: Color(0xFFD9D2F3), fontSize: 11)),
        Text(code.startsWith('#') ? code : '#$code', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: const Text('AKTİF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
    ]),
  );

  Widget _progress(int step) {
    const labels = ['Aldı','Alımda','Teslim Aldı','Yolda','Teslim'];
    return Row(children: [for (int i=0;i<labels.length;i++) Expanded(child: Column(children: [
      Container(width: 30,height: 30,decoration: BoxDecoration(color: i<=step?orange:const Color(0xFFE5E4EB),shape: BoxShape.circle),child: i<=step?const Icon(Icons.check_rounded,color: Colors.white,size: 18):null),
      const SizedBox(height: 5), Text(labels[i], textAlign: TextAlign.center, style: TextStyle(color: i<=step?orange:muted,fontSize: 8,fontWeight: i<=step?FontWeight.w800:FontWeight.w500)),
    ]))]);
  }

  Widget _routeOverview(String pickup, String dropoff, String distance, String duration) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(22),boxShadow: const [BoxShadow(color: Color(0x0A000000),blurRadius: 14,offset: Offset(0,5))]),
    child: Column(children: [
      Row(children: [
        Container(width: 42,height: 42,decoration: BoxDecoration(color: const Color(0xFFF0EDFF),borderRadius: BorderRadius.circular(13)),child: const Icon(Icons.route_rounded,color: purple)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
          const Text('Alım → Teslimat',style: TextStyle(color: muted,fontSize: 10.5)),
          const SizedBox(height: 2),
          Text('$distance  •  $duration',style: const TextStyle(color: navy,fontSize: 17,fontWeight: FontWeight.w900)),
        ])),
        FilledButton.icon(onPressed: () => _openFullRoute(pickup, dropoff),style: FilledButton.styleFrom(backgroundColor: purple,padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 10),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),icon: const Icon(Icons.navigation_rounded,size: 17),label: const Text('Navigasyon',style: TextStyle(fontSize: 10,fontWeight: FontWeight.w800))),
      ]),
      const SizedBox(height: 12),
      Row(children: [const Icon(Icons.circle,color: orange,size: 10),const SizedBox(width: 8),Expanded(child: Text(pickup,maxLines: 1,overflow: TextOverflow.ellipsis,style: const TextStyle(color: muted,fontSize: 10.5)))]),
      Padding(padding: const EdgeInsets.only(left: 4),child: Align(alignment: Alignment.centerLeft,child: Container(width: 2,height: 18,color: const Color(0xFFE3E0EA)))),
      Row(children: [const Icon(Icons.location_on_rounded,color: purple,size: 17),const SizedBox(width: 2),Expanded(child: Text(dropoff,maxLines: 1,overflow: TextOverflow.ellipsis,style: const TextStyle(color: muted,fontSize: 10.5)))]),
    ]),
  );

  Widget _addressCard(String title,String address,Color color,{required VoidCallback onRoute})=>Container(
    minHeight: 80,
    padding: const EdgeInsets.fromLTRB(13,11,10,11),
    decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Container(width: 42,height: 42,decoration: BoxDecoration(color: color.withValues(alpha:.10),shape: BoxShape.circle),child: Icon(Icons.location_on_rounded,color: color,size: 23)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.center,children: [Text(title,style: const TextStyle(color: navy,fontSize: 13,fontWeight: FontWeight.w900)),const SizedBox(height: 3),Text(address,maxLines: 2,overflow: TextOverflow.ellipsis,style: const TextStyle(color: muted,fontSize: 10.5,height: 1.25))])),
      TextButton.icon(onPressed: onRoute, icon: Icon(Icons.route_rounded,color: color,size: 18), label: Text('Rota',style: TextStyle(color: color,fontSize: 10.5,fontWeight: FontWeight.w900))),
    ]),
  );

  Widget _earningCard(int earning)=>Container(
    height: 66,padding: const EdgeInsets.symmetric(horizontal: 15),decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(20)),
    child: Row(children: [const Icon(Icons.payments_rounded,color: green,size: 27),const SizedBox(width: 10),const Expanded(child: Text('Kurye Kazancı',style: TextStyle(color: muted,fontSize: 11.5))),Text('₺$earning',style: const TextStyle(color: green,fontSize: 21,fontWeight: FontWeight.w900))]),
  );

  Widget _bottomAction(String status,String pickup,String dropoff,String? phone)=>SafeArea(
    top: false,
    child: Container(color: Colors.white,padding: const EdgeInsets.fromLTRB(14,8,14,12),child: Row(children: [
      Expanded(child: FilledButton.icon(onPressed: status=='delivered'||busy?null:()=>_advance(status,pickup,dropoff),style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54),backgroundColor: orange,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),icon: busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.navigation_rounded),label: Text(_action(status),style: const TextStyle(fontWeight: FontWeight.w900)))),
      const SizedBox(width: 9),
      SizedBox(width: 54,height:54,child: OutlinedButton(onPressed:()=>_call(phone),style: OutlinedButton.styleFrom(padding:EdgeInsets.zero,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),side: const BorderSide(color: Color(0xFFE1DEEA))),child: const Icon(Icons.phone_rounded,color: purple))),
    ])),
  );
}
