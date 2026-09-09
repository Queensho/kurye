import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'data/app_data_service.dart';

class ServiceRegionMapAdminPage extends StatefulWidget {
  const ServiceRegionMapAdminPage({super.key});

  @override
  State<ServiceRegionMapAdminPage> createState() => _ServiceRegionMapAdminPageState();
}

class _ServiceRegionMapAdminPageState extends State<ServiceRegionMapAdminPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF74839A);

  final data = AppDataService.instance;
  final mapController = MapController();
  List<Map<String, dynamic>> regions = [];
  List<LatLng> points = [];
  String? selectedId;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final raw = await data.client.rpc('admin_get_service_regions_geojson');
      final rows = List<Map<String, dynamic>>.from(raw as List);
      if (!mounted) return;
      setState(() {
        regions = rows;
        selectedId ??= rows.isEmpty ? null : rows.first['id']?.toString();
        loading = false;
      });
      _loadSelectedBoundary();
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bölgeler yüklenemedi: $e')));
    }
  }

  Map<String, dynamic>? get selectedRegion {
    for (final r in regions) {
      if (r['id']?.toString() == selectedId) return r;
    }
    return null;
  }

  void _loadSelectedBoundary() {
    final r = selectedRegion;
    if (r == null) {
      setState(() => points = []);
      return;
    }
    final geometry = r['boundary'];
    final loaded = <LatLng>[];
    if (geometry is Map) {
      final type = geometry['type']?.toString();
      final coords = geometry['coordinates'];
      dynamic ring;
      if (type == 'MultiPolygon' && coords is List && coords.isNotEmpty) {
        final polygon = coords.first;
        if (polygon is List && polygon.isNotEmpty) ring = polygon.first;
      } else if (type == 'Polygon' && coords is List && coords.isNotEmpty) {
        ring = coords.first;
      }
      if (ring is List) {
        for (final c in ring) {
          if (c is List && c.length >= 2) {
            final lng = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            loaded.add(LatLng(lat, lng));
          }
        }
        if (loaded.length > 1 && loaded.first == loaded.last) loaded.removeLast();
      }
    }
    setState(() => points = loaded);
    if (loaded.isNotEmpty) {
      final lat = loaded.map((e) => e.latitude).reduce((a, b) => a + b) / loaded.length;
      final lng = loaded.map((e) => e.longitude).reduce((a, b) => a + b) / loaded.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try { mapController.move(LatLng(lat, lng), 12.5); } catch (_) {}
      });
    }
  }

  Future<void> _save() async {
    if (selectedId == null) return;
    if (points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bölge sınırı için en az 3 nokta seç.')));
      return;
    }
    setState(() => saving = true);
    try {
      final ring = points.map((p) => [p.longitude, p.latitude]).toList();
      ring.add([points.first.longitude, points.first.latitude]);
      final geoJson = '{"type":"Polygon","coordinates":[${_encodeRing(ring)}]}';
      await data.client.rpc('admin_set_service_region_boundary', params: {
        'p_region_id': selectedId,
        'p_geojson': geoJson,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PostGIS bölge sınırı kaydedildi.')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _encodeRing(List<List<double>> ring) => '[${ring.map((c) => '[${c[0]},${c[1]}]').join(',')}]';

  Future<void> _clearBoundary() async {
    if (selectedId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Bölge sınırı silinsin mi?'),
        content: const Text('Bu işlem yalnızca polygon sınırını kaldırır; bölge kaydı silinmez.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Sınırı Sil')),
        ],
      ),
    );
    if (ok != true) return;
    await data.client.rpc('admin_set_service_region_boundary', params: {'p_region_id': selectedId, 'p_geojson': ''});
    if (!mounted) return;
    setState(() => points = []);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final region = selectedRegion;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('PostGIS Bölge Haritası', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: DropdownButtonFormField<String>(
                    value: selectedId,
                    decoration: InputDecoration(
                      labelText: 'Servis bölgesi',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                    items: regions.map((r) => DropdownMenuItem(
                      value: r['id']?.toString(),
                      child: Text('${r['name'] ?? 'Bölge'} • ${r['district'] ?? ''}'),
                    )).toList(),
                    onChanged: (v) {
                      setState(() => selectedId = v);
                      _loadSelectedBoundary();
                    },
                  ),
                ),
                if (region != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Row(children: [
                      Expanded(child: Text(
                        points.isEmpty
                            ? 'Haritaya dokunarak polygon noktalarını sırayla ekle.'
                            : '${points.length} nokta • ${region['name']} • Ek ücret ₺${region['extra_fee'] ?? 0}',
                        style: const TextStyle(color: muted, fontWeight: FontWeight.w700),
                      )),
                      TextButton.icon(
                        onPressed: points.isEmpty ? null : () => setState(() => points.removeLast()),
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Geri Al'),
                      ),
                    ]),
                  ),
                Expanded(
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(41.0082, 28.9784),
                      initialZoom: 10.5,
                      minZoom: 5,
                      maxZoom: 18,
                      onTap: (_, p) => setState(() => points.add(p)),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.queensho.kurye',
                      ),
                      if (points.length >= 2)
                        PolylineLayer(polylines: [
                          Polyline(points: [...points, if (points.length >= 3) points.first], strokeWidth: 4, color: blue),
                        ]),
                      if (points.length >= 3)
                        PolygonLayer(polygons: [
                          Polygon(points: points, color: blue.withValues(alpha: .18), borderColor: blue, borderStrokeWidth: 3),
                        ]),
                      MarkerLayer(markers: [
                        for (int i = 0; i < points.length; i++)
                          Marker(
                            point: points[i],
                            width: 32,
                            height: 32,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: blue, width: 3)),
                              child: Text('${i + 1}', style: const TextStyle(color: navy, fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                          ),
                      ]),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedId == null || saving ? null : _clearBoundary,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Sınırı Temizle'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: selectedId == null || saving ? null : _save,
                          icon: saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_rounded),
                          label: Text(saving ? 'Kaydediliyor' : 'Polygonu Kaydet', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}
