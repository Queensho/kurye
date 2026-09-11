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
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF718198);
  static const green = Color(0xFF13A66A);
  static const orange = Color(0xFFFF5A1F);

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

  String _label(String status) => switch (status) {
        'searching' => 'Kurye aranıyor',
        'accepted' => 'Kurye alım noktasına gidiyor',
        'at_pickup' => 'Kurye alım noktasında',
        'picked_up' => 'Gönderin yolda',
        'at_dropoff' => 'Kurye teslimat noktasında',
        'delivered' => 'Teslim edildi',
        'cancelled' => 'Gönderi iptal edildi',
        _ => 'Gönderi takip ediliyor',
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
      // Shipment/courier realtime streams keep the main tracking experience alive.
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

  Future<void> _cancelShipment(String status) async {
    final controller = TextEditingController();
    final fee = status == 'accepted' ? 20 : 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gönderiyi iptal et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status == 'accepted'
                ? 'Kurye işi aldığı için ₺20 iptal bedeli kaydedilir. Ödeme sistemi bağlanana kadar bu tutar otomatik tahsil edilmez.'
                : 'Kurye henüz işi almadığı için iptal ücretsiz.'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'İptal nedeni (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(fee > 0 ? '₺$fee ile İptal Et' : 'İptal Et'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      controller.dispose();
      return;
    }
    setState(() => actionBusy = true);
    try {
      await data.cancelCustomerShipment(widget.shipmentId, reason: controller.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gönderi iptal edildi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İptal edilemedi: $e')),
        );
      }
    } finally {
      controller.dispose();
      if (mounted) setState(() => actionBusy = false);
    }
  }

  Future<void> _rateShipment() async {
    var rating = 5;
    final comment = TextEditingController();
    String? problem;
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
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    onPressed: () => setLocal(() => rating = value),
                    icon: Icon(
                      value <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFFB020),
                      size: 34,
                    ),
                  );
                }),
              ),
              TextField(
                controller: comment,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Yorum (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: problem,
                decoration: const InputDecoration(
                  labelText: 'Problem bildir (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'late', child: Text('Geç teslimat')),
                  DropdownMenuItem(value: 'damaged', child: Text('Paket hasarlı')),
                  DropdownMenuItem(value: 'communication', child: Text('İletişim sorunu')),
                  DropdownMenuItem(value: 'other', child: Text('Diğer')),
                ],
                onChanged: (v) => setLocal(() => problem = v),
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
    if (result != true || !mounted) {
      comment.dispose();
      return;
    }
    setState(() => actionBusy = true);
    try {
      await data.submitShipmentRating(
        widget.shipmentId,
        rating: rating,
        comment: comment.text.trim(),
        problemReason: problem,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değerlendirmen kaydedildi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Değerlendirme kaydedilemedi: $e')),
        );
      }
    } finally {
      comment.dispose();
      if (mounted) setState(() => actionBusy = false);
    }
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
                value: category,
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Açıklama',
                ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destek kaydın oluşturuldu.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Destek kaydı oluşturulamadı: $e')),
        );
      }
    } finally {
      description.dispose();
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
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => CourierSearchPage(shipmentId: id),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tekrar gönderilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => actionBusy = false);
    }
  }

  bool _isStale(dynamic raw) {
    final seen = DateTime.tryParse('${raw ?? ''}')?.toUtc();
    if (seen == null) return true;
    return DateTime.now().toUtc().difference(seen) > const Duration(minutes: 3);
  }

  String _lastSeenText(dynamic raw) {
    final seen = DateTime.tryParse('${raw ?? ''}')?.toLocal();
    if (seen == null) return 'Konum bekleniyor';
    final diff = DateTime.now().difference(seen);
    if (diff.inSeconds < 60) return 'Az önce güncellendi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce güncellendi';
    return '${seen.hour.toString().padLeft(2, '0')}:${seen.minute.toString().padLeft(2, '0')} güncellendi';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: data.watchShipment(widget.shipmentId),
      builder: (context, shipmentSnapshot) {
        if (!shipmentSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final shipment = shipmentSnapshot.data!;
        final courierId = shipment['courier_id']?.toString();
        final status = (shipment['status'] ?? 'searching').toString();
        final pickupLat = (shipment['pickup_lat'] as num?)?.toDouble();
        final pickupLng = (shipment['pickup_lng'] as num?)?.toDouble();
        final dropLat = (shipment['dropoff_lat'] as num?)?.toDouble();
        final dropLng = (shipment['dropoff_lng'] as num?)?.toDouble();

        if (courierId == null || courierId.isEmpty) {
          final center = pickupLat != null && pickupLng != null
              ? LatLng(pickupLat, pickupLng)
              : const LatLng(41.0082, 28.9784);
          return _scaffold(
            shipment,
            status,
            center,
            const <String, dynamic>{},
            null,
            pickupLat,
            pickupLng,
            dropLat,
            dropLng,
            waiting: true,
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
            final center = courierPoint ??
                (pickupLat != null && pickupLng != null
                    ? LatLng(pickupLat, pickupLng)
                    : const LatLng(41.0082, 28.9784));
            return _scaffold(
              shipment,
              status,
              center,
              courier,
              courierPoint,
              pickupLat,
              pickupLng,
              dropLat,
              dropLng,
            );
          },
        );
      },
    );
  }

  Widget _scaffold(
    Map<String, dynamic> shipment,
    String status,
    LatLng center,
    Map<String, dynamic> courier,
    LatLng? courierPoint,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng, {
    bool waiting = false,
  }) {
    final pickupPoint = pickupLat != null && pickupLng != null ? LatLng(pickupLat, pickupLng) : null;
    final dropPoint = dropLat != null && dropLng != null ? LatLng(dropLat, dropLng) : null;
    final routeTarget = status == 'delivered' || status == 'cancelled'
        ? null
        : (status == 'picked_up' || status == 'at_dropoff' ? dropPoint : pickupPoint);
    final code = (shipment['public_code'] ?? 'Gönderi').toString();
    final info = courierInfo ?? const <String, dynamic>{};
    final courierName = (info['full_name'] ?? 'Kurye').toString();
    final phone = (info['phone'] ?? '').toString();
    final avatarUrl = (info['avatar_url'] ?? '').toString();
    final plate = (info['plate_number'] ?? '').toString();
    final rating = (info['rating_average'] as num?)?.toDouble() ?? 0;
    final ratingCount = (info['rating_count'] as num?)?.toInt() ?? 0;
    final lastSeen = courier['last_seen_at'] ?? info['last_seen_at'];
    final stale = !waiting && _isStale(lastSeen);
    final canCancel = status == 'searching' || status == 'accepted';
    final delivered = status == 'delivered';
    final cancelled = status == 'cancelled';

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('$code • Canlı Takip', style: const TextStyle(color: navy, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: actionBusy ? null : _support, icon: const Icon(Icons.support_agent_rounded)),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: delivered ? const Color(0xFFE8FBF2) : const Color(0xFFEAF4FF),
                  child: Icon(delivered ? Icons.check_rounded : Icons.delivery_dining_rounded, color: delivered ? green : blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_label(status), style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      waiting
                          ? 'Kurye işi aldığında konumu burada görünecek.'
                          : stale
                              ? 'Kurye bağlantısı zayıf. Son konum gösteriliyor.'
                              : courierPoint == null
                                  ? 'Kurye konumu güncelleniyor…'
                                  : 'Kurye konumu gerçek zamanlı güncelleniyor.',
                      style: TextStyle(color: stale ? orange : muted, fontSize: 11.5, fontWeight: stale ? FontWeight.w700 : FontWeight.w400),
                    ),
                    if (!waiting) ...[
                      const SizedBox(height: 3),
                      Text(_lastSeenText(lastSeen), style: const TextStyle(color: muted, fontSize: 10.5)),
                    ],
                  ]),
                ),
              ],
            ),
          ),
          if (!waiting && !cancelled)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFEAF4FF),
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty ? const Icon(Icons.person_rounded, color: blue, size: 30) : null,
                ),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(courierName, style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB020), size: 16),
                    const SizedBox(width: 3),
                    Text(ratingCount == 0 ? 'Yeni kurye' : '${rating.toStringAsFixed(1)} ($ratingCount)', style: const TextStyle(color: muted, fontSize: 11)),
                    if (plate.isNotEmpty) ...[
                      const Text('  •  ', style: TextStyle(color: muted)),
                      Text(plate, style: const TextStyle(color: navy, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ]),
                ])),
                IconButton.filledTonal(onPressed: () => _chat(courierName), icon: const Icon(Icons.chat_bubble_rounded)),
                if (phone.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  IconButton.filled(onPressed: () => _call(phone), icon: const Icon(Icons.phone_rounded)),
                ],
              ]),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FlutterMap(
                        mapController: mapController,
                        options: MapOptions(initialCenter: center, initialZoom: 14.5),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.queensho.kurye',
                          ),
                          CustomerRouteOverlay(
                            courierPoint: stale ? null : courierPoint,
                            targetPoint: routeTarget,
                            onEtaChanged: _updateRouteEta,
                          ),
                          MarkerLayer(markers: [
                            if (pickupPoint != null)
                              Marker(point: pickupPoint, width: 42, height: 42, child: const CircleAvatar(backgroundColor: blue, child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20))),
                            if (dropPoint != null)
                              Marker(point: dropPoint, width: 42, height: 42, child: const CircleAvatar(backgroundColor: Color(0xFFFF4757), child: Icon(Icons.flag_rounded, color: Colors.white, size: 20))),
                            if (courierPoint != null)
                              Marker(
                                point: courierPoint,
                                width: 64,
                                height: 64,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 450),
                                  decoration: BoxDecoration(color: (stale ? orange : blue).withValues(alpha: .18), shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: CircleAvatar(radius: 20, backgroundColor: stale ? orange : blue, child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 25)),
                                ),
                              ),
                          ]),
                        ],
                      ),
                    ),
                    if (courierPoint != null && routeEtaMin != null && routeTarget != null)
                      Positioned(
                        left: 14,
                        top: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12)]),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.route_rounded, color: Color(0xFF6C5CE7), size: 18),
                            const SizedBox(width: 7),
                            Text('${routeEtaMin} dk${routeDistanceKm == null ? '' : ' • ${routeDistanceKm!.toStringAsFixed(1)} km'}', style: const TextStyle(color: navy, fontWeight: FontWeight.w900, fontSize: 12)),
                          ]),
                        ),
                      ),
                    if (courierPoint != null)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          heroTag: 'customer-track-recenter',
                          backgroundColor: Colors.white,
                          foregroundColor: blue,
                          onPressed: () => mapController.move(courierPoint, 15.5),
                          child: const Icon(Icons.my_location_rounded),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 13, 18, 16),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rota', style: TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Row(children: [
                const Icon(Icons.circle, color: blue, size: 11),
                const SizedBox(width: 8),
                Expanded(child: Text((shipment['pickup_address'] ?? '').toString(), style: const TextStyle(color: muted, fontSize: 12))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFFFF4757), size: 18),
                const SizedBox(width: 4),
                Expanded(child: Text((shipment['dropoff_address'] ?? '').toString(), style: const TextStyle(color: muted, fontSize: 12))),
              ]),
              if ((shipment['recipient_name'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 7),
                Text('Alıcı: ${shipment['recipient_name']}${(shipment['recipient_phone'] ?? '').toString().isEmpty ? '' : ' • ${shipment['recipient_phone']}'}', style: const TextStyle(color: navy, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                if (canCancel)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: actionBusy ? null : () => _cancelShipment(status),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Gönderiyi İptal Et'),
                    ),
                  ),
                if (canCancel) const SizedBox(width: 8),
                if (delivered) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: actionBusy ? null : _rateShipment,
                      icon: const Icon(Icons.star_rounded),
                      label: const Text('Puanla'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: actionBusy ? null : _repeat,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tekrar Gönder'),
                    ),
                  ),
                ],
                if (cancelled)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: actionBusy ? null : _repeat,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tekrar Gönder'),
                    ),
                  ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}
