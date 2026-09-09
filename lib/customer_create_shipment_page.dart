import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'address_picker_page.dart';
import 'courier_search_page.dart';
import 'data/app_data_service.dart';

class CreateShipmentPage extends StatefulWidget {
  const CreateShipmentPage({super.key});

  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF758198);

  final data = AppDataService.instance;
  final noteController = TextEditingController();

  int vehicle = 0;
  int package = 0;
  int payment = 0;
  AddressSelection? pickup;
  AddressSelection? dropoff;
  String? weight;
  String? size;
  String? selectedCardId;
  List<Map<String, dynamic>> cards = [];
  List<LatLng> routePoints = [];
  double? distanceKm;
  int? durationMin;
  int? quotedPrice;
  bool routeBusy = false;
  bool quoteBusy = false;
  bool creating = false;

  bool get ready => pickup != null && dropoff != null && distanceKm != null && quotedPrice != null && !routeBusy && !quoteBusy;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final rows = await data.getPaymentMethods();
      if (!mounted) return;
      final list = rows.where((e) => e['type'] == 'card').toList();
      setState(() {
        cards = list;
        if (selectedCardId == null && list.isNotEmpty) {
          final defaults = list.where((e) => e['is_default'] == true).toList();
          selectedCardId = (defaults.isNotEmpty ? defaults.first : list.first)['id'].toString();
        }
      });
    } catch (_) {}
  }

  Future<void> _pickAddress(bool isPickup) async {
    final result = await Navigator.of(context).push<AddressSelection>(MaterialPageRoute(
      builder: (_) => AddressPickerPage(
        title: isPickup ? 'Alım Adresi' : 'Teslimat Adresi',
        initial: isPickup ? pickup : dropoff,
      ),
    ));
    if (result == null || !mounted) return;
    setState(() {
      if (isPickup) pickup = result; else dropoff = result;
      distanceKm = null;
      durationMin = null;
      quotedPrice = null;
      routePoints = [];
    });
    if (pickup != null && dropoff != null) await _calculateRouteAndQuote();
  }

  Future<void> _calculateRouteAndQuote() async {
    final a = pickup;
    final b = dropoff;
    if (a == null || b == null) return;
    setState(() { routeBusy = true; quotedPrice = null; });
    try {
      final uri = Uri.parse('https://router.project-osrm.org/route/v1/driving/${a.lng},${a.lat};${b.lng},${b.lat}?overview=full&geometries=geojson&steps=false');
      final response = await http.get(uri);
      if (response.statusCode != 200) throw StateError('route_failed');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) throw StateError('route_missing');
      final route = Map<String, dynamic>.from(routes.first as Map);
      final geometry = Map<String, dynamic>.from(route['geometry'] as Map);
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final points = coordinates.map((e) {
        final p = e as List<dynamic>;
        return LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble());
      }).toList();
      if (!mounted) return;
      setState(() {
        distanceKm = (route['distance'] as num).toDouble() / 1000;
        durationMin = ((route['duration'] as num).toDouble() / 60).ceil();
        routePoints = points;
      });
    } catch (_) {
      final straight = const Distance().as(LengthUnit.Kilometer, a.point, b.point);
      if (!mounted) return;
      setState(() {
        distanceKm = straight * 1.25;
        durationMin = ((straight * 1.25) / (vehicle == 0 ? 28 : 24) * 60).ceil();
        routePoints = [a.point, b.point];
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Canlı rota alınamadı; yaklaşık yol mesafesi kullanılıyor.')));
    } finally {
      if (mounted) setState(() => routeBusy = false);
    }
    await _loadQuote();
  }

  Future<void> _loadQuote() async {
    final km = distanceKm;
    final address = pickup?.displayName;
    if (km == null || address == null) return;
    setState(() { quoteBusy = true; quotedPrice = null; });
    try {
      final quote = await data.calculateDeliveryPrice(
        vehicleType: vehicle == 0 ? 'motorcycle' : 'car',
        distanceKm: km,
        pickupAddress: address,
      );
      final raw = quote['customer_total'];
      final price = raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}');
      if (price == null) throw StateError('Fiyat alınamadı.');
      if (mounted) setState(() => quotedPrice = price.round());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ücret hesaplanamadı: $e')));
    } finally {
      if (mounted) setState(() => quoteBusy = false);
    }
  }

  Future<void> _choose(String title, List<String> options, ValueChanged<String> onSelected) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
        for (final option in options) ListTile(title: Text(option), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.pop(context, option)),
        const SizedBox(height: 10),
      ])),
    );
    if (value != null) onSelected(value);
  }

  Future<void> _chooseCard() async {
    await _loadCards();
    if (!mounted) return;
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıtlı kart bulunamadı. Gerçek online ödeme sağlayıcısı bağlanana kadar nakit ödeme kullan.')));
      return;
    }
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text('Kayıtlı Kart', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
        for (final card in cards) ListTile(
          leading: const Icon(Icons.credit_card_rounded, color: blue),
          title: Text('${card['brand'] ?? 'Kart'} •••• ${card['last4'] ?? ''}'),
          trailing: selectedCardId == card['id'].toString() ? const Icon(Icons.check_circle_rounded, color: blue) : null,
          onTap: () => Navigator.pop(context, card['id'].toString()),
        ),
      ])),
    );
    if (id != null && mounted) setState(() => selectedCardId = id);
  }

  Future<void> _create() async {
    if (pickup == null) { await _pickAddress(true); return; }
    if (dropoff == null) { await _pickAddress(false); return; }
    if (!ready || creating) return;
    if (payment == 1 && selectedCardId == null) { await _chooseCard(); return; }

    setState(() => creating = true);
    try {
      const packageTypes = ['package', 'food', 'document', 'other'];
      final created = await data.createShipment(
        vehicleType: vehicle == 0 ? 'motorcycle' : 'car',
        packageType: packageTypes[package],
        pickupAddress: pickup!.displayName,
        dropoffAddress: dropoff!.displayName,
        pickupLat: pickup!.lat,
        pickupLng: pickup!.lng,
        dropoffLat: dropoff!.lat,
        dropoffLng: dropoff!.lng,
        weightLabel: weight,
        sizeLabel: size,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        distanceKm: distanceKm,
        durationMin: durationMin,
        estimatedPrice: quotedPrice,
        paymentType: payment == 0 ? 'cash' : 'online',
        paymentMethodId: payment == 1 ? selectedCardId : null,
      );
      final id = created['id']?.toString();
      if (id == null || id.isEmpty) throw StateError('Gönderi kimliği alınamadı.');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CourierSearchPage(shipmentId: id)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gönderi oluşturulamadı: $e')));
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  void _showMap() {
    final a = pickup;
    final b = dropoff;
    if (a == null || b == null) return;
    final center = LatLng((a.lat + b.lat) / 2, (a.lng + b.lng) / 2);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .72,
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 11),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.queensho.kurye'),
            if (routePoints.isNotEmpty) PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 5, color: blue)]),
            MarkerLayer(markers: [
              Marker(point: a.point, width: 52, height: 52, child: const Icon(Icons.location_on_rounded, color: blue, size: 42)),
              Marker(point: b.point, width: 52, height: 52, child: const Icon(Icons.flag_rounded, color: Color(0xFF19C983), size: 38)),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Gönderi Oluştur', style: TextStyle(fontWeight: FontWeight.w900, color: navy)),
          Text('Gerçek rota ve merkezi fiyatlandırma', style: TextStyle(fontSize: 11, color: muted)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Taşıma Türü', Row(children: [
            Expanded(child: _choiceCard(0, vehicle, Icons.two_wheeler_rounded, 'Motosiklet', 'Hızlı ve pratik', () async { setState(() { vehicle = 0; quotedPrice = null; }); if (distanceKm != null) await _loadQuote(); })),
            const SizedBox(width: 10),
            Expanded(child: _choiceCard(1, vehicle, Icons.directions_car_rounded, 'Araç', 'Büyük gönderiler', () async { setState(() { vehicle = 1; quotedPrice = null; }); if (distanceKm != null) await _loadQuote(); })),
          ])),
          const SizedBox(height: 14),
          _section('Adres Bilgileri', Column(children: [
            _address('Alım Adresi', pickup, Icons.trip_origin_rounded, () => _pickAddress(true)),
            const SizedBox(height: 10),
            _address('Teslimat Adresi', dropoff, Icons.location_on_rounded, () => _pickAddress(false)),
            if (pickup != null && dropoff != null) ...[
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _showMap, icon: const Icon(Icons.map_outlined), label: const Text('Rotayı Haritada Gör'))),
            ],
          ])),
          if (pickup != null && dropoff != null) ...[
            const SizedBox(height: 14),
            _quoteCard(),
          ],
          const SizedBox(height: 14),
          _section('Gönderi Detayları', Column(children: [
            Row(children: [
              Expanded(child: _smallChoice(0, package, 'Paket', () => setState(() => package = 0))),
              const SizedBox(width: 6),
              Expanded(child: _smallChoice(1, package, 'Yiyecek', () => setState(() => package = 1))),
              const SizedBox(width: 6),
              Expanded(child: _smallChoice(2, package, 'Belge', () => setState(() => package = 2))),
              const SizedBox(width: 6),
              Expanded(child: _smallChoice(3, package, 'Diğer', () => setState(() => package = 3))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _select('Ağırlık', weight ?? 'Seçiniz', () => _choose('Tahmini Ağırlık', ['0–1 kg', '1–3 kg', '3–5 kg', '5–10 kg', '10–20 kg', '20 kg+'], (v) => setState(() => weight = v)))),
              const SizedBox(width: 10),
              Expanded(child: _select('Boyut', size ?? 'Seçiniz', () => _choose('Tahmini Boyut', ['Çok Küçük', 'Küçük', 'Orta', 'Büyük', 'Çok Büyük'], (v) => setState(() => size = v)))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: noteController, maxLines: 2, decoration: InputDecoration(labelText: 'Ek Not (isteğe bağlı)', filled: true, fillColor: const Color(0xFFF5F8FC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          ])),
          const SizedBox(height: 14),
          _section('Ödeme Yöntemi', Row(children: [
            Expanded(child: _choiceCard(0, payment, Icons.payments_rounded, 'Nakit', 'Teslimatta öde', () => setState(() => payment = 0))),
            const SizedBox(width: 10),
            Expanded(child: _choiceCard(1, payment, Icons.credit_card_rounded, 'Online', 'Kayıtlı kart', () async { setState(() => payment = 1); await _chooseCard(); })),
          ])),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: ready && !creating ? _create : (creating ? null : _create),
            icon: creating ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
            label: Text(creating ? 'Oluşturuluyor...' : quotedPrice == null ? 'Gönderi Oluştur' : 'Gönderi Oluştur • ₺$quotedPrice'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58), backgroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _quoteCard() {
    if (routeBusy || quoteBusy) {
      return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(22)), child: const Row(children: [SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)), SizedBox(width: 12), Text('Rota ve güncel ücret hesaplanıyor...', style: TextStyle(fontWeight: FontWeight.w800, color: navy))]));
    }
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF168CF5), Color(0xFF3AA7FF)]), borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        const CircleAvatar(backgroundColor: Color(0x33FFFFFF), child: Icon(Icons.payments_rounded, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Güncel Ücret', style: TextStyle(color: Color(0xDDFFFFFF), fontWeight: FontWeight.w700)), Text(quotedPrice == null ? 'Tekrar hesapla' : '₺$quotedPrice', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)), Text('${distanceKm?.toStringAsFixed(1) ?? '-'} km • ${durationMin ?? '-'} dk', style: const TextStyle(color: Color(0xDDFFFFFF)))])),
        if (quotedPrice == null) IconButton(onPressed: _loadQuote, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
      ]),
    );
  }

  Widget _section(String title, Widget child) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 5))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, color: navy, fontWeight: FontWeight.w900)), const SizedBox(height: 12), child]),
  );

  Widget _choiceCard(int index, int selected, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final active = index == selected;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Container(height: 82, padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: active ? const Color(0xFFF0F8FF) : Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: active ? blue : const Color(0xFFE5EAF2), width: active ? 1.5 : 1)), child: Row(children: [CircleAvatar(backgroundColor: active ? const Color(0xFFDDEFFF) : const Color(0xFFF2F6FA), child: Icon(icon, color: active ? blue : muted)), const SizedBox(width: 8), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: navy, fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(fontSize: 10, color: muted))])), Icon(active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: active ? blue : const Color(0xFFB0BAC8))])));
  }

  Widget _address(String title, AddressSelection? value, IconData icon, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7FAFD), borderRadius: BorderRadius.circular(16), border: Border.all(color: value == null ? const Color(0xFFE5EAF2) : const Color(0xFFB9DAFF))), child: Row(children: [Icon(icon, color: blue), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 10, color: muted)), Text(value?.displayName ?? 'Adres seç', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: value == null ? muted : navy, fontWeight: FontWeight.w700))])), const Icon(Icons.chevron_right_rounded, color: blue)])));

  Widget _smallChoice(int index, int selected, String title, VoidCallback onTap) {
    final active = index == selected;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Container(height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: active ? const Color(0xFFEAF4FF) : const Color(0xFFF7F9FC), borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? blue : const Color(0xFFE5EAF2))), child: Text(title, style: TextStyle(color: active ? blue : navy, fontSize: 11, fontWeight: FontWeight.w800))));
  }

  Widget _select(String title, String value, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(height: 58, padding: const EdgeInsets.symmetric(horizontal: 11), decoration: BoxDecoration(color: const Color(0xFFF7F9FC), borderRadius: BorderRadius.circular(15)), child: Row(children: [Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 9, color: muted)), Text(value, style: const TextStyle(color: navy, fontWeight: FontWeight.w800))])), const Icon(Icons.keyboard_arrow_down_rounded, color: blue)])));
}
