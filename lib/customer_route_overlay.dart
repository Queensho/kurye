import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class CustomerRouteOverlay extends StatefulWidget {
  const CustomerRouteOverlay({
    super.key,
    required this.courierPoint,
    required this.targetPoint,
    required this.onEtaChanged,
  });

  final LatLng? courierPoint;
  final LatLng? targetPoint;
  final void Function(int? etaMinutes, double? distanceKm) onEtaChanged;

  @override
  State<CustomerRouteOverlay> createState() => _CustomerRouteOverlayState();
}

class _CustomerRouteOverlayState extends State<CustomerRouteOverlay> {
  static const routeColor = Color(0xFF6C5CE7);
  List<LatLng> points = const [];
  Timer? timer;
  LatLng? lastCourier;
  LatLng? lastTarget;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant CustomerRouteOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_different(oldWidget.courierPoint, widget.courierPoint) ||
        _different(oldWidget.targetPoint, widget.targetPoint)) {
      _refresh(force: true);
    }
  }

  bool _different(LatLng? a, LatLng? b) {
    if (a == null || b == null) return a != b;
    return const Distance().as(LengthUnit.Meter, a, b) > 35;
  }

  Future<void> _refresh({bool force = false}) async {
    final courier = widget.courierPoint;
    final target = widget.targetPoint;
    if (courier == null || target == null || loading) {
      if (courier == null || target == null) {
        if (mounted && points.isNotEmpty) setState(() => points = const []);
        widget.onEtaChanged(null, null);
      }
      return;
    }
    if (!force && lastCourier != null && lastTarget != null &&
        !_different(lastCourier, courier) && !_different(lastTarget, target)) {
      return;
    }

    loading = true;
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${courier.longitude},${courier.latitude};${target.longitude},${target.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) throw StateError('route_http_${response.statusCode}');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) throw StateError('route_missing');
      final route = Map<String, dynamic>.from(routes.first as Map);
      final geometry = Map<String, dynamic>.from(route['geometry'] as Map);
      final coordinates = List<dynamic>.from(geometry['coordinates'] as List);
      final nextPoints = coordinates.map((raw) {
        final pair = List<dynamic>.from(raw as List);
        return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
      }).toList(growable: false);
      final duration = (route['duration'] as num?)?.toDouble();
      final distance = (route['distance'] as num?)?.toDouble();
      final eta = duration == null ? null : (duration / 60).ceil();
      final km = distance == null ? null : distance / 1000;
      lastCourier = courier;
      lastTarget = target;
      if (mounted) setState(() => points = nextPoints);
      widget.onEtaChanged(eta, km);
    } catch (_) {
      final meters = const Distance().as(LengthUnit.Meter, courier, target);
      final fallbackKm = meters / 1000;
      final fallbackEta = ((fallbackKm / 25) * 60).ceil().clamp(1, 999).toInt();
      if (mounted) setState(() => points = [courier, target]);
      widget.onEtaChanged(fallbackEta, fallbackKm);
    } finally {
      loading = false;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    return PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          strokeWidth: 5,
          color: routeColor,
          borderStrokeWidth: 2,
          borderColor: Colors.white,
        ),
      ],
    );
  }
}
