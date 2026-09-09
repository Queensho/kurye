import 'package:supabase_flutter/supabase_flutter.dart';

class AppDataService {
  AppDataService._();
  static final AppDataService instance = AppDataService._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://xmbuuxfqdcmcettjgqbx.supabase.co');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_eQFtGX0OZ7Dg-HG4iPVmmw_Hzr_wTjT');
  SupabaseClient get client => Supabase.instance.client;
  bool get isSignedIn => client.auth.currentSession != null;

  String get userId {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Kullanıcı oturumu hazır değil.');
    return user.id;
  }

  Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
    if (isSignedIn) await ensureProfile();
  }

  Future<void> sendPhoneOtp(String phone) async {
    await client.auth.signInWithOtp(phone: phone);
  }

  Future<void> verifyPhoneOtp({required String phone, required String token}) async {
    await client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
    await ensureProfile();
    await client.from('profiles').update({'phone': phone, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', userId);
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

  Future<Map<String,dynamic>> createShipment({required String vehicleType,required String packageType,required String pickupAddress,required String dropoffAddress,double? pickupLat,double? pickupLng,double? dropoffLat,double? dropoffLng,String? weightLabel,String? sizeLabel,String? note,double? distanceKm,int? durationMin,int? estimatedPrice,required String paymentType,String? paymentMethodId}) async => Map<String,dynamic>.from(await client.from('shipments').insert({'user_id':userId,'status':'searching','vehicle_type':vehicleType,'package_type':packageType,'pickup_address':pickupAddress,'pickup_lat':pickupLat,'pickup_lng':pickupLng,'dropoff_address':dropoffAddress,'dropoff_lat':dropoffLat,'dropoff_lng':dropoffLng,'weight_label':weightLabel,'size_label':sizeLabel,'note':note,'distance_km':distanceKm,'duration_min':durationMin,'estimated_price':estimatedPrice,'payment_type':paymentType,'payment_method_id':paymentMethodId}).select().single());
  Future<List<Map<String,dynamic>>> getShipments() async => List<Map<String,dynamic>>.from(await client.from('shipments').select().eq('user_id',userId).order('created_at',ascending:false));
  Stream<List<Map<String,dynamic>>> watchShipments() => client.from('shipments').stream(primaryKey:['id']).eq('user_id',userId).order('created_at',ascending:false).map((r)=>List<Map<String,dynamic>>.from(r));

  Future<Map<String,dynamic>> setCourierOnline({required bool online,String vehicleType='motorcycle',double? latitude,double? longitude}) async => Map<String,dynamic>.from(await client.rpc('set_courier_online',params:{'p_online':online,'p_vehicle_type':vehicleType,'p_latitude':latitude,'p_longitude':longitude}) as Map);
  Future<void> updateCourierLocation(double latitude,double longitude) async => client.rpc('update_courier_location',params:{'p_latitude':latitude,'p_longitude':longitude});
  Stream<List<Map<String,dynamic>>> watchCourierPool() => client.from('shipments').stream(primaryKey:['id']).eq('status','searching').order('created_at',ascending:false).map((r)=>List<Map<String,dynamic>>.from(r.where((e)=>e['courier_id']==null)));
  Future<Map<String,dynamic>> claimShipment(String shipmentId) async { try { return Map<String,dynamic>.from(await client.rpc('claim_shipment',params:{'p_shipment_id':shipmentId}) as Map); } on PostgrestException catch(e) { if(e.message.contains('shipment_already_claimed_or_unavailable')) throw StateError('İş başka bir kurye tarafından alındı.'); if(e.message.contains('courier_already_has_active_job')) throw StateError('Zaten aktif bir işin var.'); if(e.message.contains('courier_offline')) throw StateError('İşi almak için online olmalısın.'); rethrow; } }

  Future<List<Map<String,dynamic>>> getConversations() async => List<Map<String,dynamic>>.from(await client.from('conversations').select('*, shipments(public_code,pickup_address,dropoff_address)').eq('user_id',userId).order('updated_at',ascending:false));
  Future<List<Map<String,dynamic>>> getMessages(String conversationId) async => List<Map<String,dynamic>>.from(await client.from('messages').select().eq('conversation_id',conversationId).order('created_at'));
  Stream<List<Map<String,dynamic>>> watchMessages(String conversationId) => client.from('messages').stream(primaryKey:['id']).eq('conversation_id',conversationId).order('created_at').map((r)=>List<Map<String,dynamic>>.from(r));
  Future<void> sendMessage(String conversationId,String body) async { final text=body.trim(); if(text.isEmpty)return; await client.from('messages').insert({'conversation_id':conversationId,'sender_user_id':userId,'sender_role':'customer','body':text,'is_read':false}); }
  Future<void> signOut() async => client.auth.signOut();
}

extension IterableFirstOrNullX<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
