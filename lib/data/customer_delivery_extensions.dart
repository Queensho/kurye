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

  Future<List<Map<String, dynamic>>> getCustomerSupportTickets() async {
    final value = await client.rpc('get_customer_support_tickets');
    return List<Map<String, dynamic>>.from(value as List);
  }

  Future<Map<String, dynamic>> createPaymentDispute({
    required String shipmentId,
    required String reason,
    String? description,
  }) async {
    final value = await client.rpc(
      'create_payment_dispute',
      params: {
        'p_shipment_id': shipmentId,
        'p_reason': reason,
        'p_description': description,
      },
    );
    return Map<String, dynamic>.from(value as Map);
  }

  Future<Map<String, dynamic>> saveDetailedAddress({
    required String label,
    required String addressLine,
    double? latitude,
    double? longitude,
    String? contactName,
    String? contactPhone,
    String? buildingName,
    String? floorNo,
    String? apartmentNo,
    String? doorNote,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      await client.from('addresses').update({'is_default': false}).eq('user_id', userId);
    }
    final row = await client.from('addresses').insert({
      'user_id': userId,
      'label': label.trim(),
      'address_line': addressLine.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'contact_name': contactName?.trim().isEmpty == true ? null : contactName?.trim(),
      'contact_phone': contactPhone?.trim().isEmpty == true ? null : contactPhone?.trim(),
      'building_name': buildingName?.trim().isEmpty == true ? null : buildingName?.trim(),
      'floor_no': floorNo?.trim().isEmpty == true ? null : floorNo?.trim(),
      'apartment_no': apartmentNo?.trim().isEmpty == true ? null : apartmentNo?.trim(),
      'door_note': doorNote?.trim().isEmpty == true ? null : doorNote?.trim(),
      'is_default': isDefault,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> updateDetailedAddress({
    required String addressId,
    String? label,
    String? addressLine,
    double? latitude,
    double? longitude,
    String? contactName,
    String? contactPhone,
    String? buildingName,
    String? floorNo,
    String? apartmentNo,
    String? doorNote,
  }) async {
    final values = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (label != null) values['label'] = label.trim();
    if (addressLine != null) values['address_line'] = addressLine.trim();
    if (latitude != null) values['latitude'] = latitude;
    if (longitude != null) values['longitude'] = longitude;
    if (contactName != null) values['contact_name'] = contactName.trim().isEmpty ? null : contactName.trim();
    if (contactPhone != null) values['contact_phone'] = contactPhone.trim().isEmpty ? null : contactPhone.trim();
    if (buildingName != null) values['building_name'] = buildingName.trim().isEmpty ? null : buildingName.trim();
    if (floorNo != null) values['floor_no'] = floorNo.trim().isEmpty ? null : floorNo.trim();
    if (apartmentNo != null) values['apartment_no'] = apartmentNo.trim().isEmpty ? null : apartmentNo.trim();
    if (doorNote != null) values['door_note'] = doorNote.trim().isEmpty ? null : doorNote.trim();
    await client.from('addresses').update(values).eq('id', addressId).eq('user_id', userId);
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

  Future<Map<String, dynamic>> updateCustomerShipmentDetails({
    required String shipmentId,
    required String recipientName,
    required String recipientPhone,
    String? pickupDetail,
    String? dropoffDetail,
    String? doorNote,
  }) async {
    final value = await client.rpc(
      'update_customer_shipment_details',
      params: {
        'p_shipment_id': shipmentId,
        'p_recipient_name': recipientName,
        'p_recipient_phone': recipientPhone,
        'p_pickup_detail': pickupDetail,
        'p_dropoff_detail': dropoffDetail,
        'p_door_note': doorNote,
      },
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
