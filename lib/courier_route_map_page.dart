import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class CourierRouteMapPage extends StatefulWidget {
  const CourierRouteMapPage({
    super.key,
    required this.title,
    required this.destinationLabel,
    required this.destination,
    this.origin,
    this.useCurrentLocation = false,
  });

  final String title;
  final String destinationLabel;
  final LatLng destination;
  final LatLng? origin;
  final bool useCurrentLocation;

  @override
  State<CourierRouteMapPage> createState() => _CourierRouteMapPageState();
}

class _CourierRouteMapPageState extends State<CourierRouteMapPage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF171052);
  static const purple = Color(0xFF4025C7);

  final MapController mapController = MapController();
  LatLng? origin;
  List<LatLng> route = const [];
  bool loading = true;
  bool mapReady = false;
  String? error;
  double? distanceKm;
  double? durationMin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      LatLng? start = widget.origin;
      if (widget.useCurrentLocation) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          throw Exception('Konum izni gerekli.');
        }
        final p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        start = LatLng(p.latitude, p.longitude);
      }
      if (start == null) throw Exception('Başlangıç konumu bulunamadı.');
      origin = start;
      await _fetchRoute(start, widget.destination);
    } catch (e) {
      if (mounted) setState(() { error = e.toString().replaceFirst('Exception: ', ''); loading = false; });
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    try {
      final uri = Uri.parse('https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');
      final response = await http.get(uri);
      if (response.statusCode != 200) throw Exception('Rota alınamadı.');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) throw Exception('Rota bulunamadı.');
      final first = routes.first as Map<String, dynamic>;
      final coords = ((first['geometry'] as Map<String, dynamic>)['coordinates'] as List)
          .map((e) => LatLng((e as List)[1].toDouble(), e[0].toDouble()))
          .toList();
      if (!mounted) return;
      setState(() {
        route = coords;
        distanceKm = (first['distance'] as num?)?.toDouble() == null ? null : (first['distance'] as num).toDouble() / 1000;
        durationMin = (first['duration'] as num?)?.toDouble() == null ? null : (first['duration'] as num).toDouble() / 60;
        loading = false;
      });
      _fitRoute();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        route = [start, end];
        error = 'Yol rotası alınamadı; iki nokta gösteriliyor.';
        loading = false;
      });
      _fitRoute();
    }
  }

  void _fitRoute() {
    if (!mapReady) return;
    final points = route.length >= 2
        ? route
        : [if (origin != null) origin!, widget.destination];
    if (points.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !mapReady) return;
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.fromLTRB(42, 42, 42, 150),
        ),
      );
    });
  }

  LatLng get _center {
    final a = origin ?? widget.destination;
    final b = widget.destination;
    return LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Column(children: [
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF2B1776), Color(0xFF171052)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
              const SizedBox(width: 4),
              Expanded(child: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
            ]),
          ),
          Expanded(
            child: Stack(children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 12.8,
                  onMapReady: () {
                    mapReady = true;
                    _fitRoute();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a','b','c'],
                    userAgentPackageName: 'com.queensho.kurye',
                  ),
                  if (route.isNotEmpty) PolylineLayer(polylines: [Polyline(points: route, strokeWidth: 5, color: purple)]),
                  MarkerLayer(markers: [
                    if (origin != null) Marker(
                      point: origin!,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10)]),
                        child: const Icon(Icons.trip_origin_rounded, color: orange, size: 28),
                      ),
                    ),
                    Marker(
                      point: widget.destination,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10)]),
                        child: const Icon(Icons.location_on_rounded, color: purple, size: 31),
                      ),
                    ),
                  ]),
                ],
              ),
              if (loading) const Center(child: CircularProgressIndicator(color: orange)),
              Positioned(left: 14, right: 14, bottom: 16, child: Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 5))]),
                child: Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFF1EDFF), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.route_rounded, color: purple)),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.destinationLabel, style: const TextStyle(color: navy, fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(distanceKm == null ? (error ?? 'Rota hesaplanıyor...') : '${distanceKm!.toStringAsFixed(1)} km • ${durationMin!.round()} dk', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF77758A), fontSize: 10.5)),
                  ])),
                ]),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}
