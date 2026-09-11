import 'app_data_service.dart';

extension CustomerDeliveryActions on AppDataService {
  Future<Map<String, dynamic>> cancelCustomerShipment(
    String shipmentId, {
    String? reason,
  }) async {
    final value = await client.rpc(
      'customer_cancel_shipment',
      params: {'p_shipment_id': shipmentId, 'p_reason': reason},
    );
    return Map<String, dynamic>.from(value as Map);
  }

  Future<Map<String, dynamic>> submitShipmentRating(
    String shipmentId, {
    required int rating,
    String? comment,
    String? problemReason,
  }) async {
    final value = await client.rpc(
      'submit_shipment_rating',
      params: {
        'p_shipment_id': shipmentId,
        'p_rating': rating,
        'p_comment': comment,
        'p_problem_reason': problemReason,
      },
    );
    return Map<String, dynamic>.from(value as Map);
  }

  Future<Map<String, dynamic>> createSupportTicket({
    String? shipmentId,
    required String category,
    String? description,
  }) async {
    final value = await client.rpc(
      'create_support_ticket',
      params: {
        'p_shipment_id': shipmentId,
        'p_category': category,
        'p_description': description,
      },
    );
    return Map<String, dynamic>.from(value as Map);
  }

  Future<Map<String, dynamic>?> getShipmentRating(String shipmentId) async {
    final rows = await client
        .from('shipment_ratings')
        .select()
        .eq('shipment_id', shipmentId)
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<Map<String, dynamic>> repeatCustomerShipment(String shipmentId) async {
    final value = await client.rpc(
      'repeat_customer_shipment',
      params: {'p_shipment_id': shipmentId},
    );
    return Map<String, dynamic>.from(value as Map);
  }

  Future<Map<String, dynamic>> createShipmentWithRecipient({
    required String vehicleType,
    required String packageType,
    required String pickupAddress,
    required String dropoffAddress,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    String? weightLabel,
    String? sizeLabel,
    String? note,
    double? distanceKm,
    int? durationMin,
    required String paymentType,
    String? paymentMethodId,
    String? recipientName,
    String? recipientPhone,
    String? pickupDetail,
    String? dropoffDetail,
    String? doorNote,
  }) async {
    final value = await client.rpc('create_priced_shipment', params: {
      'p_vehicle_type': vehicleType,
      'p_package_type': packageType,
      'p_pickup_address': pickupAddress,
      'p_dropoff_address': dropoffAddress,
      'p_pickup_lat': pickupLat,
      'p_pickup_lng': pickupLng,
      'p_dropoff_lat': dropoffLat,
      'p_dropoff_lng': dropoffLng,
      'p_weight_label': weightLabel,
      'p_size_label': sizeLabel,
      'p_note': note,
      'p_distance_km': distanceKm,
      'p_duration_min': durationMin,
      'p_payment_type': paymentType,
      'p_payment_method_id': paymentMethodId,
      'p_recipient_name': recipientName,
      'p_recipient_phone': recipientPhone,
      'p_pickup_detail': pickupDetail,
      'p_dropoff_detail': dropoffDetail,
      'p_door_note': doorNote,
    });
    return Map<String, dynamic>.from(value as Map);
  }
}
