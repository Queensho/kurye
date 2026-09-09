import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'data/app_data_service.dart';

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
  final MapController mapController = MapController();

  String _label(String status) => switch (status) {
        'searching' => 'Kurye aranıyor',
        'accepted' => 'Kurye alım noktasına gidiyor',
        'at_pickup' => 'Kurye alım noktasında',
        'picked_up' => 'Gönderin yolda',
        'at_dropoff' => 'Kurye teslimat noktasında',
        'delivered' => 'Teslim edildi',
        _ => 'Gönderi takip ediliyor',
      };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AppDataService.instance.watchShipment(widget.shipmentId),
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
          return _scaffold(shipment, status, center, null, pickupLat, pickupLng, dropLat, dropLng, waiting: true);
        }

        return StreamBuilder<Map<String, dynamic>>(
          stream: AppDataService.instance.watchCourierLocation(courierId),
          builder: (context, courierSnapshot) {
            final courier = courierSnapshot.data ?? const <String, dynamic>{};
            final lat = (courier['latitude'] as num?)?.toDouble();
            final lng = (courier['longitude'] as num?)?.toDouble();
            final courierPoint = lat != null && lng != null ? LatLng(lat, lng) : null;
            final center = courierPoint ??
                (pickupLat != null && pickupLng != null
                    ? LatLng(pickupLat, pickupLng)
                    : const LatLng(41.0082, 28.9784));
            return _scaffold(shipment, status, center, courierPoint, pickupLat, pickupLng, dropLat, dropLng);
          },
        );
      },
    );
  }

  Widget _scaffold(
    Map<String, dynamic> shipment,
    String status,
    LatLng center,
    LatLng? courierPoint,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng, {
    bool waiting = false,
  }) {
    final pickupPoint = pickupLat != null && pickupLng != null ? LatLng(pickupLat, pickupLng) : null;
    final dropPoint = dropLat != null && dropLng != null ? LatLng(dropLat, dropLng) : null;
    final code = (shipment['public_code'] ?? 'Gönderi').toString();
    final lastSeenRaw = shipment['updated_at']?.toString();
    final lastSeen = DateTime.tryParse(lastSeenRaw ?? '')?.toLocal();

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('$code • Canlı Takip', style: const TextStyle(color: navy, fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: status == 'delivered' ? const Color(0xFFE8FBF2) : const Color(0xFFEAF4FF),
                  child: Icon(status == 'delivered' ? Icons.check_rounded : Icons.delivery_dining_rounded, color: status == 'delivered' ? const Color(0xFF10B866) : blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_label(status), style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(waiting ? 'Kurye işi aldığında konumu burada görünecek.' : courierPoint == null ? 'Kurye konumu bekleniyor…' : 'Kurye konumu gerçek zamanlı güncelleniyor.', style: const TextStyle(color: muted, fontSize: 11.5)),
                  ]),
                ),
                if (lastSeen != null)
                  Text('${lastSeen.hour.toString().padLeft(2, '0')}:${lastSeen.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                          MarkerLayer(markers: [
                            if (pickupPoint != null)
                              Marker(
                                point: pickupPoint,
                                width: 42,
                                height: 42,
                                child: const CircleAvatar(backgroundColor: blue, child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20)),
                              ),
                            if (dropPoint != null)
                              Marker(
                                point: dropPoint,
                                width: 42,
                                height: 42,
                                child: const CircleAvatar(backgroundColor: Color(0xFFFF4757), child: Icon(Icons.flag_rounded, color: Colors.white, size: 20)),
                              ),
                            if (courierPoint != null)
                              Marker(
                                point: courierPoint,
                                width: 64,
                                height: 64,
                                child: Container(
                                  decoration: BoxDecoration(color: blue.withValues(alpha: .18), shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: const CircleAvatar(radius: 20, backgroundColor: blue, child: Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 25)),
                                ),
                              ),
                          ]),
                        ],
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
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rota', style: TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              Row(children: [
                const Icon(Icons.circle, color: blue, size: 11),
                const SizedBox(width: 8),
                Expanded(child: Text((shipment['pickup_address'] ?? '').toString(), style: const TextStyle(color: muted, fontSize: 12))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFFFF4757), size: 18),
                const SizedBox(width: 4),
                Expanded(child: Text((shipment['dropoff_address'] ?? '').toString(), style: const TextStyle(color: muted, fontSize: 12))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}
