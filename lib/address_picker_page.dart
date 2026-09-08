import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class AddressSelection {
  const AddressSelection({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  final String displayName;
  final double lat;
  final double lng;

  LatLng get point => LatLng(lat, lng);
}

class AddressPickerPage extends StatefulWidget {
  const AddressPickerPage({
    super.key,
    required this.title,
    this.initial,
  });

  final String title;
  final AddressSelection? initial;

  @override
  State<AddressPickerPage> createState() => _AddressPickerPageState();
}

class _AddressPickerPageState extends State<AddressPickerPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF758198);
  static const turkeyCenter = LatLng(39.0, 35.0);

  final controller = TextEditingController();
  final mapController = MapController();
  Timer? debounce;
  bool searching = false;
  bool resolving = false;
  List<AddressSelection> results = [];
  AddressSelection? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
    if (widget.initial != null) {
      controller.text = widget.initial!.displayName;
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    debounce?.cancel();
    final q = value.trim();
    if (q.length < 3) {
      setState(() => results = []);
      return;
    }
    debounce = Timer(const Duration(milliseconds: 550), () => _search(q));
  }

  bool _looksLikeFullAddress(String query) {
    return RegExp(r'\d').hasMatch(query) &&
        (query.toLowerCase().contains('sokak') ||
            query.toLowerCase().contains('sk') ||
            query.toLowerCase().contains('cadde') ||
            query.toLowerCase().contains('cd') ||
            query.toLowerCase().contains('bulvar') ||
            query.toLowerCase().contains('mahall'));
  }

  String _normalizeQuery(String query) {
    return query
        .replaceAll(RegExp(r'\bno\.?\s*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<List<AddressSelection>> _fetchAddresses(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$query, Türkiye',
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '7',
      'countrycodes': 'tr',
      'accept-language': 'tr',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Adres servisi yanıt vermedi');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) {
      final m = item as Map<String, dynamic>;
      return AddressSelection(
        displayName: (m['display_name'] ?? '').toString(),
        lat: double.parse(m['lat'].toString()),
        lng: double.parse(m['lon'].toString()),
      );
    }).where((e) => e.displayName.isNotEmpty).toList();
  }

  Future<void> _search(String query, {bool forceSelect = false}) async {
    if (!mounted) return;
    setState(() => searching = true);
    try {
      var parsed = await _fetchAddresses(query);

      // Nominatim bazı Türkçe adreslerde "No 41" yerine "41" biçimini daha iyi buluyor.
      if (parsed.isEmpty) {
        final normalized = _normalizeQuery(query);
        if (normalized != query) {
          parsed = await _fetchAddresses(normalized);
        }
      }

      if (!mounted) return;
      setState(() => results = parsed);

      // Sokak + kapı numarası girildiğinde en iyi eşleşmeyi doğrudan haritada işaretle.
      if (parsed.isNotEmpty && (forceSelect || _looksLikeFullAddress(query))) {
        await _selectResult(parsed.first, keepSearchText: true);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresler alınamadı. Tekrar deneyin.')),
      );
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> _selectResult(AddressSelection value, {bool keepSearchText = false}) async {
    setState(() {
      selected = value;
      if (!keepSearchText) controller.text = value.displayName;
      results = [];
    });
    mapController.move(value.point, 17);
  }

  Future<void> _selectMapPoint(TapPosition _, LatLng point) async {
    setState(() {
      resolving = true;
      selected = AddressSelection(
        displayName: 'Konum belirleniyor...',
        lat: point.latitude,
        lng: point.longitude,
      );
    });
    mapController.move(point, 16);

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'format': 'jsonv2',
        'accept-language': 'tr',
        'zoom': '18',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) throw Exception('Ters geocode başarısız');
      final m = jsonDecode(response.body) as Map<String, dynamic>;
      final name = (m['display_name'] ?? 'Haritadan seçilen konum').toString();
      if (!mounted) return;
      final value = AddressSelection(displayName: name, lat: point.latitude, lng: point.longitude);
      setState(() {
        selected = value;
        controller.text = name;
      });
    } catch (_) {
      if (!mounted) return;
      final fallback = AddressSelection(
        displayName: 'Haritadan seçilen konum',
        lat: point.latitude,
        lng: point.longitude,
      );
      setState(() {
        selected = fallback;
        controller.text = fallback.displayName;
      });
    } finally {
      if (mounted) setState(() => resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = selected?.point ?? turkeyCenter;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: TextField(
              controller: controller,
              autofocus: widget.initial == null,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                final q = value.trim();
                if (q.length >= 3) _search(q, forceSelect: true);
              },
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Mahalle, cadde, sokak ve kapı no ara',
                prefixIcon: const Icon(Icons.search_rounded, color: blue),
                suffixIcon: searching
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : controller.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              controller.clear();
                              setState(() {
                                results = [];
                                selected = null;
                              });
                              mapController.move(turkeyCenter, 5.2);
                            },
                            icon: const Icon(Icons.close_rounded),
                          )
                        : null,
                filled: true,
                fillColor: const Color(0xFFF2F7FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (results.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 235),
              color: Colors.white,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item = results[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined, color: blue),
                    title: Text(
                      item.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: navy),
                    ),
                    onTap: () => _selectResult(item),
                  );
                },
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: selected == null ? 5.2 : 16,
                    minZoom: 4.5,
                    maxZoom: 18,
                    onTap: _selectMapPoint,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.queensho.kurye',
                    ),
                    if (selected != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selected!.point,
                            width: 56,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12)],
                                border: Border.all(color: blue, width: 2),
                              ),
                              child: const Icon(Icons.location_on_rounded, color: blue, size: 32),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12)],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.touch_app_rounded, color: blue, size: 18),
                        SizedBox(width: 6),
                        Text('Haritaya dokunarak da seçebilirsin', style: TextStyle(fontSize: 11, color: navy, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selected != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place_rounded, color: blue, size: 19),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              selected!.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: navy, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: selected == null || resolving
                          ? null
                          : () => Navigator.of(context).pop(selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFB7C7D8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: Text(
                        resolving ? 'Konum belirleniyor...' : 'Bu adresi kullan',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
