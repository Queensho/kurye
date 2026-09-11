import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'customer_assigned_courier_page.dart';
import 'data/app_data_service.dart';

class CourierSearchPage extends StatefulWidget {
  const CourierSearchPage({super.key, this.shipmentId});

  final String? shipmentId;

  @override
  State<CourierSearchPage> createState() => _CourierSearchPageState();
}

class _CourierSearchPageState extends State<CourierSearchPage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF171052);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);
  static const soft = Color(0xFFF3F1FA);

  final data = AppDataService.instance;
  StreamSubscription<Map<String, dynamic>>? shipmentSub;
  Map<String, dynamic> shipment = {};
  String? shipmentId;
  bool openingCourier = false;
  bool loading = true;
  bool cancelling = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _resolveShipment();
  }

  Future<void> _resolveShipment() async {
    try {
      shipmentId = widget.shipmentId;
      if (shipmentId == null || shipmentId!.isEmpty) {
        final rows = await data.client
            .from('shipments')
            .select()
            .eq('user_id', data.userId)
            .order('created_at', ascending: false)
            .limit(1);
        if (rows.isEmpty) throw StateError('Aktif gönderi bulunamadı.');
        final latest = Map<String, dynamic>.from(rows.first);
        shipmentId = latest['id']?.toString();
        shipment = latest;
      }
      if (shipmentId == null || shipmentId!.isEmpty) throw StateError('Gönderi kimliği bulunamadı.');

      final fresh = await data.client
          .from('shipments')
          .select()
          .eq('id', shipmentId!)
          .eq('user_id', data.userId)
          .single();
      shipment = Map<String, dynamic>.from(fresh);

      if (!mounted) return;
      setState(() => loading = false);
      _listenShipment(shipmentId!);
      _maybeOpenCourier(shipment);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  void _listenShipment(String id) {
    shipmentSub = data.watchShipment(id).listen((row) {
      if (!mounted || row.isEmpty) return;
      setState(() => shipment = row);
      _maybeOpenCourier(row);
    });
  }

  void _maybeOpenCourier(Map<String, dynamic> row) {
    final courierId = row['courier_id']?.toString();
    if (openingCourier || courierId == null || courierId.isEmpty || shipmentId == null) return;
    openingCourier = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CustomerAssignedCourierPage(shipmentId: shipmentId!)),
      );
    });
  }

  Future<void> _cancelShipment() async {
    final id = shipmentId;
    if (id == null || cancelling) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gönderiyi iptal et?', style: TextStyle(fontWeight: FontWeight.w900, color: navy)),
        content: const Text('Henüz kurye işi almadan bu gönderiyi iptal etmek istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('İptal Et', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => cancelling = true);
    try {
      await data.client
          .from('shipments')
          .update({'status': 'cancelled'})
          .eq('id', id)
          .eq('user_id', data.userId)
          .isFilter('courier_id', null)
          .eq('status', 'searching');
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gönderi iptal edilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => cancelling = false);
    }
  }

  @override
  void dispose() {
    shipmentSub?.cancel();
    super.dispose();
  }

  double? _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

  String _shortType(String raw) {
    switch (raw) {
      case 'document': return 'Evrak';
      case 'food': return 'Market';
      case 'other': return 'Gönderi';
      default: return 'Paket';
    }
  }

  String _subtitleType(String raw) {
    switch (raw) {
      case 'document': return 'Zarf, dosya ve evrak gönderisi';
      case 'food': return 'Market ve mağaza gönderisi';
      case 'other': return 'Özel gönderi';
      default: return 'Küçük ve orta boyutlu gönderi';
    }
  }

  String _money(dynamic value) {
    if (value is num) {
      final d = value.toDouble();
      return d == d.roundToDouble() ? '₺${d.toInt()}' : '₺${d.toStringAsFixed(2)}';
    }
    return value == null ? '—' : '₺$value';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: bg, body: Center(child: CircularProgressIndicator(color: orange)));
    if (error != null) {
      return Scaffold(backgroundColor: bg, appBar: AppBar(backgroundColor: bg, title: const Text('Kurye Aranıyor')), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!))));
    }
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = (constraints.maxWidth / 390).clamp(.90, 1.10).toDouble();
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _hero(context, s),
                Transform.translate(offset: Offset(0, -2 * s), child: _progressCard(s)),
                Padding(
                  padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 26 * s),
                  child: Column(children: [
                    _mapCard(s),
                    SizedBox(height: 12 * s),
                    _shipmentCard(s),
                    SizedBox(height: 10 * s),
                    _addressCard(s),
                    SizedBox(height: 12 * s),
                    _cancelButton(s),
                    SizedBox(height: 14 * s),
                    _securityCard(s),
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, double s) {
    return SizedBox(
      height: 184 * s,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned.fill(child: Container(color: const Color(0xFFF9F8FC))),
        Positioned(right: -72 * s, top: -64 * s, width: 300 * s, height: 260 * s, child: Image.asset('assets/images/3d_kurye.png', fit: BoxFit.contain, alignment: Alignment.bottomRight, filterQuality: FilterQuality.high)),
        Positioned(left: 17 * s, top: 16 * s, child: InkWell(onTap: () => Navigator.of(context).pop(), borderRadius: BorderRadius.circular(14 * s), child: Container(width: 42 * s, height: 42 * s, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14 * s), boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 10)]), child: Icon(Icons.arrow_back_rounded, color: navy, size: 25 * s)))),
        Positioned(left: 22 * s, bottom: 24 * s, width: 175 * s, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Kurye\nAranıyor', style: TextStyle(color: navy, fontSize: 31 * s, height: .95, fontWeight: FontWeight.w900, letterSpacing: -1.1)), SizedBox(height: 8 * s), Text('Sana en yakın ve uygun kuryeler\nkontrol ediliyor.', style: TextStyle(color: muted, fontSize: 11.5 * s, height: 1.3, fontWeight: FontWeight.w500))])),
      ]),
    );
  }

  Widget _progressCard(double s) {
    return Container(
      height: 72 * s,
      margin: EdgeInsets.symmetric(horizontal: 13 * s),
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s), boxShadow: const [BoxShadow(color: Color(0x0A171052), blurRadius: 16, offset: Offset(0, 5))]),
      child: Row(children: [
        SizedBox(width: 26 * s, height: 26 * s, child: CircularProgressIndicator(strokeWidth: 3 * s, color: orange)),
        SizedBox(width: 12 * s),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Kurye aranıyor', style: TextStyle(color: navy, fontSize: 13 * s, fontWeight: FontWeight.w900)),
          SizedBox(height: 3 * s),
          Text('Gönderin uygun online kuryelerin havuzunda.', style: TextStyle(color: muted, fontSize: 10 * s, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }

  Widget _mapCard(double s) {
    final pickupLat = _num(shipment['pickup_lat']);
    final pickupLng = _num(shipment['pickup_lng']);
    final center = pickupLat != null && pickupLng != null ? LatLng(pickupLat, pickupLng) : const LatLng(41.0082, 28.9784);
    const testMessages = ['Kurye aranıyor...', 'Kurye bulundu.', 'Kurye yola çıkıyor.', 'Teslimat aşaması test ediliyor.'];
    return ClipRRect(
      borderRadius: BorderRadius.circular(18 * s),
      child: SizedBox(
        height: 294 * s,
        child: Stack(children: [
          Positioned.fill(child: FlutterMap(options: MapOptions(initialCenter: center, initialZoom: pickupLat == null ? 11 : 12.7, minZoom: 5, maxZoom: 18, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.queensho.kurye'), if (pickupLat != null && pickupLng != null) MarkerLayer(markers: [Marker(point: center, width: 84 * s, height: 84 * s, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: orange.withValues(alpha: .14)), alignment: Alignment.center, child: Container(width: 56 * s, height: 56 * s, decoration: BoxDecoration(shape: BoxShape.circle, color: orange.withValues(alpha: .22)), alignment: Alignment.center, child: Container(width: 31 * s, height: 31 * s, decoration: const BoxDecoration(shape: BoxShape.circle, color: orange), child: Icon(Icons.location_on_rounded, color: Colors.white, size: 19 * s)))))] )])),
          Positioned(left: 0, right: 0, bottom: 12 * s, child: Center(child: Container(padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 12)]), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 19 * s, height: 19 * s, decoration: const BoxDecoration(color: orange, shape: BoxShape.circle), child: Icon(Icons.bolt_rounded, color: Colors.white, size: 13 * s)), SizedBox(width: 7 * s), Text(testMessages[testStage], style: TextStyle(color: navy, fontSize: 8.8 * s, fontWeight: FontWeight.w700))])))),
          Positioned(right: 10 * s, top: 10 * s, child: Container(width: 42 * s, padding: EdgeInsets.symmetric(vertical: 5 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13 * s), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10)]), child: Column(children: [Icon(Icons.my_location_rounded, color: navy, size: 20 * s), SizedBox(height: 10 * s), Icon(Icons.layers_outlined, color: navy, size: 20 * s), SizedBox(height: 10 * s), Icon(Icons.navigation_rounded, color: navy, size: 20 * s)]))),
        ]),
      ),
    );
  }

  Widget _shipmentCard(double s) {
    final rawType = shipment['package_type']?.toString() ?? 'package';
    return Container(height: 66 * s, padding: EdgeInsets.symmetric(horizontal: 14 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16 * s)), child: Row(children: [
      Container(width: 42 * s, height: 42 * s, decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(13 * s)), child: Icon(Icons.inventory_2_outlined, color: navy, size: 25 * s)), SizedBox(width: 11 * s),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_shortType(rawType), style: TextStyle(color: navy, fontSize: 13 * s, fontWeight: FontWeight.w900)), SizedBox(height: 2 * s), Text(_subtitleType(rawType), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 9.5 * s))])),
      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(_money(shipment['estimated_price']), style: TextStyle(color: orange, fontSize: 20 * s, fontWeight: FontWeight.w900)), Text('Tahmini tutar', style: TextStyle(color: muted, fontSize: 8.5 * s))]),
    ]));
  }

  Widget _addressCard(double s) {
    final pickup = (shipment['pickup_address']?.toString().trim().isNotEmpty ?? false) ? shipment['pickup_address'].toString() : 'Adres yüklenemedi';
    final dropoff = (shipment['dropoff_address']?.toString().trim().isNotEmpty ?? false) ? shipment['dropoff_address'].toString() : 'Adres yüklenemedi';
    return Container(
      padding: EdgeInsets.fromLTRB(15 * s, 13 * s, 15 * s, 13 * s),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16 * s)),
      child: Stack(children: [
        Positioned(left: 6.5 * s, top: 19 * s, child: Container(width: 2, height: 39 * s, color: const Color(0xFFD8D5E5))),
        Column(children: [_addressRow(true, 'Alım Adresi', pickup, s), SizedBox(height: 13 * s), _addressRow(false, 'Teslimat Adresi', dropoff, s)]),
      ]),
    );
  }

  Widget _addressRow(bool pickup, String title, String value, double s) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 14 * s, height: 14 * s, margin: EdgeInsets.only(top: 2 * s), decoration: BoxDecoration(color: pickup ? orange : navy, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3 * s))), SizedBox(width: 12 * s), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: navy, fontSize: 11.5 * s, fontWeight: FontWeight.w900)), SizedBox(height: 2 * s), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 9.5 * s, height: 1.2))]))]);

  Widget _cancelButton(double s) => SizedBox(width: double.infinity, height: 50 * s, child: OutlinedButton(onPressed: cancelling ? null : _cancelShipment, style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFF5E5E)), foregroundColor: const Color(0xFFFF4D4D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14 * s))), child: cancelling ? SizedBox(width: 20 * s, height: 20 * s, child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF4D4D))) : Text('İptal Et', style: TextStyle(fontSize: 13 * s, fontWeight: FontWeight.w900))));

  Widget _securityCard(double s) => Container(padding: EdgeInsets.all(13 * s), decoration: BoxDecoration(color: const Color(0xFFF2EFFF), borderRadius: BorderRadius.circular(15 * s)), child: Row(children: [Container(width: 38 * s, height: 38 * s, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .65), borderRadius: BorderRadius.circular(12 * s)), child: Icon(Icons.shield_outlined, color: navy, size: 23 * s)), SizedBox(width: 11 * s), Expanded(child: Text('Test modunda aşamalar otomatik ilerliyor. Gerçek kurye işi aldığında gerçek akış devralır.', style: TextStyle(color: muted, fontSize: 10.5 * s, height: 1.35, fontWeight: FontWeight.w600)))]));
}
