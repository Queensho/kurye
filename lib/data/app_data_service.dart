import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDataService {
  AppDataService._();
  static final AppDataService instance = AppDataService._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://xmbuuxfqdcmcettjgqbx.supabase.co');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_eQFtGX0OZ7Dg-HG4iPVmmw_Hzr_wTjT');
  SupabaseClient get client => Supabase.instance.client;
  bool get isSignedIn => client.auth.currentSession != null;
  StreamSubscription<Position>? _courierPositionSubscription;

  String get userId {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Kullanıcı oturumu hazır değil.');
    return user.id;
  }

  Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
    if (isSignedIn) await ensureProfile();
  }

  Future<void> signUpWithPhonePassword({required String phone, required String password}) async {
    final res = await client.auth.signUp(phone: phone, password: password);
    if (res.session == null) throw StateError('Telefon doğrulaması açık. OTP kullanmadan kayıt için Supabase Phone doğrulamasını kapatmalısın.');
    await ensureProfile();
    await client.from('profiles').update({'phone': phone, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', userId);
  }

  Future<void> signInWithPhonePassword({required String phone, required String password}) async {
    await client.auth.signInWithPassword(phone: phone, password: password);
    await ensureProfile();
  }

  Future<void> ensureProfile() async => client.from('profiles').upsert({'id': userId}, onConflict: 'id');
  Future<Map<String, dynamic>> getProfile() async => Map<String, dynamic>.from(await client.from('profiles').select().eq('id', userId).single());

  Future<void> updateProfile({String? fullName, String? phone, String? email, bool? notificationsEnabled, String? language}) async {
    final values = <String, dynamic>{'updated_at': DateTime.now().toUtc().toIso8601String()};
    if (fullName != null) values['full_name'] = fullName;
    if (phone != null) values['phone'] = phone;
    if (email != null) values['email'] = email;
    if (notificationsEnabled != null) values['notifications_enabled'] = notificationsEnabled;
    if (language != null) values['language'] = language;
    await client.from('profiles').update(values).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getAddresses() async => List<Map<String, dynamic>>.from(await client.from('addresses').select().eq('user_id', userId).order('is_default', ascending: false).order('created_at'));
  Future<Map<String, dynamic>> addAddress({required String label, required String addressLine, double? latitude, double? longitude, bool isDefault = false}) async {
    if (isDefault) await client.from('addresses').update({'is_default': false}).eq('user_id', userId);
    return Map<String, dynamic>.from(await client.from('addresses').insert({'user_id': userId,'label': label,'address_line': addressLine,'latitude': latitude,'longitude': longitude,'is_default': isDefault}).select().single());
  }
  Future<void> deleteAddress(String id) async => client.from('addresses').delete().eq('id', id).eq('user_id', userId);
  Future<void> setDefaultAddress(String id) async { await client.from('addresses').update({'is_default': false}).eq('user_id', userId); await client.from('addresses').update({'is_default': true}).eq('id', id).eq('user_id', userId); }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async => List<Map<String, dynamic>>.from(await client.from('payment_methods').select().eq('user_id', userId).order('is_default', ascending: false).order('created_at'));
  Future<Map<String, dynamic>> addCard({required String brand, required String last4, String? label, bool isDefault = false}) async { if (isDefault) await client.from('payment_methods').update({'is_default': false}).eq('user_id', userId); return Map<String,dynamic>.from(await client.from('payment_methods').insert({'user_id':userId,'type':'card','provider':'pending_gateway','brand':brand,'last4':last4,'label':label,'is_default':isDefault}).select().single()); }
  Future<void> deletePaymentMethod(String id) async => client.from('payment_methods').delete().eq('id', id).eq('user_id', userId);
  Future<void> setDefaultPaymentMethod(String id) async { await client.from('payment_methods').update({'is_default':false}).eq('user_id',userId); await client.from('payment_methods').update({'is_default':true}).eq('id',id).eq('user_id',userId); }

  Future<Map<String,dynamic>> calculateDeliveryPrice({required String vehicleType, required double distanceKm, String? pickupAddress}) async {
    final value = await client.rpc('calculate_delivery_price', params:{
      'p_vehicle_type':vehicleType,
      'p_distance_km':distanceKm,
      'p_pickup_address':pickupAddress,
    });
    return Map<String,dynamic>.from(value as Map);
  }

  Future<Map<String,dynamic>> createShipment({required String vehicleType,required String packageType,required String pickupAddress,required String dropoffAddress,double? pickupLat,double? pickupLng,double? dropoffLat,double? dropoffLng,String? weightLabel,String? sizeLabel,String? note,double? distanceKm,int? durationMin,int? estimatedPrice,required String paymentType,String? paymentMethodId}) async {
    try {
      final value = await client.rpc('create_priced_shipment',params:{
        'p_vehicle_type':vehicleType,
        'p_package_type':packageType,
        'p_pickup_address':pickupAddress,
        'p_dropoff_address':dropoffAddress,
        'p_pickup_lat':pickupLat,
        'p_pickup_lng':pickupLng,
        'p_dropoff_lat':dropoffLat,
        'p_dropoff_lng':dropoffLng,
        'p_weight_label':weightLabel,
        'p_size_label':sizeLabel,
        'p_note':note,
        'p_distance_km':distanceKm,
        'p_duration_min':durationMin,
        'p_payment_type':paymentType,
        'p_payment_method_id':paymentMethodId,
      });
      return Map<String,dynamic>.from(value as Map);
    } on PostgrestException catch(e) {
      if (e.message.contains('pricing_rule_not_found')) throw StateError('Bu araç tipi için aktif fiyat kuralı bulunamadı.');
      rethrow;
    }
  }
  Future<List<Map<String,dynamic>>> getShipments() async => List<Map<String,dynamic>>.from(await client.from('shipments').select().eq('user_id',userId).order('created_at',ascending:false));
  Stream<List<Map<String,dynamic>>> watchShipments() => client.from('shipments').stream(primaryKey:['id']).eq('user_id',userId).order('created_at',ascending:false).map((r)=>List<Map<String,dynamic>>.from(r));

  Future<Map<String,dynamic>> setCourierOnline({required bool online,String vehicleType='motorcycle',double? latitude,double? longitude}) async {
    final result = Map<String,dynamic>.from(await client.rpc('set_courier_online',params:{'p_online':online,'p_vehicle_type':vehicleType,'p_latitude':latitude,'p_longitude':longitude}) as Map);
    if (online) { unawaited(startCourierLocationTracking()); } else { await stopCourierLocationTracking(); }
    return result;
  }

  Future<void> startCourierLocationTracking() async {
    if (_courierPositionSubscription != null) return;
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
    try {
      final first = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      await updateCourierLocation(first.latitude, first.longitude);
    } catch (_) {}
    _courierPositionSubscription = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15)).listen((position) async {
      try { await updateCourierLocation(position.latitude, position.longitude); } catch (_) {}
    });
  }

  Future<void> stopCourierLocationTracking() async { await _courierPositionSubscription?.cancel(); _courierPositionSubscription = null; }
  Future<void> updateCourierLocation(double latitude,double longitude) async => client.rpc('update_courier_location',params:{'p_latitude':latitude,'p_longitude':longitude});
  Stream<Map<String,dynamic>> watchCourierLocation(String courierId) => client.from('couriers').stream(primaryKey:['user_id']).eq('user_id',courierId).map((rows)=>rows.isEmpty?<String,dynamic>{}:Map<String,dynamic>.from(rows.first));
  Stream<List<Map<String,dynamic>>> watchCourierPool() => client.from('shipments').stream(primaryKey:['id']).eq('status','searching').order('created_at',ascending:false).map((r)=>List<Map<String,dynamic>>.from(r.where((e)=>e['courier_id']==null)));
  Future<Map<String,dynamic>> claimShipment(String shipmentId) async { try { return Map<String,dynamic>.from(await client.rpc('claim_shipment',params:{'p_shipment_id':shipmentId}) as Map); } on PostgrestException catch(e) { if(e.message.contains('shipment_already_claimed_or_unavailable')) throw StateError('İş başka bir kurye tarafından alındı.'); if(e.message.contains('courier_already_has_active_job')) throw StateError('Zaten aktif bir işin var.'); if(e.message.contains('courier_offline')) throw StateError('İşi almak için online olmalısın.'); rethrow; } }

  Future<Map<String,dynamic>> updateShipmentStatus(String shipmentId, String status) async {
    try { return Map<String,dynamic>.from(await client.rpc('update_shipment_status', params:{'p_shipment_id':shipmentId,'p_status':status}) as Map); }
    on PostgrestException catch(e) { if (e.message.contains('invalid_status_transition')) throw StateError('Bu işlem sırası geçersiz.'); if (e.message.contains('shipment_not_assigned_to_courier')) throw StateError('Bu gönderi sana atanmış değil.'); rethrow; }
  }

  Stream<Map<String,dynamic>> watchShipment(String shipmentId) => client.from('shipments').stream(primaryKey:['id']).eq('id', shipmentId).map((rows) => rows.isEmpty ? <String,dynamic>{} : Map<String,dynamic>.from(rows.first));

  Future<Map<String,dynamic>> getCourierEarningsSummary() async {
    final value = await client.rpc('get_courier_earnings_summary');
    return Map<String,dynamic>.from(value as Map);
  }

  Stream<List<Map<String,dynamic>>> watchCourierEarnings() => client
      .from('courier_earnings')
      .stream(primaryKey:['id'])
      .eq('courier_id', userId)
      .order('created_at', ascending:false)
      .map((rows)=>List<Map<String,dynamic>>.from(rows));

  Stream<List<Map<String,dynamic>>> watchCourierPayouts() => client
      .from('courier_payouts')
      .stream(primaryKey:['id'])
      .eq('courier_id', userId)
      .order('created_at', ascending:false)
      .map((rows)=>List<Map<String,dynamic>>.from(rows));

  Future<List<Map<String,dynamic>>> getConversations() async => List<Map<String,dynamic>>.from(await client.from('conversations').select('*, shipments(public_code,pickup_address,dropoff_address)').eq('user_id',userId).order('updated_at',ascending:false));
  Future<List<Map<String,dynamic>>> getMessages(String conversationId) async => List<Map<String,dynamic>>.from(await client.from('messages').select().eq('conversation_id',conversationId).order('created_at'));
  Stream<List<Map<String,dynamic>>> watchMessages(String conversationId) => client.from('messages').stream(primaryKey:['id']).eq('conversation_id',conversationId).order('created_at').map((r)=>List<Map<String,dynamic>>.from(r));
  Future<void> sendMessage(String conversationId,String body) async { final text=body.trim(); if(text.isEmpty)return; await client.from('messages').insert({'conversation_id':conversationId,'sender_user_id':userId,'sender_role':'customer','body':text,'is_read':false}); }
  Future<void> signOut() async { await stopCourierLocationTracking(); await client.auth.signOut(); }
}

extension IterableFirstOrNullX<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
