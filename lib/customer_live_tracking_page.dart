import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'courier_search_page.dart';
import 'customer_route_overlay.dart';
import 'data/app_data_service.dart';
import 'data/customer_delivery_extensions.dart';
import 'shipment_chat_page.dart';

class CustomerLiveTrackingPage extends StatefulWidget {
  final String shipmentId;
  const CustomerLiveTrackingPage({super.key, required this.shipmentId});

  @override
  State<CustomerLiveTrackingPage> createState() => _CustomerLiveTrackingPageState();
}

class _CustomerLiveTrackingPageState extends State<CustomerLiveTrackingPage> {
  static const navy = Color(0xFF171052);
  static const muted = Color(0xFF7D8191);
  static const green = Color(0xFF18B86A);
  static const orange = Color(0xFFFF5A1F);
  static const softOrange = Color(0xFFFFF3EC);
  static const bg = Color(0xFFF7F8FC);

  final data = AppDataService.instance;
  final MapController mapController = MapController();
  Map<String, dynamic>? courierInfo;
  String? loadedCourierId;
  bool loadingCourier = false;
  bool actionBusy = false;
  int? routeEtaMin;
  double? routeDistanceKm;

  void _updateRouteEta(int? eta, double? km) {
    final sameEta = routeEtaMin == eta;
    final sameKm = (routeDistanceKm == null && km == null) ||
        (routeDistanceKm != null && km != null && (routeDistanceKm! - km).abs() < .05);
    if (!mounted || (sameEta && sameKm)) return;
    setState(() {
      routeEtaMin = eta;
      routeDistanceKm = km;
    });
  }

  String _statusTitle(String status) => switch (status) {
        'accepted' => 'Kurye bulundu!',
        'at_pickup' => 'Kurye bulundu!',
        'picked_up' => 'Gönderin yolda!',
        'at_dropoff' => 'Kurye bulundu!',
        'delivered' => 'Teslim edildi!',
        'cancelled' => 'Gönderi iptal edildi',
        _ => 'Kurye bulundu!',
      };

  String _statusSubtitle(String status) => switch (status) {
        'accepted' => 'Alım noktasına geliyor',
        'at_pickup' => 'Alım noktasında',
        'picked_up' => 'Teslimat noktasına geliyor',
        'at_dropoff' => 'Teslimat noktasında',
        'delivered' => 'Gönderi tamamlandı',
        'cancelled' => 'Bu gönderi artık aktif değil',
        _ => 'Kurye hazırlanıyor',
      };

  String _mapBadge(String status) => switch (status) {
        'accepted' => 'Alım noktasına geliyor',
        'at_pickup' => 'Alım noktasında',
        'picked_up' => 'Yolda',
        'at_dropoff' => 'Teslimat noktasında',
        'delivered' => 'Teslim edildi',
        'cancelled' => 'İptal edildi',
        _ => 'Kurye bulundu',
      };

  Future<void> _ensureCourierInfo(String courierId) async {
    if (loadingCourier || loadedCourierId == courierId) return;
    loadingCourier = true;
    try {
      final raw = await data.client.rpc(
        'get_assigned_courier_for_shipment',
        params: {'p_shipment_id': widget.shipmentId},
      );
      if (!mounted) return;
      setState(() {
        courierInfo = raw == null ? null : Map<String, dynamic>.from(raw as Map);
        loadedCourierId = courierId;
      });
    } catch (_) {
      // Realtime shipment/courier streams keep the page usable if the profile RPC is late.
    } finally {
      loadingCourier = false;
    }
  }

  Future<void> _call(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefon uygulaması açılamadı.')),
      );
    }
  }

  void _chat(String courierName) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ShipmentChatPage(
        shipmentId: widget.shipmentId,
        title: courierName,
      ),
    ));
  }

  Future<void> _support() async {
    String category = 'courier_missing';
    final description = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Sorun bildir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Konu'),
                items: const [
                  DropdownMenuItem(value: 'courier_missing', child: Text('Kurye gelmedi')),
                  DropdownMenuItem(value: 'damaged_package', child: Text('Paket hasarlı')),
                  DropdownMenuItem(value: 'wrong_delivery', child: Text('Yanlış teslimat')),
                  DropdownMenuItem(value: 'pricing', child: Text('Ücret sorunu')),
                  DropdownMenuItem(value: 'other', child: Text('Diğer')),
                ],
                onChanged: (v) => setLocal(() => category = v ?? category),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 4,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Açıklama'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Gönder')),
          ],
        ),
      ),
    );
    if (send != true || !mounted) {
      description.dispose();
      return;
    }
    setState(() => actionBusy = true);
    try {
      await data.createSupportTicket(
        shipmentId: widget.shipmentId,
        category: category,
        description: description.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Destek kaydın oluşturuldu.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Destek kaydı oluşturulamadı: $e')));
    } finally {
      description.dispose();
      if (mounted) setState(() => actionBusy = false);
    }
  }

  Future<void> _rateShipment() async {
    var rating = 5;
    final comment = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Teslimatı değerlendir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final value = i + 1;
                  return IconButton(
                    onPressed: () => setLocal(() => rating = value),
                    icon: Icon(value <= rating ? Icons.star_rounded : Icons.star_border_rounded, color: const Color(0xFFFFB020), size: 34),
                  );
                }),
              ),
              TextField(controller: comment, maxLines: 3, decoration: const InputDecoration(labelText: 'Yorum', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Gönder')),
          ],
        ),
      ),
    );
    if (result != true || !mounted) {
      comment.dispose();
      return;
    }
    setState(() => actionBusy = true);
    try {
      await data.submitShipmentRating(widget.shipmentId, rating: rating, comment: comment.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Değerlendirmen kaydedildi.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Değerlendirme kaydedilemedi: $e')));
    } finally {
      comment.dispose();
      if (mounted) setState(() => actionBusy = false);
    }
  }

  Future<void> _repeat() async {
    if (actionBusy) return;
    setState(() => actionBusy = true);
    try {
      final created = await data.repeatCustomerShipment(widget.shipmentId);
      final id = created['id']?.toString();
      if (id == null || id.isEmpty) throw StateError('Yeni gönderi oluşturulamadı.');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CourierSearchPage(shipmentId: id)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tekrar gönderilemedi: $e')));
    } finally {
      if (mounted) setState(() => actionBusy = false);
    }
  }

  bool _isStale(dynamic raw) {
    final seen = DateTime.tryParse('${raw ?? ''}')?.toUtc();
    if (seen == null) return true;
    return DateTime.now().toUtc().difference(seen) > const Duration(minutes: 3);
  }

  String _vehicleLabel(dynamic value) {
    final v = '${value ?? ''}'.toLowerCase();
    if (v.contains('motor')) return 'Motosiklet';
    if (v.contains('car') || v.contains('otomobil')) return 'Otomobil';
    if (v.contains('van') || v.contains('panel')) return 'Panelvan';
    return 'Motosiklet';
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
    return StreamBuilder<Map<String, dynamic>>(
      stream: data.watchShipment(widget.shipmentId),
      builder: (context, shipmentSnapshot) {
        if (!shipmentSnapshot.hasData) {
          return const Scaffold(backgroundColor: bg, body: Center(child: CircularProgressIndicator(color: orange)));
        }
        final shipment = shipmentSnapshot.data!;
        final courierId = shipment['courier_id']?.toString();
        final status = (shipment['status'] ?? 'searching').toString();
        final pickupLat = (shipment['pickup_lat'] as num?)?.toDouble();
        final pickupLng = (shipment['pickup_lng'] as num?)?.toDouble();
        final dropLat = (shipment['dropoff_lat'] as num?)?.toDouble();
        final dropLng = (shipment['dropoff_lng'] as num?)?.toDouble();

        if (courierId == null || courierId.isEmpty) {
          final center = pickupLat != null && pickupLng != null ? LatLng(pickupLat, pickupLng) : const LatLng(41.0082, 28.9784);
          return _screen(
            shipment: shipment,
            status: status,
            center: center,
            courier: const <String, dynamic>{},
            courierPoint: null,
            pickupPoint: pickupLat != null && pickupLng != null ? LatLng(pickupLat, pickupLng) : null,
            dropPoint: dropLat != null && dropLng != null ? LatLng(dropLat, dropLng) : null,
          );
        }

        unawaited(_ensureCourierInfo(courierId));
        return StreamBuilder<Map<String, dynamic>>(
          stream: data.watchCourierLocation(courierId),
          builder: (context, courierSnapshot) {
            final courier = courierSnapshot.data ?? const <String, dynamic>{};
            final lat = (courier['latitude'] as num?)?.toDouble();
            final lng = (courier['longitude'] as num?)?.toDouble();
            final courierPoint = lat != null && lng != null ? LatLng(lat, lng) : null;
            final pickupPoint = pickupLat != null && pickupLng != null ? LatLng(pickupLat, pickupLng) : null;
            final dropPoint = dropLat != null && dropLng != null ? LatLng(dropLat, dropLng) : null;
            final center = courierPoint ?? pickupPoint ?? const LatLng(41.0082, 28.9784);
            return _screen(
              shipment: shipment,
              status: status,
              center: center,
              courier: courier,
              courierPoint: courierPoint,
              pickupPoint: pickupPoint,
              dropPoint: dropPoint,
            );
          },
        );
      },
    );
  }

  Widget _screen({
    required Map<String, dynamic> shipment,
    required String status,
    required LatLng center,
    required Map<String, dynamic> courier,
    required LatLng? courierPoint,
    required LatLng? pickupPoint,
    required LatLng? dropPoint,
  }) {
    final info = courierInfo ?? const <String, dynamic>{};
    final courierName = (info['full_name'] ?? info['name'] ?? 'Kurye').toString();
    final phone = (info['phone'] ?? '').toString();
    final avatarUrl = (info['avatar_url'] ?? '').toString();
    final plate = (info['plate_number'] ?? info['plate'] ?? '').toString();
    final rating = (info['rating_average'] as num?)?.toDouble() ?? 0;
    final ratingCount = (info['rating_count'] as num?)?.toInt() ?? 0;
    final vehicle = _vehicleLabel(info['vehicle_type'] ?? courier['vehicle_type']);
    final stale = _isStale(courier['last_seen_at'] ?? info['last_seen_at']);
    final routeTarget = (status == 'picked_up' || status == 'at_dropoff') ? dropPoint : pickupPoint;
    final code = (shipment['public_code'] ?? 'Gönderi').toString();
    final delivered = status == 'delivered';
    final cancelled = status == 'cancelled';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _orangeHeader(status),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _mapCard(
                      status: status,
                      center: center,
                      courierPoint: courierPoint,
                      pickupPoint: pickupPoint,
                      dropPoint: dropPoint,
                      routeTarget: routeTarget,
                      stale: stale,
                    ),
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child: _detailsSheet(
                        shipment: shipment,
                        code: code,
                        courierName: courierName,
                        phone: phone,
                        avatarUrl: avatarUrl,
                        plate: plate,
                        vehicle: vehicle,
                        rating: rating,
                        ratingCount: ratingCount,
                        stale: stale,
                        delivered: delivered,
                        cancelled: cancelled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orangeHeader(String status) {
    return Container(
      height: 138,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFFF5A1F), Color(0xFFFF7700)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            top: 30,
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .23), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 23),
              ),
            ),
          ),
          Positioned(
            left: 78,
            top: 29,
            right: 142,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_statusTitle(status), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.05)),
              const SizedBox(height: 5),
              Text(_statusSubtitle(status), style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
          ),
          Positioned(
            right: 12,
            bottom: -2,
            width: 148,
            height: 128,
            child: Image.asset('assets/images/kurye_header_hd.png', fit: BoxFit.contain, alignment: Alignment.bottomCenter),
          ),
          Positioned(
            right: 10,
            top: 34,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: const Text('Yola\nçıkıyorum! 🚀', textAlign: TextAlign.center, style: TextStyle(color: navy, fontSize: 11.5, height: 1.25, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapCard({
    required String status,
    required LatLng center,
    required LatLng? courierPoint,
    required LatLng? pickupPoint,
    required LatLng? dropPoint,
    required LatLng? routeTarget,
    required bool stale,
  }) {
    return SizedBox(
      height: 330,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(initialCenter: center, initialZoom: 14.2),
                children: [
                  TileLayer(urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', userAgentPackageName: 'com.queensho.kurye'),
                  CustomerRouteOverlay(courierPoint: stale ? null : courierPoint, targetPoint: routeTarget, onEtaChanged: _updateRouteEta),
                  MarkerLayer(markers: [
                    if (pickupPoint != null)
                      Marker(point: pickupPoint, width: 34, height: 34, child: const CircleAvatar(backgroundColor: orange, child: Icon(Icons.circle, color: Colors.white, size: 9))),
                    if (dropPoint != null)
                      Marker(point: dropPoint, width: 36, height: 36, child: const CircleAvatar(backgroundColor: navy, child: Icon(Icons.flag_rounded, color: Colors.white, size: 18))),
                    if (courierPoint != null)
                      Marker(
                        point: courierPoint,
                        width: 94,
                        height: 94,
                        child: Container(
                          decoration: BoxDecoration(color: orange.withValues(alpha: .16), shape: BoxShape.circle),
                          padding: const EdgeInsets.all(13),
                          child: Container(
                            decoration: BoxDecoration(color: orange.withValues(alpha: .12), shape: BoxShape.circle),
                            padding: const EdgeInsets.all(7),
                            child: ClipOval(child: Image.asset('assets/images/motosiklet_hd.png', fit: BoxFit.contain)),
                          ),
                        ),
                      ),
                  ]),
                ],
              ),
            ),
            if (courierPoint != null)
              Positioned(
                left: 0,
                right: 0,
                top: 86,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(13), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12)]),
                    child: Text(_mapBadge(status), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ),
            Positioned(
              right: 14,
              top: 24,
              child: Column(
                children: [
                  _mapButton(Icons.my_location_rounded, () => courierPoint == null ? null : mapController.move(courierPoint, 15.3)),
                  const SizedBox(height: 9),
                  _mapButton(Icons.map_outlined, () {}),
                  const SizedBox(height: 9),
                  _mapButton(Icons.navigation_rounded, () => courierPoint == null ? null : mapController.move(courierPoint, 16)),
                ],
              ),
            ),
            if (routeEtaMin != null && routeTarget != null)
              Positioned(
                left: 18,
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 14)]),
                  child: Text('${routeEtaMin} dk${routeDistanceKm == null ? '' : ' • ${routeDistanceKm!.toStringAsFixed(1)} km'}', style: const TextStyle(color: navy, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 48, height: 48, child: Icon(icon, color: orange, size: 24)),
      ),
    );
  }

  Widget _detailsSheet({
    required Map<String, dynamic> shipment,
    required String code,
    required String courierName,
    required String phone,
    required String avatarUrl,
    required String plate,
    required String vehicle,
    required double rating,
    required int ratingCount,
    required bool stale,
    required bool delivered,
    required bool cancelled,
  }) {
    final ratingText = ratingCount == 0 ? 'Yeni kurye' : '${rating.toStringAsFixed(1)} ($ratingCount teslimat)';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 54, height: 5, decoration: BoxDecoration(color: const Color(0xFFD7D8E0), borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFFFE7D8),
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty ? ClipOval(child: Image.asset('assets/images/Profil3d.png', width: 64, height: 64, fit: BoxFit.cover)) : null,
                  ),
                  Positioned(right: -1, bottom: 2, child: Container(width: 17, height: 17, decoration: BoxDecoration(color: green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)))),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(courierName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text('$vehicle${plate.isEmpty ? '' : ' • $plate'}', style: const TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFA600), size: 20),
                    const SizedBox(width: 4),
                    Text(ratingText, style: const TextStyle(color: navy, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ]),
                ]),
              ),
              _roundAction(Icons.chat_bubble_rounded, const Color(0xFFFFEFE7), orange, () => _chat(courierName)),
              const SizedBox(width: 10),
              _roundAction(Icons.phone_rounded, orange, Colors.white, phone.isEmpty ? null : () => _call(phone)),
            ],
          ),
          const SizedBox(height: 20),
          _infoRow(Icons.inventory_2_outlined, 'Gönderi', code, copyIcon: true),
          _infoRow(Icons.location_on_rounded, 'Alım', (shipment['pickup_address'] ?? '').toString()),
          _infoRow(Icons.flag_rounded, 'Teslimat', (shipment['dropoff_address'] ?? '').toString()),
          _infoRow(Icons.payments_rounded, 'Ücret', _money(shipment['estimated_price'])),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: stale ? const Color(0xFFFFF3E8) : const Color(0xFFEAFBF1), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(stale ? Icons.wifi_off_rounded : Icons.access_time_rounded, color: stale ? orange : green),
              const SizedBox(width: 11),
              Expanded(child: Text(stale ? 'Kurye bağlantısı zayıf. Son konum gösteriliyor.' : 'Kurye konumu gerçek zamanlı güncellenir.', style: TextStyle(color: stale ? orange : green, fontSize: 12.5, fontWeight: FontWeight.w700))),
            ]),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: actionBusy ? null : _support,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(color: softOrange, borderRadius: BorderRadius.circular(15)),
              child: const Row(children: [
                CircleAvatar(backgroundColor: orange, foregroundColor: Colors.white, radius: 20, child: Icon(Icons.chat_rounded, size: 21)),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Kurye ile iletişimde kalın', style: TextStyle(color: orange, fontSize: 15, fontWeight: FontWeight.w900)),
                  SizedBox(height: 2),
                  Text('Herhangi bir sorun olursa kurye ile mesajlaşabilirsiniz.', style: TextStyle(color: muted, fontSize: 12.5)),
                ])),
                Icon(Icons.chevron_right_rounded, color: orange, size: 28),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          if (!delivered && !cancelled)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _chat(courierName),
                style: FilledButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 23),
                label: const Text('Kuryeye Mesaj Gönder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          if (delivered)
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: actionBusy ? null : _rateShipment, icon: const Icon(Icons.star_rounded), label: const Text('Puanla'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: actionBusy ? null : _repeat, icon: const Icon(Icons.refresh_rounded), label: const Text('Tekrar Gönder'))),
            ]),
          if (cancelled)
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: actionBusy ? null : _repeat, icon: const Icon(Icons.refresh_rounded), label: const Text('Tekrar Gönder'))),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _roundAction(IconData icon, Color background, Color foreground, VoidCallback? onTap) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 58, height: 58, child: Icon(icon, color: foreground, size: 27)),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool copyIcon = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 31, child: Icon(icon, color: const Color(0xFF59647C), size: 23)),
        const SizedBox(width: 8),
        SizedBox(width: 82, child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(label, style: const TextStyle(color: muted, fontSize: 14, fontWeight: FontWeight.w600)))),
        Expanded(child: Text(value, style: const TextStyle(color: navy, fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.35))),
        if (copyIcon) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.copy_rounded, color: Color(0xFF677188), size: 20)),
      ]),
    );
  }
}
