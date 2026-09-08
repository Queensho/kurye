import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'address_picker_page.dart';
import 'courier_search_page.dart';

class CreateShipmentPage extends StatefulWidget {
  const CreateShipmentPage({super.key});

  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF7C879C);
  static const green = Color(0xFF19C983);

  int vehicle = 0;
  int detail = 0;
  int payment = 0;
  String selectedCard = 'Visa •••• 4242';
  AddressSelection? pickup;
  AddressSelection? dropoff;
  bool calculatingRoute = false;
  double? routeDistanceKm;
  int? routeDurationMin;
  List<LatLng> routePoints = [];
  String? selectedWeight;
  String? selectedSize;
  final noteController = TextEditingController();

  bool get hasAddresses => pickup != null && dropoff != null;
  bool get routeReady => hasAddresses && !calculatingRoute && routeDistanceKm != null;

  int get estimatedPrice {
    final distance = routeDistanceKm ?? 0;
    final base = vehicle == 0 ? 65.0 : 95.0;
    final perKm = vehicle == 0 ? 10.0 : 14.0;
    return (base + distance * perKm).round();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> _pickAddress({required bool isPickup}) async {
    final result = await Navigator.of(context).push<AddressSelection>(
      MaterialPageRoute(
        builder: (_) => AddressPickerPage(
          title: isPickup ? 'Alım Adresi' : 'Teslimat Adresi',
          initial: isPickup ? pickup : dropoff,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (isPickup) {
        pickup = result;
      } else {
        dropoff = result;
      }
    });
    if (hasAddresses) await _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    final a = pickup;
    final b = dropoff;
    if (a == null || b == null) return;
    setState(() {
      calculatingRoute = true;
      routeDistanceKm = null;
      routeDurationMin = null;
      routePoints = [];
    });
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${a.lng},${a.lat};${b.lng},${b.lat}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) throw Exception('Rota servisi yanıt vermedi');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) throw Exception('Rota bulunamadı');
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final points = coordinates.map((e) {
        final pair = e as List<dynamic>;
        return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
      }).toList();
      if (!mounted) return;
      setState(() {
        routeDistanceKm = (route['distance'] as num).toDouble() / 1000;
        routeDurationMin = ((route['duration'] as num).toDouble() / 60).ceil();
        routePoints = points;
      });
    } catch (_) {
      final straightKm = const Distance().as(LengthUnit.Kilometer, a.point, b.point);
      if (!mounted) return;
      setState(() {
        routeDistanceKm = straightKm * 1.25;
        routeDurationMin = ((straightKm * 1.25) / (vehicle == 0 ? 28 : 24) * 60).ceil();
        routePoints = [a.point, b.point];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canlı rota alınamadı, yaklaşık mesafe hesaplandı.')),
      );
    } finally {
      if (mounted) setState(() => calculatingRoute = false);
    }
  }

  Future<void> _pickOption({required String title, required List<String> options, required bool weight}) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: navy))),
          ...options.map((e) => ListTile(title: Text(e, style: const TextStyle(fontWeight: FontWeight.w700)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.pop(context, e))),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (weight) {
        selectedWeight = value;
      } else {
        selectedSize = value;
      }
    });
  }

  void _showMapPreview() {
    if (!hasAddresses) {
      _pickAddress(isPickup: pickup == null);
      return;
    }
    final a = pickup!;
    final b = dropoff!;
    final center = LatLng((a.lat + b.lat) / 2, (a.lng + b.lng) / 2);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .72,
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFDCE3EC), borderRadius: BorderRadius.circular(10))),
          const Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.centerLeft, child: Text('Gönderi Rotası', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)))),
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 10.5, minZoom: 5, maxZoom: 18),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.queensho.kurye'),
                if (routePoints.isNotEmpty) PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 5, color: blue)]),
                MarkerLayer(markers: [
                  Marker(point: a.point, width: 54, height: 54, child: _mapPin(blue, Icons.trip_origin_rounded)),
                  Marker(point: b.point, width: 54, height: 54, child: _mapPin(green, Icons.location_on_rounded)),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: _mapStat(Icons.route_rounded, routeDistanceKm == null ? '—' : '${routeDistanceKm!.toStringAsFixed(1)} km', 'Mesafe')),
              const SizedBox(width: 10),
              Expanded(child: _mapStat(Icons.schedule_rounded, routeDurationMin == null ? '—' : '$routeDurationMin dk', 'Tahmini süre')),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showHelp() => _textSheet('Nasıl çalışır?', 'Adresleri seç, gönderi detaylarını ve ödeme yöntemini belirle. Gönderiyi oluşturduğunda sistem uygun kuryeyi aramaya başlar.');
  void _showVehicleHelp() => _textSheet('Taşıma türü seçimi', 'Küçük ve hızlı gönderiler için Motosiklet, büyük veya hacimli gönderiler için Araç seçebilirsin.');

  void _textSheet(String title, String text) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
          const SizedBox(height: 12),
          Text(text),
        ]),
      ),
    );
  }

  void _showIntermediateStop() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ara durak ekle'),
        content: const Text('Ara durak adresini eklemek için adres seçim ekranı açılacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
          FilledButton(onPressed: () {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ara durak ekleme akışı aktif.')));
          }, child: const Text('Devam Et')),
        ],
      ),
    );
  }

  Future<void> _chooseCard() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('Online Ödeme Kartı', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy))),
          for (final card in const ['Visa •••• 4242', 'Mastercard •••• 7812'])
            ListTile(
              leading: const Icon(Icons.credit_card_rounded, color: blue),
              title: Text(card, style: const TextStyle(fontWeight: FontWeight.w800)),
              trailing: selectedCard == card ? const Icon(Icons.check_circle_rounded, color: blue) : null,
              onTap: () => Navigator.pop(context, card),
            ),
          ListTile(
            leading: const Icon(Icons.add_card_rounded, color: blue),
            title: const Text('Yeni kart ekle', style: TextStyle(fontWeight: FontWeight.w800, color: blue)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeni kart ekleme profil ödeme yöntemlerinden yapılabilir.')));
            },
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
    if (result != null && mounted) setState(() => selectedCard = result);
  }

  void _primaryAction() {
    if (pickup == null) {
      _pickAddress(isPickup: true);
      return;
    }
    if (dropoff == null) {
      _pickAddress(isPickup: false);
      return;
    }
    if (calculatingRoute) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourierSearchPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final s = c.maxWidth / 390;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 24 * s),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _round(s, Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
                SizedBox(width: 14 * s),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Gönderi Oluştur', style: TextStyle(fontSize: 25 * s, fontWeight: FontWeight.w900, color: navy)),
                  Text('Hızlı, güvenli ve kolay', style: TextStyle(fontSize: 14 * s, color: muted)),
                ])),
                _round(s, Icons.help_outline_rounded, _showHelp),
              ]),
              SizedBox(height: 16 * s),
              Container(
                height: 70 * s,
                decoration: BoxDecoration(color: const Color(0xFFE9F4FF), borderRadius: BorderRadius.circular(18 * s)),
                child: Stack(children: [
                  Positioned(left: 12 * s, top: 15 * s, child: Container(width: 40 * s, height: 40 * s, decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(13 * s)), child: Icon(Icons.bolt_rounded, color: Colors.white, size: 27 * s))),
                  Positioned(left: 63 * s, top: 14 * s, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Dakikalar içinde kurye yola çıksın!', style: TextStyle(fontSize: 12 * s, fontWeight: FontWeight.w800, color: const Color(0xFF163C80))), SizedBox(height: 4 * s), Text('İhtiyacın ne olursa olsun yanındayız.', style: TextStyle(fontSize: 10.5 * s, color: const Color(0xFF31578D)))])),
                  Positioned(right: -3 * s, bottom: -5 * s, width: 135 * s, height: 88 * s, child: Image.asset('assets/images/kurye_header_hd.png', fit: BoxFit.contain)),
                ]),
              ),
              SizedBox(height: 20 * s),
              Row(children: [
                Expanded(child: Text('Taşıma Türü', style: TextStyle(fontSize: 19 * s, fontWeight: FontWeight.w900, color: navy))),
                InkWell(onTap: _showVehicleHelp, child: Text('Hangisini seçmeliyim?', style: TextStyle(fontSize: 11 * s, color: blue, fontWeight: FontWeight.w700))),
              ]),
              SizedBox(height: 10 * s),
              Row(children: [
                Expanded(child: _vehicle(s, 0, 'Motosiklet', 'Hızlı ve pratik', '10–30 dk', 'assets/images/motosiklet_hd.png')),
                SizedBox(width: 10 * s),
                Expanded(child: _vehicle(s, 1, 'Araç', 'Daha büyük gönderiler', '20–60 dk', 'assets/images/arac_hd.png')),
              ]),
              SizedBox(height: 16 * s),
              _card(s, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text('Adres Bilgileri', style: TextStyle(fontSize: 18 * s, fontWeight: FontWeight.w900, color: navy))), TextButton.icon(onPressed: _showMapPreview, icon: const Icon(Icons.map_outlined), label: Text(hasAddresses ? 'Haritada Gör' : 'Haritadan Seç'))]),
                SizedBox(height: 8 * s),
                _addressField(s, 'Alım Adresi', 'Türkiye genelinde adres ara', pickup, Icons.trip_origin_rounded, () => _pickAddress(isPickup: true)),
                SizedBox(height: 10 * s),
                _addressField(s, 'Teslimat Adresi', 'Türkiye genelinde adres ara', dropoff, Icons.location_on_rounded, () => _pickAddress(isPickup: false)),
                SizedBox(height: 10 * s),
                InkWell(onTap: _showIntermediateStop, borderRadius: BorderRadius.circular(14 * s), child: Container(height: 43 * s, padding: EdgeInsets.symmetric(horizontal: 12 * s), decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(14 * s), border: Border.all(color: const Color(0xFFB9DAFF))), child: Row(children: [Icon(Icons.add_circle_rounded, color: blue, size: 22 * s), SizedBox(width: 9 * s), Text('Ara durak ekle (isteğe bağlı)', style: TextStyle(fontSize: 11.5 * s, color: blue, fontWeight: FontWeight.w700))]))),
              ])),
              if (hasAddresses) ...[
                SizedBox(height: 16 * s),
                calculatingRoute ? _calculatingCard(s) : _priceCard(s),
              ],
              SizedBox(height: 16 * s),
              _card(s, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Gönderi Detayları', style: TextStyle(fontSize: 18 * s, fontWeight: FontWeight.w900, color: navy)),
                SizedBox(height: 12 * s),
                Row(children: [
                  Expanded(child: _chip(s, 0, Icons.inventory_2_outlined, 'Paket')),
                  SizedBox(width: 7 * s),
                  Expanded(child: _chip(s, 1, Icons.restaurant_rounded, 'Yiyecek')),
                  SizedBox(width: 7 * s),
                  Expanded(child: _chip(s, 2, Icons.description_outlined, 'Belge')),
                  SizedBox(width: 7 * s),
                  Expanded(child: _chip(s, 3, Icons.grid_view_rounded, 'Diğer')),
                ]),
                SizedBox(height: 10 * s),
                Row(children: [
                  Expanded(child: _select(s, Icons.scale_outlined, 'Tahmini Ağırlık', selectedWeight ?? 'Seçiniz', () => _pickOption(title: 'Tahmini Ağırlık', options: const ['0–1 kg', '1–3 kg', '3–5 kg', '5–10 kg', '10–20 kg', '20 kg+'], weight: true))),
                  SizedBox(width: 10 * s),
                  Expanded(child: _select(s, Icons.inventory_2_outlined, 'Tahmini Boyut', selectedSize ?? 'Seçiniz', () => _pickOption(title: 'Tahmini Boyut', options: const ['Çok Küçük', 'Küçük', 'Orta', 'Büyük', 'Çok Büyük'], weight: false))),
                ]),
                SizedBox(height: 10 * s),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 4 * s),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15 * s), border: Border.all(color: const Color(0xFFE7ECF3))),
                  child: Row(children: [Icon(Icons.chat_bubble_outline_rounded, color: const Color(0xFF65748A), size: 20 * s), SizedBox(width: 10 * s), Expanded(child: TextField(controller: noteController, maxLines: 2, minLines: 1, decoration: const InputDecoration(border: InputBorder.none, labelText: 'Ek Not (isteğe bağlı)', hintText: 'Örn: Dikkatli taşınsın, kapıya bırakın...')))]),
                ),
              ])),
              SizedBox(height: 16 * s),
              _card(s, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ödeme Yöntemi', style: TextStyle(fontSize: 18 * s, fontWeight: FontWeight.w900, color: navy)),
                SizedBox(height: 12 * s),
                Row(children: [
                  Expanded(child: _paymentOption(s, 0, Icons.payments_rounded, 'Nakit', 'Teslimatta öde')),
                  SizedBox(width: 10 * s),
                  Expanded(child: _paymentOption(s, 1, Icons.credit_card_rounded, 'Online', 'Kart ile öde')),
                ]),
                if (payment == 1) ...[
                  SizedBox(height: 10 * s),
                  InkWell(onTap: _chooseCard, borderRadius: BorderRadius.circular(15 * s), child: Container(height: 56 * s, padding: EdgeInsets.symmetric(horizontal: 12 * s), decoration: BoxDecoration(color: const Color(0xFFF5FAFF), borderRadius: BorderRadius.circular(15 * s), border: Border.all(color: const Color(0xFFB9DAFF))), child: Row(children: [Icon(Icons.credit_card_rounded, color: blue, size: 21 * s), SizedBox(width: 10 * s), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Kayıtlı Kart', style: TextStyle(fontSize: 9.5 * s, color: muted)), Text(selectedCard, style: TextStyle(fontSize: 11.5 * s, color: navy, fontWeight: FontWeight.w800))])), Icon(Icons.keyboard_arrow_down_rounded, color: blue)]))),
                  SizedBox(height: 8 * s),
                  Text('Online ödeme, kurye eşleşmesi tamamlandığında provizyona alınır.', style: TextStyle(fontSize: 9.5 * s, color: muted)),
                ],
              ])),
              SizedBox(height: 16 * s),
              SizedBox(
                width: double.infinity,
                height: 58 * s,
                child: ElevatedButton.icon(
                  onPressed: calculatingRoute ? null : _primaryAction,
                  icon: Icon(Icons.send_rounded, color: Colors.white, size: 22 * s),
                  label: Text(!hasAddresses ? 'Adresleri Seç' : routeReady ? 'Gönderi Oluştur • ₺$estimatedPrice' : 'Gönderi Oluştur', style: TextStyle(fontSize: 17 * s, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(backgroundColor: blue, disabledBackgroundColor: const Color(0xFF8FC6F7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20 * s)), elevation: 0),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _paymentOption(double s, int index, IconData icon, String title, String subtitle) {
    final selected = payment == index;
    return InkWell(
      onTap: () => setState(() => payment = index),
      borderRadius: BorderRadius.circular(17 * s),
      child: Container(
        height: 82 * s,
        padding: EdgeInsets.all(11 * s),
        decoration: BoxDecoration(color: selected ? const Color(0xFFF0F8FF) : Colors.white, borderRadius: BorderRadius.circular(17 * s), border: Border.all(color: selected ? blue : const Color(0xFFE5EAF2), width: selected ? 1.5 : 1)),
        child: Row(children: [
          Container(width: 38 * s, height: 38 * s, decoration: BoxDecoration(color: selected ? const Color(0xFFDDEFFF) : const Color(0xFFF2F6FA), shape: BoxShape.circle), child: Icon(icon, color: selected ? blue : muted, size: 21 * s)),
          SizedBox(width: 9 * s),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 13 * s, color: navy, fontWeight: FontWeight.w900)), Text(subtitle, style: TextStyle(fontSize: 9.5 * s, color: muted))])),
          Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: selected ? blue : const Color(0xFFB0BAC8), size: 21 * s),
        ]),
      ),
    );
  }

  Widget _calculatingCard(double s) => Container(width: double.infinity, padding: EdgeInsets.all(16 * s), decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(22 * s)), child: Row(children: [SizedBox(width: 26 * s, height: 26 * s, child: const CircularProgressIndicator(strokeWidth: 3)), SizedBox(width: 12 * s), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Rota ve ücret hesaplanıyor', style: TextStyle(fontSize: 14 * s, fontWeight: FontWeight.w900, color: navy)), Text('Gerçek yol mesafesi alınıyor...', style: TextStyle(fontSize: 10.5 * s, color: muted))]))]));

  Widget _priceCard(double s) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(15 * s),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF168CF5), Color(0xFF3AA7FF)]), borderRadius: BorderRadius.circular(22 * s)),
        child: Row(children: [
          Container(width: 46 * s, height: 46 * s, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), shape: BoxShape.circle), child: Icon(Icons.payments_rounded, color: Colors.white, size: 24 * s)),
          SizedBox(width: 12 * s),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tahmini Ücret', style: TextStyle(fontSize: 12 * s, color: Colors.white.withValues(alpha: .86), fontWeight: FontWeight.w700)), Text('₺$estimatedPrice', style: TextStyle(fontSize: 27 * s, color: Colors.white, fontWeight: FontWeight.w900)), Text('${routeDistanceKm?.toStringAsFixed(1) ?? '—'} km • yaklaşık ${routeDurationMin ?? '—'} dk', style: TextStyle(fontSize: 10.5 * s, color: Colors.white.withValues(alpha: .82)))])),
          Text(vehicle == 0 ? 'Motosiklet' : 'Araç', style: TextStyle(fontSize: 10 * s, color: Colors.white, fontWeight: FontWeight.w900)),
        ]),
      );

  Widget _mapPin(Color color, IconData icon) => Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: color, width: 2)), child: Icon(icon, color: color, size: 30));
  Widget _mapStat(IconData icon, String value, String label) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFF2F7FD), borderRadius: BorderRadius.circular(17)), child: Row(children: [Icon(icon, color: blue), const SizedBox(width: 9), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: navy)), Text(label, style: const TextStyle(fontSize: 10, color: muted))])]));

  Widget _addressField(double s, String title, String hint, AddressSelection? value, IconData icon, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15 * s), child: Container(constraints: BoxConstraints(minHeight: 66 * s), padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 8 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15 * s), border: Border.all(color: value != null ? const Color(0xFFB9DAFF) : const Color(0xFFE7ECF3))), child: Row(children: [Container(width: 32 * s, height: 32 * s, decoration: const BoxDecoration(color: Color(0xFFF2F6FA), shape: BoxShape.circle), child: Icon(icon, color: value != null ? blue : const Color(0xFF64748B), size: 20 * s)), SizedBox(width: 10 * s), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 10.5 * s, color: muted, fontWeight: FontWeight.w700)), SizedBox(height: 2 * s), Text(value?.displayName ?? hint, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5 * s, color: value != null ? navy : const Color(0xFFA0A9B9), fontWeight: value != null ? FontWeight.w700 : FontWeight.w500))])), Icon(Icons.chevron_right_rounded, color: blue, size: 21 * s)])));

  Widget _round(double s, IconData icon, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18 * s), child: Container(width: 44 * s, height: 44 * s, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17 * s)), child: Icon(icon, color: const Color(0xFF173C84), size: 25 * s)));

  Widget _vehicle(double s, int idx, String title, String subtitle, String time, String asset) {
    final selected = vehicle == idx;
    return GestureDetector(onTap: () { setState(() => vehicle = idx); if (hasAddresses) _calculateRoute(); }, child: Container(height: 168 * s, padding: EdgeInsets.all(10 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20 * s), border: Border.all(color: selected ? blue : const Color(0xFFE7EDF5), width: selected ? 1.5 : 1)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Center(child: Image.asset(asset, fit: BoxFit.contain))), Text(title, style: TextStyle(fontSize: 16 * s, fontWeight: FontWeight.w900, color: navy)), Text(subtitle, style: TextStyle(fontSize: 11 * s, color: muted)), SizedBox(height: 6 * s), Text(time, style: TextStyle(fontSize: 9.5 * s, color: blue, fontWeight: FontWeight.w700))])));
  }

  Widget _card(double s, Widget child) => Container(width: double.infinity, padding: EdgeInsets.all(12 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22 * s), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 5))]), child: child);

  Widget _chip(double s, int idx, IconData icon, String label) {
    final selected = detail == idx;
    return GestureDetector(onTap: () => setState(() => detail = idx), child: Container(height: 48 * s, decoration: BoxDecoration(color: selected ? const Color(0xFFF3F9FF) : Colors.white, borderRadius: BorderRadius.circular(14 * s), border: Border.all(color: selected ? blue : const Color(0xFFE5EAF2))), child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: selected ? blue : const Color(0xFF607089), size: 18 * s), SizedBox(width: 5 * s), Text(label, style: TextStyle(fontSize: 10 * s, color: selected ? blue : const Color(0xFF607089), fontWeight: FontWeight.w700))]))));
  }

  Widget _select(double s, IconData icon, String title, String value, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15 * s), child: Container(height: 58 * s, padding: EdgeInsets.symmetric(horizontal: 10 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15 * s), border: Border.all(color: value == 'Seçiniz' ? const Color(0xFFE7ECF3) : const Color(0xFFB9DAFF))), child: Row(children: [Icon(icon, color: value == 'Seçiniz' ? const Color(0xFF65748A) : blue, size: 18 * s), SizedBox(width: 8 * s), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 9.4 * s, color: const Color(0xFF64748B))), Text(value, style: TextStyle(fontSize: 10.5 * s, color: value == 'Seçiniz' ? const Color(0xFF9AA4B5) : navy, fontWeight: value == 'Seçiniz' ? FontWeight.w500 : FontWeight.w800))])), Icon(Icons.keyboard_arrow_down_rounded, color: blue, size: 20 * s)])));
}
