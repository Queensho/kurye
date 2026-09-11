import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'customer_live_tracking_page.dart';
import 'data/app_data_service.dart';
import 'data/customer_delivery_extensions.dart';

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

  final data = AppDataService.instance;
  StreamSubscription<Map<String, dynamic>>? shipmentSub;
  Map<String, dynamic> shipment = {};
  String? shipmentId;
  bool openingCourier = false;
  bool loading = true;
  bool cancelling = false;
  bool detailsPrompted = false;
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
        shipmentId = rows.first['id']?.toString();
      }
      if (shipmentId == null || shipmentId!.isEmpty) {
        throw StateError('Gönderi kimliği bulunamadı.');
      }

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
      WidgetsBinding.instance.addPostFrameCallback((_) => _promptRecipientDetailsIfNeeded());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  void _listenShipment(String id) {
    shipmentSub?.cancel();
    shipmentSub = data.watchShipment(id).listen((row) {
      if (!mounted || row.isEmpty) return;
      setState(() => shipment = row);
      _maybeOpenCourier(row);
    });
  }

  void _maybeOpenCourier(Map<String, dynamic> row) {
    final courierId = row['courier_id']?.toString();
    final status = (row['status'] ?? '').toString();
    if (openingCourier || courierId == null || courierId.isEmpty || shipmentId == null) return;
    if (!{'accepted', 'at_pickup', 'picked_up', 'at_dropoff', 'delivered'}.contains(status)) return;
    openingCourier = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CustomerLiveTrackingPage(shipmentId: shipmentId!)),
      );
    });
  }

  Future<void> _promptRecipientDetailsIfNeeded() async {
    if (!mounted || detailsPrompted || shipmentId == null) return;
    if ((shipment['status'] ?? '') != 'searching') return;
    final currentName = (shipment['recipient_name'] ?? '').toString().trim();
    final currentPhone = (shipment['recipient_phone'] ?? '').toString().trim();
    if (currentName.isNotEmpty && currentPhone.isNotEmpty) return;
    detailsPrompted = true;

    final name = TextEditingController(text: currentName);
    final phone = TextEditingController(text: currentPhone);
    final pickupDetail = TextEditingController(text: (shipment['pickup_detail'] ?? '').toString());
    final dropoffDetail = TextEditingController(text: (shipment['dropoff_detail'] ?? '').toString());
    final doorNote = TextEditingController(text: (shipment['door_note'] ?? '').toString());

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(18, 6, 18, MediaQuery.of(context).viewInsets.bottom + 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alıcı ve adres detayları', style: TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('Kuryenin teslimatı sorunsuz tamamlaması için alıcı bilgilerini ekle.', style: TextStyle(color: muted)),
              const SizedBox(height: 16),
              TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Alıcı adı soyadı *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Alıcı telefonu *', hintText: '05xx xxx xx xx', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: pickupDetail, decoration: const InputDecoration(labelText: 'Alım: bina / kat / daire', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: dropoffDetail, decoration: const InputDecoration(labelText: 'Teslimat: bina / kat / daire', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: doorNote, maxLines: 2, decoration: const InputDecoration(labelText: 'Kapı / teslimat notu', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: orange, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    final digits = phone.text.replaceAll(RegExp(r'[^0-9]'), '');
                    if (name.text.trim().length < 2 || digits.length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alıcı adı ve geçerli telefon numarası gerekli.')));
                      return;
                    }
                    try {
                      await data.updateCustomerShipmentDetails(
                        shipmentId: shipmentId!,
                        recipientName: name.text.trim(),
                        recipientPhone: phone.text.trim(),
                        pickupDetail: pickupDetail.text.trim(),
                        dropoffDetail: dropoffDetail.text.trim(),
                        doorNote: doorNote.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bilgiler kaydedilemedi: $e')));
                    }
                  },
                  child: const Text('Bilgileri Kaydet', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 6),
              Center(child: TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Şimdilik geç'))),
            ],
          ),
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    pickupDetail.dispose();
    dropoffDetail.dispose();
    doorNote.dispose();
    if (saved == true && mounted) {
      final fresh = await data.client.from('shipments').select().eq('id', shipmentId!).single();
      if (mounted) setState(() => shipment = Map<String, dynamic>.from(fresh));
    }
  }

  Future<void> _cancelShipment() async {
    final id = shipmentId;
    if (id == null || cancelling) return;
    final reason = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gönderiyi iptal et?', style: TextStyle(fontWeight: FontWeight.w900, color: navy)),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'İptal nedeni (opsiyonel)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('İptal Et', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (approved != true || !mounted) {
      reason.dispose();
      return;
    }
    setState(() => cancelling = true);
    try {
      await data.cancelCustomerShipment(id, reason: reason.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gönderi iptal edilemedi: $e')));
    } finally {
      reason.dispose();
      if (mounted) setState(() => cancelling = false);
    }
  }

  @override
  void dispose() {
    shipmentSub?.cancel();
    super.dispose();
  }

  double? _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

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
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg, title: const Text('Kurye Aranıyor')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!))),
      );
    }

    final pickupLat = _num(shipment['pickup_lat']);
    final pickupLng = _num(shipment['pickup_lng']);
    final center = pickupLat != null && pickupLng != null ? LatLng(pickupLat, pickupLng) : const LatLng(41.0082, 28.9784);
    final recipientReady = (shipment['recipient_name'] ?? '').toString().trim().isNotEmpty && (shipment['recipient_phone'] ?? '').toString().trim().isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Kurye Aranıyor', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: orange)),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Gönderin kurye havuzunda', style: TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                const Text('Uygun online kuryeler gönderini gerçek zamanlı görüyor.', style: TextStyle(color: muted, fontSize: 11.5)),
                if (!recipientReady) ...[
                  const SizedBox(height: 6),
                  InkWell(onTap: _promptRecipientDetailsIfNeeded, child: const Text('Alıcı bilgilerini tamamla', style: TextStyle(color: orange, fontWeight: FontWeight.w800))),
                ],
              ])),
            ]),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 290,
              child: FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: pickupLat == null ? 11 : 13),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.queensho.kurye'),
                  if (pickupLat != null && pickupLng != null)
                    MarkerLayer(markers: [
                      Marker(point: center, width: 60, height: 60, child: const CircleAvatar(backgroundColor: orange, child: Icon(Icons.location_on_rounded, color: Colors.white))),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.inventory_2_outlined, color: navy),
                const SizedBox(width: 9),
                Expanded(child: Text((shipment['public_code'] ?? 'Gönderi').toString(), style: const TextStyle(color: navy, fontWeight: FontWeight.w900))),
                Text(_money(shipment['estimated_price']), style: const TextStyle(color: orange, fontSize: 19, fontWeight: FontWeight.w900)),
              ]),
              const Divider(height: 24),
              Text((shipment['pickup_address'] ?? '').toString(), style: const TextStyle(color: navy, fontWeight: FontWeight.w700)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Icon(Icons.arrow_downward_rounded, color: muted, size: 18)),
              Text((shipment['dropoff_address'] ?? '').toString(), style: const TextStyle(color: navy, fontWeight: FontWeight.w700)),
              if (recipientReady) ...[
                const SizedBox(height: 12),
                Text('Alıcı: ${shipment['recipient_name']} • ${shipment['recipient_phone']}', style: const TextStyle(color: muted, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: cancelling ? null : _cancelShipment,
            icon: cancelling ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.close_rounded),
            label: const Text('Gönderiyi İptal Et'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}
