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

class _GeoCandidate {
  const _GeoCandidate(this.selection, this.address);
  final AddressSelection selection;
  final Map<String, dynamic> address;
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
    if (widget.initial != null) controller.text = widget.initial!.displayName;
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
      setState(() {
        results = [];
        selected = null;
      });
      return;
    }
    debounce = Timer(const Duration(milliseconds: 700), () => _search(q));
  }

  bool _looksLikeFullAddress(String query) {
    final q = query.toLowerCase();
    return RegExp(r'\d').hasMatch(q) &&
        (q.contains('sokak') ||
            q.contains(' sk') ||
            q.contains('cadde') ||
            q.contains(' cd') ||
            q.contains('bulvar') ||
            q.contains('mahall'));
  }

  String _normalizeQuery(String query) {
    var q = query.toLowerCase().trim();

    // Sık görülen yazım biçimleri ve kullanıcının örneğindeki kısa yazım.
    q = q
        .replaceAll(RegExp(r'\bvaklı\b', caseSensitive: false), 'kavaklı')
        .replaceAll(RegExp(r'\bmahallesi\b', caseSensitive: false), 'mahalle')
        .replaceAll(RegExp(r'\bmah\.?\b', caseSensitive: false), 'mahalle')
        .replaceAll(RegExp(r'\bsk\.?\b', caseSensitive: false), 'sokak')
        .replaceAll(RegExp(r'\bcd\.?\b', caseSensitive: false), 'cadde')
        .replaceAll(RegExp(r'\bno\.?\s*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return q;
  }

  String _withoutHouseNumber(String query) {
    var q = query.replaceAll(
      RegExp(r'\bno\.?\s*\d+[a-zA-Z]?\b', caseSensitive: false),
      ' ',
    );
    q = q.replaceAll(
      RegExp(r'\s+\d+[a-zA-Z]?\s*$', caseSensitive: false),
      ' ',
    );
    return q.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _houseNumber(String query) {
    final no = RegExp(
      r'\bno\.?\s*(\d+[a-zA-Z]?)\b',
      caseSensitive: false,
    ).firstMatch(query);
    if (no != null) return no.group(1);

    final normalized = _normalizeQuery(query);
    final end = RegExp(r'(\d+[a-zA-Z]?)\s*$').firstMatch(normalized);
    return end?.group(1);
  }

  String? _neighborhood(String query) {
    final q = query
        .replaceAll(RegExp(r'\bvaklı\b', caseSensitive: false), 'kavaklı')
        .trim();
    final match = RegExp(
      r'(.+?)\s+(?:mahallesi|mahalle|mah\.?)\b',
      caseSensitive: false,
    ).firstMatch(q);
    if (match == null) return null;
    var value = (match.group(1) ?? '').trim();
    final pieces = value.split(RegExp(r'[,;]'));
    value = pieces.last.trim();
    return value.isEmpty ? null : value;
  }

  String? _road(String query) {
    var q = query
        .replaceAll(RegExp(r'\bvaklı\b', caseSensitive: false), 'kavaklı')
        .replaceAll(RegExp(r'\bno\.?\s*\d+[a-zA-Z]?\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+\d+[a-zA-Z]?\s*$', caseSensitive: false), ' ')
        .trim();

    final afterMahalle = RegExp(
      r'(?:mahallesi|mahalle|mah\.?)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(q);
    if (afterMahalle != null) q = (afterMahalle.group(1) ?? '').trim();

    final road = RegExp(
      r'(.+?\s+(?:sokak|sokağı|sk\.?|cadde|caddesi|cd\.?|bulvar|bulvarı))\b',
      caseSensitive: false,
    ).firstMatch(q);
    return road?.group(1)?.trim();
  }

  Future<List<_GeoCandidate>> _fetchCandidates(
    String query, {
    String? viewbox,
    int limit = 12,
  }) async {
    final params = <String, String>{
      'q': '$query, Türkiye',
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '$limit',
      'countrycodes': 'tr',
      'accept-language': 'tr',
      'dedupe': '1',
    };
    if (viewbox != null) {
      params['viewbox'] = viewbox;
      params['bounded'] = '1';
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Adres servisi yanıt vermedi');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) {
      final m = item as Map<String, dynamic>;
      final address =
          (m['address'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      return _GeoCandidate(
        AddressSelection(
          displayName: (m['display_name'] ?? '').toString(),
          lat: double.parse(m['lat'].toString()),
          lng: double.parse(m['lon'].toString()),
        ),
        address,
      );
    }).where((e) => e.selection.displayName.isNotEmpty).toList();
  }

  String _fold(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  double _scoreCandidate(_GeoCandidate c, String query) {
    final q = _fold(_normalizeQuery(query));
    final name = _fold(c.selection.displayName);
    var score = 0.0;

    final tokens = q
        .split(' ')
        .where((e) => e.length >= 3 && !RegExp(r'^\d+$').hasMatch(e));
    for (final token in tokens) {
      if (name.contains(token)) score += 1;
    }

    final wantedNo = _houseNumber(query);
    final foundNo = (c.address['house_number'] ?? '').toString().toLowerCase();
    if (wantedNo != null && foundNo == wantedNo.toLowerCase()) score += 12;

    final wantedMahalle = _neighborhood(query);
    if (wantedMahalle != null) {
      final haystack = _fold([
        c.address['neighbourhood'],
        c.address['quarter'],
        c.address['suburb'],
        c.address['town'],
        c.address['county'],
        c.address['city'],
        c.selection.displayName,
      ].whereType<Object>().join(' '));
      if (haystack.contains(_fold(wantedMahalle))) score += 5;
    }

    final wantedRoad = _road(query);
    if (wantedRoad != null) {
      final foundRoad = _fold((c.address['road'] ?? '').toString());
      if (foundRoad.isNotEmpty &&
          (foundRoad.contains(_fold(wantedRoad)) ||
              _fold(wantedRoad).contains(foundRoad))) {
        score += 7;
      }
    }

    if ((c.address['road'] ?? '').toString().isNotEmpty) score += 1;
    return score;
  }

  String _contextSuffix(Map<String, dynamic> address) {
    final parts = <String>[];
    for (final key in [
      'neighbourhood',
      'quarter',
      'suburb',
      'town',
      'county',
      'city',
      'province',
    ]) {
      final value = (address[key] ?? '').toString().trim();
      if (value.isNotEmpty && !parts.contains(value)) parts.add(value);
    }
    return parts.join(', ');
  }

  String _viewboxAround(AddressSelection point, {double delta = 0.05}) {
    return '${point.lng - delta},${point.lat + delta},${point.lng + delta},${point.lat - delta}';
  }

  Future<List<_GeoCandidate>> _smartCandidates(String query) async {
    final normalized = _normalizeQuery(query);
    final houseNo = _houseNumber(query);
    final neighborhood = _neighborhood(query);
    final road = _road(query);
    final all = <_GeoCandidate>[];

    void merge(List<_GeoCandidate> fetched) {
      for (final item in fetched) {
        final exists = all.any((e) =>
            (e.selection.lat - item.selection.lat).abs() < 0.00001 &&
            (e.selection.lng - item.selection.lng).abs() < 0.00001);
        if (!exists) all.add(item);
      }
    }

    Future<void> add(String q, {String? viewbox}) async {
      if (q.trim().isEmpty) return;
      merge(await _fetchCandidates(q, viewbox: viewbox));
    }

    // 1) Kullanıcının yazdığı tam metin.
    await add(query);
    if (normalized != query.toLowerCase().trim()) await add(normalized);

    // 2) Kapı numarasını çıkarıp mahalle+sokak bağlamını bul.
    if (_looksLikeFullAddress(query)) {
      final base = _withoutHouseNumber(normalized);
      if (base.isNotEmpty) await add(base);

      // 3) Mahalle tek başına aranır. Böylece il/ilçe bilgisi kullanıcı yazmasa
      // bile örn. Kavaklı -> Beylikdüzü / İstanbul bağlamı elde edilir.
      final contexts = <_GeoCandidate>[];
      if (neighborhood != null) {
        contexts.addAll(await _fetchCandidates('$neighborhood mahalle', limit: 20));
        if (contexts.isEmpty) {
          contexts.addAll(await _fetchCandidates(neighborhood, limit: 20));
        }
      }

      // Mahalle bulunamazsa sokak/temel sorgudan gelen sonuçlar bağlam olarak kullanılır.
      if (contexts.isEmpty) {
        contexts.addAll(await _fetchCandidates(base, limit: 20));
      }

      contexts.sort((a, b) =>
          _scoreCandidate(b, query).compareTo(_scoreCandidate(a, query)));

      for (final context in contexts.take(5)) {
        final viewbox = _viewboxAround(context.selection, delta: 0.06);
        final suffix = _contextSuffix(context.address);

        if (road != null && houseNo != null) {
          await add('$road $houseNo', viewbox: viewbox);
          if (suffix.isNotEmpty) await add('$road $houseNo, $suffix');
        }
        if (road != null) {
          await add(road, viewbox: viewbox);
          if (suffix.isNotEmpty) await add('$road, $suffix');
        }
        if (houseNo != null) {
          await add('$base $houseNo', viewbox: viewbox);
        }
      }
    }

    all.sort((a, b) =>
        _scoreCandidate(b, query).compareTo(_scoreCandidate(a, query)));
    return all;
  }

  Future<void> _search(String query, {bool forceSelect = false}) async {
    if (!mounted) return;
    setState(() => searching = true);

    try {
      final candidates = await _smartCandidates(query);
      if (!mounted) return;

      final parsed = candidates.map((e) => e.selection).take(7).toList();
      setState(() => results = parsed);

      if (parsed.isNotEmpty && (forceSelect || _looksLikeFullAddress(query))) {
        await _selectResult(parsed.first, keepSearchText: true);
      } else if (forceSelect && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adres bulunamadı. Mahalle ve sokak adını kontrol edin.'),
          ),
        );
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
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'accept-language': 'tr',
        'zoom': '18',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Ters geocode başarısız');
      }
      final m = jsonDecode(response.body) as Map<String, dynamic>;
      final name =
          (m['display_name'] ?? 'Haritadan seçilen konum').toString();
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
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
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
                    leading:
                        const Icon(Icons.location_on_outlined, color: blue),
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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          const Icon(Icons.place_rounded,
                              color: blue, size: 19),
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
                        resolving
                            ? 'Konum belirleniyor...'
                            : 'Bu adresi kullan',
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
