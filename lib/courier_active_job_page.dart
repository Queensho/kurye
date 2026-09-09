import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class CourierActiveJobPage extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String pickupKm;
  final String totalKm;
  final String duration;
  final int earning;

  const CourierActiveJobPage({
    super.key,
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
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF718198);
  static const green = Color(0xFF10B866);
  static const locationIqKey = String.fromEnvironment('LOCATIONIQ_API_KEY');

  final MapController _mapController = MapController();
  int step = 0;
  Position? currentPosition;
  LatLng? pickupPoint;
  LatLng? dropoffPoint;
  List<LatLng> routePoints = const [];
  bool locating = false;
  bool mapLoading = true;

  String get actionLabel => switch (step) {
        0 => 'Alım Noktasına Git',
        1 => 'Teslim Aldım',
        2 => 'Teslimat Adresine Git',
        _ => 'Teslim Ettim',
      };

  bool get goingToDelivery => step >= 2;
  String get activeTarget => goingToDelivery ? widget.dropoff : widget.pickup;
  String get activeTargetTitle => goingToDelivery ? 'Teslimat Adresi' : 'Alım Noktası';
  LatLng? get activeTargetPoint => goingToDelivery ? dropoffPoint : pickupPoint;

  @override
  void initState() {
    super.initState();
    _prepareMap();
  }

  Future<void> _prepareMap() async {
    setState(() => mapLoading = true);
    pickupPoint = await _geocode(widget.pickup);
    dropoffPoint = await _geocode(widget.dropoff);
    await _getCurrentLocation(showErrors: false);
    await _refreshRoute();
    if (mounted) setState(() => mapLoading = false);
  }

  Future<LatLng?> _geocode(String address) async {
    if (locationIqKey.isEmpty) return null;
    final query = '$address, İstanbul, Türkiye';
    for (final host in ['eu1.locationiq.com', 'us1.locationiq.com']) {
      try {
        final uri = Uri.https(host, '/v1/search', {
          'key': locationIqKey,
          'q': query,
          'format': 'json',
          'limit': '1',
          'countrycodes': 'tr',
        });
        final response = await http.get(uri).timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) continue;
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isEmpty) continue;
        final item = data.first as Map<String, dynamic>;
        return LatLng(
          double.parse(item['lat'].toString()),
          double.parse(item['lon'].toString()),
        );
      } catch (_) {}
    }
    return null;
  }

  Future<void> _refreshRoute() async {
    final target = activeTargetPoint;
    final pos = currentPosition;
    if (target == null || pos == null) {
      if (mounted) setState(() => routePoints = const []);
      return;
    }
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${pos.longitude},${pos.latitude};${target.longitude},${target.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return;
      final geometry = routes.first['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final points = coordinates
          .map((e) => LatLng(
                (e as List<dynamic>)[1] as num,
                e[0] as num,
              ))
          .map((p) => LatLng(p.latitude.toDouble(), p.longitude.toDouble()))
          .toList();
      if (mounted) setState(() => routePoints = points);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _topBar(),
                const SizedBox(height: 18),
                _hero(),
                const SizedBox(height: 20),
                _progress(),
                const SizedBox(height: 22),
                _mapCard(),
                const SizedBox(height: 18),
                _shipmentCard(),
                const SizedBox(height: 16),
                _customerCard(),
              ]),
            ),
          ),
          _bottomAction(),
        ]),
      ),
    );
  }

  Widget _topBar() => Row(children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 5))]),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF19518A)),
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _cancelDialog,
          icon: const Icon(Icons.warning_amber_rounded),
          label: const Text('İşi İptal Et'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF4C4C), side: const BorderSide(color: Color(0xFFFFC7C7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
        ),
      ]);

  Widget _hero() => SizedBox(
        height: 180,
        child: Stack(children: [
          const Positioned(
            left: 0,
            top: 18,
            width: 245,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('İşin Aktif!', style: TextStyle(color: navy, fontSize: 34, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text('Evrakı alım noktasından teslim al\nve teslimat adresine ulaştır.', style: TextStyle(color: muted, fontSize: 17, height: 1.35, fontWeight: FontWeight.w500)),
            ]),
          ),
          Positioned(right: -12, bottom: -5, width: 185, height: 185, child: Image.asset('assets/images/kurye_header_hd.png', fit: BoxFit.contain)),
        ]),
      );

  Widget _progress() {
    const labels = ['Alım Noktasına Git', 'Teslim Aldım', 'Teslimat Adresine Git', 'Teslim Ettim'];
    return Row(children: [
      for (int i = 0; i < 4; i++) ...[
        Expanded(child: Column(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: i <= step ? blue : const Color(0xFFF2F7FC), shape: BoxShape.circle, border: Border.all(color: i <= step ? blue : const Color(0xFFC8D9EA), width: 2)),
            child: i <= step ? const Icon(Icons.check_rounded, color: Colors.white, size: 19) : null,
          ),
          const SizedBox(height: 7),
          Text(labels[i], textAlign: TextAlign.center, style: TextStyle(color: i <= step ? blue : muted, fontSize: 9.5, fontWeight: i <= step ? FontWeight.w900 : FontWeight.w600)),
        ])),
        if (i < 3) Container(width: 20, height: 2, color: i < step ? blue : const Color(0xFFD4E1EE)),
      ],
    ]);
  }

  Widget _mapCard() {
    final target = activeTargetPoint;
    final current = currentPosition == null ? null : LatLng(currentPosition!.latitude, currentPosition!.longitude);
    final center = target ?? current ?? const LatLng(41.066, 28.995);

    return Container(
      height: 310,
      decoration: BoxDecoration(color: const Color(0xFFEAF4F9), borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 6))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 14.3),
              children: [
                TileLayer(
                  urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.queensho.kurye',
                ),
                if (routePoints.isNotEmpty)
                  PolylineLayer(polylines: [
                    Polyline(points: routePoints, strokeWidth: 6, color: blue, borderStrokeWidth: 3, borderColor: Colors.white),
                  ]),
                MarkerLayer(markers: [
                  if (current != null)
                    Marker(
                      point: current,
                      width: 54,
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(color: blue.withValues(alpha: .20), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const CircleAvatar(radius: 17, backgroundColor: blue, child: Icon(Icons.my_location_rounded, color: Colors.white, size: 20)),
                      ),
                    ),
                  if (target != null)
                    Marker(
                      point: target,
                      width: 48,
                      height: 48,
                      child: CircleAvatar(
                        backgroundColor: goingToDelivery ? const Color(0xFFFF4757) : blue,
                        child: const Icon(Icons.location_on_rounded, color: Colors.white),
                      ),
                    ),
                ]),
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: 16,
            child: InkWell(
              onTap: () => _showNavigationSheet(goingToDelivery),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 12)]),
                child: Row(children: [
                  Icon(Icons.location_on_rounded, color: goingToDelivery ? const Color(0xFFFF4757) : blue),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(activeTargetTitle, style: const TextStyle(color: navy, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(activeTarget, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11)),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: blue),
                ]),
              ),
            ),
          ),
          if (mapLoading)
            const Positioned.fill(child: ColoredBox(color: Color(0x66FFFFFF), child: Center(child: CircularProgressIndicator()))),
          Positioned(
            right: 18,
            bottom: 18,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              backgroundColor: Colors.white,
              foregroundColor: blue,
              onPressed: () {
                final p = currentPosition;
                if (p != null) _mapController.move(LatLng(p.latitude, p.longitude), 15);
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _shipmentCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 5))]),
        child: Column(children: [
          Row(children: [
            const Text('Gönderi Detayları', style: TextStyle(color: navy, fontSize: 23, fontWeight: FontWeight.w900)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEAF5FF), borderRadius: BorderRadius.circular(12)), child: const Text('#12458', style: TextStyle(color: blue, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF1F8FF), borderRadius: BorderRadius.circular(19)),
            child: Row(children: [
              const CircleAvatar(radius: 24, backgroundColor: Color(0xFFE3F2FF), child: Icon(Icons.description_outlined, color: blue)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Evrak Teslimatı', style: TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('1 adet evrak', style: TextStyle(color: muted, fontSize: 11))])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text('Tahmini Ücret', style: TextStyle(color: muted, fontSize: 11)), Text('₺${widget.earning}', style: const TextStyle(color: green, fontSize: 27, fontWeight: FontWeight.w900))]),
            ]),
          ),
          const SizedBox(height: 14),
          _address(Icons.location_on_rounded, blue, 'Alım Adresi', widget.pickup, false),
          const Divider(height: 24, color: Color(0xFFE7EEF5)),
          _address(Icons.location_on_rounded, const Color(0xFFFF4757), 'Teslimat Adresi', widget.dropoff, true),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _metric(Icons.route_rounded, widget.pickupKm, 'Alımına Uzaklık')),
            const SizedBox(width: 8),
            Expanded(child: _metric(Icons.inventory_2_outlined, '1 adet', 'Evrak')),
            const SizedBox(width: 8),
            Expanded(child: _metric(Icons.schedule_rounded, widget.duration, 'Tahmini Süre')),
          ]),
        ]),
      );

  Widget _address(IconData icon, Color color, String title, String value, bool delivery) => Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: navy, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(value, style: const TextStyle(color: muted, fontSize: 12))])),
        TextButton.icon(onPressed: () => _showNavigationSheet(delivery), icon: const Icon(Icons.navigation_rounded, size: 17), label: const Text('Haritada Aç')),
      ]);

  Widget _metric(IconData icon, String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(color: const Color(0xFFF1F8FF), borderRadius: BorderRadius.circular(17)),
        child: Column(children: [Icon(icon, color: const Color(0xFF155BAC), size: 23), const SizedBox(height: 5), Text(value, style: const TextStyle(color: navy, fontWeight: FontWeight.w900)), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 9))]),
      );

  Widget _customerCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
        child: Row(children: [
          const CircleAvatar(radius: 27, backgroundColor: Color(0xFFEAF5FF), child: Icon(Icons.person_outline_rounded, color: blue, size: 29)),
          const SizedBox(width: 13),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Müşteri Bilgileri', style: TextStyle(color: muted, fontSize: 11)), Text('Ahmet Yılmaz', style: TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.w900)), Text('+90 555 123 45 67', style: TextStyle(color: muted, fontSize: 12))])),
          _circleAction(Icons.phone_rounded),
          const SizedBox(width: 9),
          _circleAction(Icons.chat_bubble_rounded),
        ]),
      );

  Widget _circleAction(IconData icon) => InkWell(onTap: () {}, child: CircleAvatar(radius: 25, backgroundColor: const Color(0xFFEAF5FF), child: Icon(icon, color: blue)));

  Widget _bottomAction() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: FilledButton.icon(
            onPressed: _advance,
            icon: Icon(step == 3 ? Icons.check_rounded : step == 1 ? Icons.inventory_2_outlined : Icons.navigation_rounded),
            label: Text(actionLabel),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(62), backgroundColor: step == 1 || step == 3 ? green : blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ),
        ),
      );

  Future<void> _advance() async {
    if (step == 0) {
      await _showNavigationSheet(false);
      return;
    }
    if (step == 1) {
      setState(() => step = 2);
      await _refreshRoute();
      _fitActiveRoute();
      return;
    }
    if (step == 2) {
      await _showNavigationSheet(true);
      return;
    }
    _completeJob();
  }

  Future<Position?> _getCurrentLocation({bool showErrors = true}) async {
    if (locating) return currentPosition;
    if (mounted) setState(() => locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (showErrors && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum servisini açman gerekiyor.')));
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (showErrors && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum izni verilmedi.')));
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => currentPosition = pos);
      return pos;
    } catch (_) {
      if (showErrors && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum alınamadı.')));
      return null;
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> _openNavigation(String destination) async {
    final pos = currentPosition ?? await _getCurrentLocation();
    final target = activeTargetPoint;
    final destinationValue = target == null ? Uri.encodeComponent(destination) : '${target.latitude},${target.longitude}';
    final origin = pos == null ? '' : '&origin=${pos.latitude},${pos.longitude}';
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destinationValue$origin&travelmode=driving');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigasyon açılamadı.')));
    }
  }

  void _fitActiveRoute() {
    final target = activeTargetPoint;
    final pos = currentPosition;
    if (target == null || pos == null) return;
    final bounds = LatLngBounds.fromPoints([LatLng(pos.latitude, pos.longitude), target]);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)));
  }

  Future<void> _showNavigationSheet(bool delivery) async {
    final address = delivery ? widget.dropoff : widget.pickup;
    final title = delivery ? 'Teslimat Adresi' : 'Alım Noktası';
    final target = delivery ? dropoffPoint : pickupPoint;
    await _getCurrentLocation();
    if (!mounted) return;
    await _refreshRoute();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .82),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 60, height: 5, decoration: BoxDecoration(color: const Color(0xFFD4DCE5), borderRadius: BorderRadius.circular(8))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(children: [
                CircleAvatar(radius: 23, backgroundColor: const Color(0xFFEAF5FF), child: Icon(Icons.location_on_rounded, color: delivery ? const Color(0xFFFF4757) : blue)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(address, style: const TextStyle(color: muted, fontSize: 12.5)),
                ])),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: FlutterMap(
                    options: MapOptions(initialCenter: target ?? const LatLng(41.066, 28.995), initialZoom: 14.5),
                    children: [
                      TileLayer(urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', userAgentPackageName: 'com.queensho.kurye'),
                      if (routePoints.isNotEmpty)
                        PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 6, color: blue, borderStrokeWidth: 3, borderColor: Colors.white)]),
                      MarkerLayer(markers: [
                        if (currentPosition != null)
                          Marker(point: LatLng(currentPosition!.latitude, currentPosition!.longitude), width: 50, height: 50, child: const CircleAvatar(backgroundColor: blue, child: Icon(Icons.my_location_rounded, color: Colors.white))),
                        if (target != null)
                          Marker(point: target, width: 50, height: 50, child: CircleAvatar(backgroundColor: delivery ? const Color(0xFFFF4757) : blue, child: const Icon(Icons.location_on_rounded, color: Colors.white))),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(children: [
                FilledButton.icon(
                  onPressed: () => _openNavigation(address),
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Navigasyonu Başlat'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    if (delivery) {
                      setState(() => step = 3);
                    } else {
                      setState(() => step = 1);
                    }
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(delivery ? 'Teslimat Noktasına Vardım' : 'Alım Noktasına Vardım'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)), textStyle: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _completeJob() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        icon: const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE8FBF2), child: Icon(Icons.check_rounded, color: green, size: 34)),
        title: const Text('Tebrikler!'),
        content: Text('₺${widget.earning} kazanç hesabına işlendi.', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [FilledButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Tamam'))],
      ),
    );
  }

  void _cancelDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('İşi iptal etmek istiyor musun?'),
        content: const Text('İptal edilen iş tekrar iş havuzuna dönecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF4C4C)), child: const Text('İptal Et')),
        ],
      ),
    );
  }
}
