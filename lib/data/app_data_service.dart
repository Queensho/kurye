import 'package:supabase_flutter/supabase_flutter.dart';

class AppDataService {
  AppDataService._();

  static final AppDataService instance = AppDataService._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xmbuuxfqdcmcettjgqbx.supabase.co',
  );

  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_eQFtGX0OZ7Dg-HG4iPVmmw_Hzr_wTjT',
  );

  SupabaseClient get client => Supabase.instance.client;

  String get userId {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Kullanıcı oturumu hazır değil.');
    return user.id;
  }

  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
    );

    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
    }

    await ensureProfile();
  }

  Future<void> ensureProfile() async {
    await client.from('profiles').upsert({
      'id': userId,
    }, onConflict: 'id');
  }

  Future<Map<String, dynamic>> getProfile() async {
    final row = await client.from('profiles').select().eq('id', userId).single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    bool? notificationsEnabled,
    String? language,
  }) async {
    final values = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (fullName != null) values['full_name'] = fullName;
    if (phone != null) values['phone'] = phone;
    if (email != null) values['email'] = email;
    if (notificationsEnabled != null) values['notifications_enabled'] = notificationsEnabled;
    if (language != null) values['language'] = language;
    await client.from('profiles').update(values).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getAddresses() async {
    final rows = await client
        .from('addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> addAddress({
    required String label,
    required String addressLine,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      await client.from('addresses').update({'is_default': false}).eq('user_id', userId);
    }
    final row = await client
        .from('addresses')
        .insert({
          'user_id': userId,
          'label': label,
          'address_line': addressLine,
          'latitude': latitude,
          'longitude': longitude,
          'is_default': isDefault,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> deleteAddress(String id) async {
    await client.from('addresses').delete().eq('id', id).eq('user_id', userId);
  }

  Future<void> setDefaultAddress(String id) async {
    await client.from('addresses').update({'is_default': false}).eq('user_id', userId);
    await client
        .from('addresses')
        .update({'is_default': true, 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final rows = await client
        .from('payment_methods')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> addCard({
    required String brand,
    required String last4,
    String? label,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      await client.from('payment_methods').update({'is_default': false}).eq('user_id', userId);
    }
    final row = await client
        .from('payment_methods')
        .insert({
          'user_id': userId,
          'type': 'card',
          'provider': 'pending_gateway',
          'brand': brand,
          'last4': last4,
          'label': label,
          'is_default': isDefault,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> deletePaymentMethod(String id) async {
    await client.from('payment_methods').delete().eq('id', id).eq('user_id', userId);
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    await client.from('payment_methods').update({'is_default': false}).eq('user_id', userId);
    await client
        .from('payment_methods')
        .update({'is_default': true, 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<Map<String, dynamic>> createShipment({
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
    int? estimatedPrice,
    required String paymentType,
    String? paymentMethodId,
  }) async {
    final row = await client
        .from('shipments')
        .insert({
          'user_id': userId,
          'status': 'searching',
          'vehicle_type': vehicleType,
          'package_type': packageType,
          'pickup_address': pickupAddress,
          'pickup_lat': pickupLat,
          'pickup_lng': pickupLng,
          'dropoff_address': dropoffAddress,
          'dropoff_lat': dropoffLat,
          'dropoff_lng': dropoffLng,
          'weight_label': weightLabel,
          'size_label': sizeLabel,
          'note': note,
          'distance_km': distanceKm,
          'duration_min': durationMin,
          'estimated_price': estimatedPrice,
          'payment_type': paymentType,
          'payment_method_id': paymentMethodId,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> getShipments() async {
    final rows = await client
        .from('shipments')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Stream<List<Map<String, dynamic>>> watchShipments() {
    return client
        .from('shipments')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final rows = await client
        .from('conversations')
        .select('*, shipments(public_code,pickup_address,dropoff_address)')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final rows = await client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  Future<void> sendMessage(String conversationId, String body) async {
    final text = body.trim();
    if (text.isEmpty) return;
    await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_user_id': userId,
      'sender_role': 'customer',
      'body': text,
      'is_read': false,
    });
    await client
        .from('conversations')
        .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', conversationId)
        .eq('user_id', userId);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }
}

extension IterableFirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
