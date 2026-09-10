import 'dart:convert';

import 'package:flutter/material.dart';
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
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF171052);
  static const purple = Color(0xFF261168);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);
  static const soft = Color(0xFFF3F1FA);
  static const border = Color(0xFFE8E7EE);

  final data = AppDataService.instance;
  final noteController = TextEditingController();

  int package = 0;
  int payment = 0;
  AddressSelection? pickup;
  AddressSelection? dropoff;
  String weight = '1 kg';
  String size = 'Orta';
  String? selectedCardId;
  List<Map<String, dynamic>> cards = [];
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
      if (isPickup) {
        pickup = result;
      } else {
        dropoff = result;
      }
      distanceKm = null;
      durationMin = null;
      quotedPrice = null;
    });
    if (pickup != null && dropoff != null) await _calculateRouteAndQuote();
  }

  Future<void> _calculateRouteAndQuote() async {
    final a = pickup;
    final b = dropoff;
    if (a == null || b == null) return;
    setState(() {
      routeBusy = true;
      quotedPrice = null;
    });
    try {
      final uri = Uri.parse('https://router.project-osrm.org/route/v1/driving/${a.lng},${a.lat};${b.lng},${b.lat}?overview=false&steps=false');
      final response = await http.get(uri);
      if (response.statusCode != 200) throw StateError('route_failed');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) throw StateError('route_missing');
      final route = Map<String, dynamic>.from(routes.first as Map);
      if (!mounted) return;
      setState(() {
        distanceKm = (route['distance'] as num).toDouble() / 1000;
        durationMin = ((route['duration'] as num).toDouble() / 60).ceil();
      });
    } catch (_) {
      final straight = const Distance().as(LengthUnit.Kilometer, a.point, b.point);
      if (!mounted) return;
      setState(() {
        distanceKm = straight * 1.25;
        durationMin = ((straight * 1.25) / 28 * 60).ceil();
      });
    } finally {
      if (mounted) setState(() => routeBusy = false);
    }
    await _loadQuote();
  }

  Future<void> _loadQuote() async {
    final km = distanceKm;
    final address = pickup?.displayName;
    if (km == null || address == null) return;
    setState(() {
      quoteBusy = true;
      quotedPrice = null;
    });
    try {
      final quote = await data.calculateDeliveryPrice(vehicleType: 'motorcycle', distanceKm: km, pickupAddress: address);
      final raw = quote['customer_total'];
      final price = raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}');
      if (price == null) throw StateError('price_missing');
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
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: navy))),
          for (final option in options)
            ListTile(title: Text(option), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.pop(context, option)),
          const SizedBox(height: 10),
        ]),
      ),
    );
    if (value != null) onSelected(value);
  }

  Future<void> _chooseCard() async {
    await _loadCards();
    if (!mounted) return;
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıtlı kart bulunamadı.')));
      setState(() => payment = 0);
      return;
    }
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('Kayıtlı Kartlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: navy))),
          for (final card in cards)
            ListTile(
              leading: const Icon(Icons.credit_card_rounded, color: orange),
              title: Text('${card['brand'] ?? 'Kart'} •••• ${card['last4'] ?? ''}'),
              trailing: selectedCardId == card['id'].toString() ? const Icon(Icons.check_circle_rounded, color: orange) : null,
              onTap: () => Navigator.pop(context, card['id'].toString()),
            ),
        ]),
      ),
    );
    if (id != null && mounted) setState(() => selectedCardId = id);
  }

  Future<void> _create() async {
    if (pickup == null) {
      await _pickAddress(true);
      return;
    }
    if (dropoff == null) {
      await _pickAddress(false);
      return;
    }
    if (!ready || creating) return;
    if (payment == 1 && selectedCardId == null) {
      await _chooseCard();
      return;
    }

    setState(() => creating = true);
    try {
      const packageTypes = ['package', 'document', 'other', 'other'];
      final created = await data.createShipment(
        vehicleType: 'motorcycle',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = (constraints.maxWidth / 390).clamp(.90, 1.10).toDouble();
            return Column(children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _header(context, s),
                    _steps(s),
                    Padding(
                      padding: EdgeInsets.fromLTRB(17 * s, 20 * s, 17 * s, 22 * s),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _addressBlock(s),
                        SizedBox(height: 14 * s),
                        _addressShortcuts(s),
                        SizedBox(height: 18 * s),
                        _sectionTitle('Gönderi Türü', 'Hangisini seçmeliyim?', s),
                        SizedBox(height: 10 * s),
                        _packageTypes(s),
                        SizedBox(height: 18 * s),
                        _sectionTitle('Paket Bilgileri', null, s),
                        SizedBox(height: 10 * s),
                        _packageInfo(s),
                        SizedBox(height: 18 * s),
                        _sectionTitle('Ödeme Yöntemi', null, s),
                        SizedBox(height: 10 * s),
                        _paymentMethods(s),
                        SizedBox(height: 14 * s),
                        _priceCard(s),
                        SizedBox(height: 14 * s),
                        _continueButton(s),
                      ]),
                    ),
                  ],
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, double s) {
    return SizedBox(
      height: 150 * s,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned.fill(child: Container(color: const Color(0xFFF9F8FC))),
        Positioned(right: -42 * s, top: -48 * s, width: 250 * s, height: 210 * s, child: Image.asset('assets/images/3d_kurye.png', fit: BoxFit.contain, alignment: Alignment.bottomRight)),
        Positioned(left: 17 * s, top: 16 * s, child: InkWell(onTap: () => Navigator.pop(context), borderRadius: BorderRadius.circular(16 * s), child: Container(width: 42 * s, height: 42 * s, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14 * s), boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 10)]), child: Icon(Icons.arrow_back_rounded, color: navy, size: 25 * s)))),
        Positioned(left: 17 * s, bottom: 17 * s, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Gönderi Oluştur', style: TextStyle(color: navy, fontSize: 24 * s, fontWeight: FontWeight.w900, letterSpacing: -.8)),
          SizedBox(height: 2 * s),
          Text('Hızlı, güvenli, kapınıza teslim.', style: TextStyle(color: muted, fontSize: 12.5 * s, fontWeight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  Widget _steps(double s) {
    return Container(
      height: 58 * s,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 17 * s),
      child: Row(children: [
        _step(1, 'Bilgiler', true, s),
        _stepLine(true, s),
        _step(2, 'Detaylar', false, s),
        _stepLine(false, s),
        _step(3, 'Onay', false, s),
      ]),
    );
  }

  Widget _step(int number, String label, bool active, double s) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 28 * s, height: 28 * s, alignment: Alignment.center, decoration: BoxDecoration(color: active ? orange : const Color(0xFFE7E7ED), shape: BoxShape.circle), child: Text('$number', style: TextStyle(color: active ? Colors.white : const Color(0xFFB6B5C0), fontSize: 12 * s, fontWeight: FontWeight.w800))),
    SizedBox(width: 7 * s),
    Text(label, style: TextStyle(color: active ? navy : muted, fontSize: 12.5 * s, fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
  ]);

  Widget _stepLine(bool active, double s) => Expanded(child: Container(height: 2 * s, margin: EdgeInsets.symmetric(horizontal: 8 * s), color: active ? orange : const Color(0xFFE9E8EE)));

  Widget _addressBlock(double s) {
    return Stack(children: [
      Column(children: [
        _addressCard(true, s),
        SizedBox(height: 8 * s),
        _addressCard(false, s),
      ]),
      Positioned(left: 22 * s, top: 49 * s, child: Container(width: 2, height: 24 * s, color: const Color(0xFFE0DEE8))),
    ]);
  }

  Widget _addressCard(bool isPickup, double s) {
    final value = isPickup ? pickup : dropoff;
    return InkWell(
      onTap: () => _pickAddress(isPickup),
      borderRadius: BorderRadius.circular(17 * s),
      child: Container(
        height: 66 * s,
        padding: EdgeInsets.symmetric(horizontal: 13 * s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17 * s), boxShadow: const [BoxShadow(color: Color(0x0B171052), blurRadius: 16, offset: Offset(0, 5))]),
        child: Row(children: [
          Container(width: 14 * s, height: 14 * s, decoration: BoxDecoration(color: isPickup ? orange : navy, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3 * s))),
          SizedBox(width: 15 * s),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isPickup ? 'Alım Adresi' : 'Teslimat Adresi', style: TextStyle(color: navy, fontSize: 13 * s, fontWeight: FontWeight.w900)),
            SizedBox(height: 3 * s),
            Text(value == null ? (isPickup ? 'Nereden alalım?' : 'Nereye bırakalım?') : value.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 11.5 * s, fontWeight: FontWeight.w500)),
          ])),
          Container(width: 38 * s, height: 38 * s, decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12 * s)), child: Icon(Icons.location_on_outlined, color: navy, size: 23 * s)),
        ]),
      ),
    );
  }

  Widget _addressShortcuts(double s) => Row(children: [
    Expanded(child: _shortcut(Icons.add_circle_outline_rounded, 'Ara durak ekle', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ara durak desteği sonraki adımda eklenecek.'))), s, true)),
    SizedBox(width: 9 * s),
    Expanded(child: _shortcut(Icons.bookmark_border_rounded, 'Adreslerimden seç', () => _pickAddress(true), s, false)),
  ]);

  Widget _shortcut(IconData icon, String label, VoidCallback onTap, double s, bool tinted) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14 * s), child: Container(height: 47 * s, alignment: Alignment.center, decoration: BoxDecoration(color: tinted ? const Color(0xFFF0ECFF) : Colors.white, borderRadius: BorderRadius.circular(14 * s)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: navy, size: 20 * s), SizedBox(width: 7 * s), Text(label, style: TextStyle(color: navy, fontSize: 11.5 * s, fontWeight: FontWeight.w700))])));

  Widget _sectionTitle(String title, String? trailing, double s) => Row(children: [
    Expanded(child: Text(title, style: TextStyle(color: navy, fontSize: 16 * s, fontWeight: FontWeight.w900))),
    if (trailing != null) ...[Text(trailing, style: TextStyle(color: muted, fontSize: 10.5 * s)), SizedBox(width: 3 * s), Icon(Icons.chevron_right_rounded, color: muted, size: 18 * s)],
  ]);

  Widget _packageTypes(double s) {
    final items = [
      (Icons.inventory_2_outlined, 'Paket', 'Küçük ve orta\nboyutlu gönderiler'),
      (Icons.description_outlined, 'Evrak', 'Zarf, dosya vb.'),
      (Icons.shopping_bag_outlined, 'Market', 'Market &\nmağaza alışverişi'),
      (Icons.card_giftcard_rounded, 'Hediye', 'Özel gün\ngönderileri'),
    ];
    return Row(children: [for (int i = 0; i < items.length; i++) ...[if (i > 0) SizedBox(width: 7 * s), Expanded(child: _packageCard(i, items[i].$1, items[i].$2, items[i].$3, s))]]);
  }

  Widget _packageCard(int index, IconData icon, String title, String subtitle, double s) {
    final active = package == index;
    return InkWell(
      onTap: () => setState(() => package = index),
      borderRadius: BorderRadius.circular(15 * s),
      child: Container(
        height: 96 * s,
        padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 10 * s),
        decoration: BoxDecoration(color: active ? const Color(0xFFFFF7F3) : Colors.white, borderRadius: BorderRadius.circular(15 * s), border: Border.all(color: active ? orange : Colors.transparent, width: 1.2), boxShadow: active ? null : const [BoxShadow(color: Color(0x08000000), blurRadius: 12)]),
        child: Stack(children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: active ? orange : navy, size: 25 * s),
            SizedBox(height: 8 * s),
            Text(title, style: TextStyle(color: navy, fontSize: 11.5 * s, fontWeight: FontWeight.w800)),
            SizedBox(height: 3 * s),
            Text(subtitle, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: muted, fontSize: 8.3 * s, height: 1.15)),
          ]),
          if (active) Positioned(right: 0, top: 0, child: Container(width: 17 * s, height: 17 * s, decoration: const BoxDecoration(color: orange, shape: BoxShape.circle), child: Icon(Icons.check_rounded, color: Colors.white, size: 12 * s))),
        ]),
      ),
    );
  }

  Widget _packageInfo(double s) => Row(children: [
    Expanded(child: _infoSelect(Icons.inventory_2_outlined, 'Ağırlık (kg)', weight, () => _choose('Ağırlık', ['1 kg', '2 kg', '3 kg', '5 kg', '10 kg', '20 kg+'], (v) => setState(() => weight = v)), s)),
    SizedBox(width: 8 * s),
    Expanded(child: _infoSelect(Icons.inventory_2_outlined, 'Boyut', size, () => _choose('Boyut', ['Çok Küçük', 'Küçük', 'Orta', 'Büyük', 'Çok Büyük'], (v) => setState(() => size = v)), s)),
    SizedBox(width: 8 * s),
    Expanded(child: Container(height: 62 * s, padding: EdgeInsets.symmetric(horizontal: 10 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14 * s)), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Icon(Icons.notes_rounded, color: navy, size: 20 * s), SizedBox(width: 7 * s), Expanded(child: TextField(controller: noteController, maxLines: 2, style: TextStyle(color: navy, fontSize: 10.5 * s, fontWeight: FontWeight.w600), decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Açıklama\n(op.)', hintStyle: TextStyle(color: muted, fontSize: 9 * s)) ))]))),
  ]);

  Widget _infoSelect(IconData icon, String label, String value, VoidCallback onTap, double s) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14 * s), child: Container(height: 62 * s, padding: EdgeInsets.symmetric(horizontal: 9 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14 * s)), child: Row(children: [Icon(icon, color: const Color(0xFF6A6880), size: 21 * s), SizedBox(width: 7 * s), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: muted, fontSize: 8.5 * s)), SizedBox(height: 3 * s), Text(value, style: TextStyle(color: navy, fontSize: 11.5 * s, fontWeight: FontWeight.w800))])), Icon(Icons.keyboard_arrow_down_rounded, color: navy, size: 18 * s)])));

  Widget _paymentMethods(double s) => Row(children: [
    Expanded(child: _paymentCard(0, Icons.account_balance_wallet_outlined, 'Nakit', 'Alıcı öder', s)),
    SizedBox(width: 9 * s),
    Expanded(child: _paymentCard(1, Icons.credit_card_rounded, 'Kart', 'Online öde', s)),
  ]);

  Widget _paymentCard(int index, IconData icon, String title, String subtitle, double s) {
    final active = payment == index;
    return InkWell(
      onTap: () async {
        setState(() => payment = index);
        if (index == 1) await _chooseCard();
      },
      borderRadius: BorderRadius.circular(15 * s),
      child: Container(
        height: 58 * s,
        padding: EdgeInsets.symmetric(horizontal: 13 * s),
        decoration: BoxDecoration(color: active ? const Color(0xFFFFF7F3) : Colors.white, borderRadius: BorderRadius.circular(15 * s), border: Border.all(color: active ? orange : Colors.transparent, width: 1.2)),
        child: Row(children: [
          Icon(icon, color: active ? orange : const Color(0xFF6F6D7E), size: 22 * s),
          SizedBox(width: 10 * s),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: navy, fontSize: 11.5 * s, fontWeight: FontWeight.w800)), Text(subtitle, style: TextStyle(color: muted, fontSize: 9 * s))])),
          if (active) Container(width: 18 * s, height: 18 * s, decoration: const BoxDecoration(color: orange, shape: BoxShape.circle), child: Icon(Icons.check_rounded, color: Colors.white, size: 13 * s)),
        ]),
      ),
    );
  }

  Widget _priceCard(double s) {
    final loading = routeBusy || quoteBusy;
    final value = loading ? 'Hesaplanıyor...' : quotedPrice == null ? 'Adresleri seçin' : '₺$quotedPrice';
    final detail = distanceKm == null ? 'Mesafeye göre hesaplanır.' : '${distanceKm!.toStringAsFixed(1)} km • ${durationMin ?? '-'} dk';
    return Container(
      height: 64 * s,
      padding: EdgeInsets.symmetric(horizontal: 14 * s),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15 * s)),
      child: Row(children: [
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('Tahmini Tutar', style: TextStyle(color: navy, fontSize: 10.5 * s, fontWeight: FontWeight.w600)), SizedBox(width: 5 * s), Icon(Icons.info_outline_rounded, color: navy, size: 14 * s)]),
          SizedBox(height: 3 * s),
          Text(value, style: TextStyle(color: navy, fontSize: quotedPrice == null ? 14 * s : 20 * s, fontWeight: FontWeight.w900)),
        ])),
        Text(detail, style: TextStyle(color: muted, fontSize: 9.5 * s)),
      ]),
    );
  }

  Widget _continueButton(double s) => SizedBox(
    height: 54 * s,
    width: double.infinity,
    child: FilledButton(
      onPressed: creating ? null : _create,
      style: FilledButton.styleFrom(backgroundColor: orange, disabledBackgroundColor: orange.withValues(alpha: .6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * s)), elevation: 0),
      child: creating
          ? SizedBox(width: 22 * s, height: 22 * s, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Devam Et', style: TextStyle(color: Colors.white, fontSize: 16 * s, fontWeight: FontWeight.w800)), SizedBox(width: 8 * s), Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22 * s)]),
    ),
  );
}
