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
  static const turkeyCenter = LatLng(39.0, 35.0);
  static const geoapifyKey = String.fromEnvironment('GEOAPIFY_API_KEY');

  final controller = TextEditingController();
  final mapController = MapController();
  bool searching = false;
  bool resolving = false;
  List<AddressSelection> results = [];
  AddressSelection? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
    if (widget.initial != null) controller.text = widget.initial!.displayName;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _normalizeQuery(String query) {
    var q = query.trim();
    q = q
        .replaceAll(RegExp(r'\bvaklı\b', caseSensitive: false), 'Kavaklı')
        .replaceAll(RegExp(r'\bmah\.?\b', caseSensitive: false), 'Mahallesi')
        .replaceAll(RegExp(r'\bsk\.?\b', caseSensitive: false), 'Sokak')
        .replaceAll(RegExp(r'\bcd\.?\b', caseSensitive: false), 'Cadde')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return q;
  }

  Future<List<AddressSelection>> _geoapifySearch(String query) async {
    if (geoapifyKey.isEmpty) {
      throw Exception('Geoapify API anahtarı tanımlı değil');
    }

    final normalized = _normalizeQuery(query);
    final attempts = <String>[
      '$normalized, Türkiye',
      '$normalized, İstanbul, Türkiye',
    ];

    if (normalized.toLowerCase().contains('kavaklı') &&
        normalized.toLowerCase().contains('vakıf')) {
      attempts.insert(0, '$normalized, Beylikdüzü, İstanbul, Türkiye');
    }

    final all = <AddressSelection>[];

    for (final text in attempts) {
      final uri = Uri.https('api.geoapify.com', '/v1/geocode/search', {
        'text': text,
        'filter': 'countrycode:tr',
        'lang': 'tr',
        'limit': '8',
        'format': 'json',
        'apiKey': geoapifyKey,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Geoapify adres servisi yanıt vermedi');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = (body['results'] as List?) ?? const [];

      for (final row in rows) {
        final m = row as Map<String, dynamic>;
        final lat = double.tryParse('${m['lat']}');
        final lon = double.tryParse('${m['lon']}');
        if (lat == null || lon == null) continue;
        final label = (m['formatted'] ?? m['address_line2'] ?? '').toString().trim();
        if (label.isEmpty) continue;

        final candidate = AddressSelection(
          displayName: label,
          lat: lat,
          lng: lon,
        );

        final duplicate = all.any((e) =>
            (e.lat - candidate.lat).abs() < 0.00001 &&
            (e.lng - candidate.lng).abs() < 0.00001);
        if (!duplicate) all.add(candidate);
      }

      if (all.isNotEmpty) break;
    }

    return all;
  }

  Future<void> _search([String? raw]) async {
    final query = (raw ?? controller.text).trim();
    if (query.length < 3 || searching) return;

    FocusScope.of(context).unfocus();
    setState(() {
      searching = true;
      results = [];
    });

    try {
      final found = await _geoapifySearch(query);
      if (!mounted) return;

      setState(() => results = found);

      if (found.isNotEmpty) {
        await _selectResult(found.first, keepSearchText: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adres bulunamadı. İlçe veya il ekleyerek tekrar deneyin.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final missingKey = e.toString().contains('API anahtarı');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            missingKey
                ? 'Adres servisi henüz etkin değil. GEOAPIFY_API_KEY eklenmeli.'
                : 'Adres servisine ulaşılamadı. Tekrar deneyin.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> _selectResult(
    AddressSelection value, {
    bool keepSearchText = false,
  }) async {
    if (!mounted) return;
    setState(() {
      selected = value;
      if (!keepSearchText) controller.text = value.displayName;
      results = [];
    });
    mapController.move(value.point, 18);
  }

  Future<void> _selectMapPoint(TapPosition _, LatLng point) async {
    if (geoapifyKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adres servisi henüz etkin değil.')),
      );
      return;
    }

    setState(() {
      resolving = true;
      selected = AddressSelection(
        displayName: 'Konum belirleniyor...',
        lat: point.latitude,
        lng: point.longitude,
      );
    });
    mapController.move(point, 17);

    try {
      final uri = Uri.https('api.geoapify.com', '/v1/geocode/reverse', {
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'lang': 'tr',
        'format': 'json',
        'apiKey': geoapifyKey,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Reverse geocode başarısız');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = (body['results'] as List?) ?? const [];
      final first = rows.isNotEmpty ? rows.first as Map<String, dynamic> : null;
      final name = (first?['formatted'] ?? 'Haritadan seçilen konum').toString();

      if (!mounted) return;
      final value = AddressSelection(
        displayName: name,
        lat: point.latitude,
        lng: point.longitude,
      );
      setState(() {
        selected = value;
        controller.text = name;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        selected = AddressSelection(
          displayName: 'Haritadan seçilen konum',
          lat: point.latitude,
          lng: point.longitude,
        );
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
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800, color: navy),
        ),
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
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Mahalle, cadde, sokak ve kapı no ara',
                prefixIcon: const Icon(Icons.search_rounded, color: blue),
                suffixIcon: searching
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.text.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                controller.clear();
                                setState(() {
                                  results = [];
                                  selected = null;
                                });
                                mapController.move(turkeyCenter, 5.2);
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                          IconButton(
                            onPressed: _search,
                            icon: const Icon(Icons.arrow_forward_rounded, color: blue),
                          ),
                        ],
                      ),
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
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
                    maxZoom: 19,
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
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 12,
                                  ),
                                ],
                                border: Border.all(color: blue, width: 2),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: blue,
                                size: 32,
                              ),
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
                      boxShadow: const [
                        BoxShadow(color: Color(0x18000000), blurRadius: 12),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.touch_app_rounded, color: blue, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Haritaya dokunarak da seçebilirsin',
                          style: TextStyle(
                            fontSize: 11,
                            color: navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: navy,
                                fontWeight: FontWeight.w700,
                              ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        resolving ? 'Konum belirleniyor...' : 'Bu adresi kullan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
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
