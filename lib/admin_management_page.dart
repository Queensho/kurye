import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/app_data_service.dart';

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF74839A);
  static const bg = Color(0xFFF4F8FC);
  static const green = Color(0xFF20C997);
  static const red = Color(0xFFFF4D67);
  static const orange = Color(0xFFFFA726);

  final data = AppDataService.instance;
  final search = TextEditingController();
  int tab = 0;
  bool loading = true;
  String filter = 'Tümü';

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> couriers = [];
  List<Map<String, dynamic>> documents = [];
  List<Map<String, dynamic>> pricing = [];
  List<Map<String, dynamic>> regions = [];
  List<Map<String, dynamic>> payouts = [];

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      final uv = await data.client.rpc('admin_list_users');
      final cv = await data.client.rpc('admin_list_couriers');
      final dv = await data.client.from('courier_documents').select().order('created_at', ascending: false);
      final pr = await data.client.from('pricing_rules').select().order('created_at', ascending: false);
      final rg = await data.client.from('service_regions').select().order('sort_order').order('name');
      final po = await data.client.from('courier_payouts').select().order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        users = List<Map<String, dynamic>>.from(uv as List);
        couriers = List<Map<String, dynamic>>.from(cv as List);
        documents = List<Map<String, dynamic>>.from(dv);
        pricing = List<Map<String, dynamic>>.from(pr);
        regions = List<Map<String, dynamic>>.from(rg);
        payouts = List<Map<String, dynamic>>.from(po);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yüklenemedi: $e')));
    }
  }

  String get q => search.text.trim().toLowerCase();
  bool _matches(Map<String, dynamic> row) => q.isEmpty || row.values.any((v) => v?.toString().toLowerCase().contains(q) == true);

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      ('Kullanıcı', Icons.people_alt_rounded),
      ('Kurye', Icons.two_wheeler_rounded),
      ('Belgeler', Icons.badge_rounded),
      ('Fiyat', Icons.payments_rounded),
      ('Bölgeler', Icons.map_rounded),
      ('Ödemeler', Icons.account_balance_wallet_rounded),
    ];
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Operasyon Yönetimi', style: TextStyle(fontWeight: FontWeight.w900, color: navy)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: TextField(
                    controller: search,
                    decoration: InputDecoration(
                      hintText: 'Ara: isim, telefon, plaka, gönderi, belge...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: q.isEmpty ? null : IconButton(onPressed: search.clear, icon: const Icon(Icons.close_rounded)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    scrollDirection: Axis.horizontal,
                    itemCount: tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ChoiceChip(
                      selected: tab == i,
                      onSelected: (_) => setState(() { tab = i; filter = 'Tümü'; }),
                      avatar: Icon(tabs[i].$2, size: 18, color: tab == i ? Colors.white : blue),
                      label: Text(tabs[i].$1),
                      selectedColor: blue,
                      labelStyle: TextStyle(color: tab == i ? Colors.white : navy, fontWeight: FontWeight.w800),
                      side: BorderSide.none,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                Expanded(child: _body()),
              ],
            ),
      floatingActionButton: tab == 3
          ? FloatingActionButton.extended(onPressed: () => _pricingDialog(), icon: const Icon(Icons.add), label: const Text('Fiyat Kuralı'))
          : tab == 4
              ? FloatingActionButton.extended(onPressed: () => _regionDialog(), icon: const Icon(Icons.add), label: const Text('Bölge'))
              : null,
    );
  }

  Widget _body() {
    switch (tab) {
      case 0: return _users();
      case 1: return _couriers();
      case 2: return _documents();
      case 3: return _pricing();
      case 4: return _regions();
      default: return _payouts();
    }
  }

  Widget _filters(List<String> values) => SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          itemCount: values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (_, i) => FilterChip(
            selected: filter == values[i],
            label: Text(values[i]),
            onSelected: (_) => setState(() => filter = values[i]),
            selectedColor: const Color(0xFFDFF1FF),
            side: BorderSide.none,
          ),
        ),
      );

  Widget _users() {
    final rows = users.where(_matches).where((r) => filter == 'Tümü' || (filter == 'Aktif' ? r['account_status'] != 'suspended' : r['account_status'] == 'suspended')).toList();
    return Column(children: [
      _filters(const ['Tümü','Aktif','Askıda']),
      Expanded(child: _list(rows, (r) => _tile(
        icon: Icons.person_rounded,
        title: (r['full_name'] ?? 'İsimsiz kullanıcı').toString(),
        subtitle: '${r['phone'] ?? r['email'] ?? 'İletişim yok'}\n${r['account_status'] == 'suspended' ? 'Askıda' : 'Aktif'}',
        badge: r['account_status'] == 'suspended' ? 'Askıda' : 'Aktif',
        badgeColor: r['account_status'] == 'suspended' ? red : green,
        onTap: () => _userDetail(r),
      ))),
    ]);
  }

  Widget _couriers() {
    final rows = couriers.where(_matches).where((r) {
      if (filter == 'Online') return r['is_online'] == true;
      if (filter == 'Offline') return r['is_online'] != true;
      if (filter == 'Onaysız') return r['is_approved'] != true;
      return true;
    }).toList();
    return Column(children: [
      _filters(const ['Tümü','Online','Offline','Onaysız']),
      Expanded(child: _list(rows, (r) => _tile(
        icon: Icons.two_wheeler_rounded,
        title: (r['full_name'] ?? r['user_id'] ?? 'Kurye').toString(),
        subtitle: '${r['vehicle_type'] ?? 'Araç yok'} • ${r['is_online'] == true ? 'Online' : 'Offline'}\n${r['is_approved'] == true ? 'Onaylı kurye' : 'Onay bekliyor'}',
        badge: r['is_approved'] == true ? 'Onaylı' : 'Bekliyor',
        badgeColor: r['is_approved'] == true ? green : orange,
        onTap: () => _courierDetail(r),
      ))),
    ]);
  }

  Widget _documents() {
    final rows = documents.where(_matches).where((r) => filter == 'Tümü' || r['status']?.toString() == {'Bekleyen':'pending','Onaylı':'approved','Reddedilen':'rejected'}[filter]).toList();
    return Column(children: [
      _filters(const ['Tümü','Bekleyen','Onaylı','Reddedilen']),
      Expanded(child: _list(rows, (r) => _tile(
        icon: Icons.description_rounded,
        title: _docName((r['document_type'] ?? '').toString()),
        subtitle: 'Kurye: ${r['courier_id'] ?? '-'}\n${r['status'] ?? 'pending'}',
        badge: _statusTr(r['status']?.toString()),
        badgeColor: r['status'] == 'approved' ? green : r['status'] == 'rejected' ? red : orange,
        onTap: () => _documentDetail(r),
      ))),
    ]);
  }

  Widget _pricing() {
    final rows = pricing.where(_matches).toList();
    return _list(rows, (r) => _tile(
      icon: Icons.payments_rounded,
      title: (r['name'] ?? 'Fiyat kuralı').toString(),
      subtitle: 'Baz ₺${r['base_price']} • Km ₺${r['per_km_price']} • Min ₺${r['minimum_price']}\nKurye %${r['courier_share_percent']} • Komisyon %${r['platform_commission_percent']}',
      badge: r['is_active'] == true ? 'Aktif' : 'Pasif',
      badgeColor: r['is_active'] == true ? green : muted,
      onTap: () => _pricingDialog(existing: r),
    ));
  }

  Widget _regions() {
    final rows = regions.where(_matches).toList();
    return _list(rows, (r) => _tile(
      icon: Icons.location_on_rounded,
      title: (r['name'] ?? r['district'] ?? 'Bölge').toString(),
      subtitle: '${r['city'] ?? ''} • ${r['district'] ?? ''}\nEk ücret: ₺${r['extra_fee'] ?? 0}',
      badge: r['is_active'] == true ? 'Aktif' : 'Pasif',
      badgeColor: r['is_active'] == true ? green : muted,
      onTap: () => _regionDialog(existing: r),
    ));
  }

  Widget _payouts() {
    final rows = payouts.where(_matches).where((r) => filter == 'Tümü' || _statusTr(r['status']?.toString()) == filter).toList();
    return Column(children: [
      _filters(const ['Tümü','Bekleyen','İşleniyor','Ödendi','Başarısız','İptal']),
      Expanded(child: _list(rows, (r) => _tile(
        icon: Icons.account_balance_wallet_rounded,
        title: '₺${r['amount'] ?? 0}',
        subtitle: 'Kurye: ${r['courier_id'] ?? '-'}\n${_date(r['created_at'])}',
        badge: _statusTr(r['status']?.toString()),
        badgeColor: r['status'] == 'paid' ? green : r['status'] == 'failed' || r['status'] == 'cancelled' ? red : orange,
        onTap: () => _payoutDetail(r),
      ))),
    ]);
  }

  Widget _list(List<Map<String, dynamic>> rows, Widget Function(Map<String, dynamic>) item) => rows.isEmpty
      ? const Center(child: Text('Kayıt bulunamadı', style: TextStyle(color: muted, fontWeight: FontWeight.w700)))
      : RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: const EdgeInsets.fromLTRB(14, 8, 14, 90), itemCount: rows.length, itemBuilder: (_, i) => item(rows[i])));

  Widget _tile({required IconData icon, required String title, required String subtitle, required String badge, required Color badgeColor, required VoidCallback onTap}) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      leading: CircleAvatar(backgroundColor: const Color(0xFFEAF4FF), child: Icon(icon, color: blue)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: navy)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis)),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: badgeColor.withOpacity(.12), borderRadius: BorderRadius.circular(10)), child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w900))),
        const SizedBox(height: 5),
        const Icon(Icons.chevron_right_rounded, color: muted),
      ]),
    ),
  );

  Future<void> _userDetail(Map<String, dynamic> r) async {
    await _sheet('Kullanıcı Detayı', Icons.person_rounded, [
      _kv('Ad Soyad', r['full_name']), _kv('Telefon', r['phone']), _kv('E-posta', r['email']), _kv('Durum', r['account_status'] ?? 'active'), _kv('Kullanıcı ID', r['id']),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () async { Navigator.pop(context); await data.client.rpc('admin_set_user_status', params:{'p_user_id':r['id'],'p_status':r['account_status']=='suspended'?'active':'suspended'}); await _load(); }, icon: Icon(r['account_status']=='suspended'?Icons.lock_open_rounded:Icons.block_rounded), label: Text(r['account_status']=='suspended'?'Hesabı Aç':'Hesabı Askıya Al')),
    ]);
  }

  Future<void> _courierDetail(Map<String, dynamic> r) async {
    await _sheet('Kurye Detayı', Icons.two_wheeler_rounded, [
      _kv('Kurye ID', r['user_id']), _kv('Araç', r['vehicle_type']), _kv('Online', r['is_online']==true?'Evet':'Hayır'), _kv('Onay', r['is_approved']==true?'Onaylı':'Bekliyor'), _kv('Aktif İş', r['active_shipment_id'] ?? 'Yok'), _kv('Son Görülme', _date(r['last_seen'])),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () async { Navigator.pop(context); await data.client.rpc('admin_set_courier_approval', params:{'p_user_id':r['user_id'],'p_approved':r['is_approved']!=true}); await _load(); }, icon: const Icon(Icons.verified_rounded), label: Text(r['is_approved']==true?'Onayı Kaldır':'Kuryeyi Onayla')),
    ]);
  }

  Future<void> _documentDetail(Map<String, dynamic> r) async {
    await _sheet('Belge Detayı', Icons.description_rounded, [
      _kv('Belge', _docName(r['document_type']?.toString() ?? '')), _kv('Kurye', r['courier_id']), _kv('Durum', _statusTr(r['status']?.toString())), _kv('Red nedeni', r['rejection_reason']),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: () => _viewDocument(r), icon: const Icon(Icons.visibility_rounded), label: const Text('Belgeyi Gör')),
      const SizedBox(height: 8),
      Row(children:[
        Expanded(child: FilledButton(onPressed: () async { Navigator.pop(context); await data.client.rpc('admin_review_document', params:{'p_document_id':r['id'],'p_status':'approved','p_reason':null}); await _load(); }, child: const Text('Onayla'))),
        const SizedBox(width:8),
        Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor:red), onPressed: () async { Navigator.pop(context); await _rejectDoc(r); }, child: const Text('Reddet'))),
      ]),
    ]);
  }

  Future<void> _viewDocument(Map<String, dynamic> r) async {
    try {
      String raw = (r['file_url'] ?? '').toString();
      if (raw.isEmpty) throw Exception('Belge dosyası yok');
      String url = raw;
      if (!raw.startsWith('http')) url = await data.client.storage.from('courier-documents').createSignedUrl(raw, 900);
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw Exception('Açılamadı');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Belge açılamadı: $e')));
    }
  }

  Future<void> _rejectDoc(Map<String, dynamic> r) async {
    final c = TextEditingController();
    final reason = await showDialog<String>(context: context, builder: (d) => AlertDialog(title: const Text('Red nedeni'), content: TextField(controller:c, maxLines:3), actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Vazgeç')),FilledButton(onPressed:()=>Navigator.pop(d,c.text.trim()),child:const Text('Reddet'))]));
    c.dispose();
    if (reason == null) return;
    await data.client.rpc('admin_review_document', params:{'p_document_id':r['id'],'p_status':'rejected','p_reason':reason});
    await _load();
  }

  Future<void> _pricingDialog({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final base = TextEditingController(text: existing?['base_price']?.toString() ?? '');
    final km = TextEditingController(text: existing?['per_km_price']?.toString() ?? '');
    final min = TextEditingController(text: existing?['minimum_price']?.toString() ?? '');
    final courier = TextEditingController(text: existing?['courier_share_percent']?.toString() ?? '80');
    bool active = existing?['is_active'] != false;
    String vehicle = existing?['vehicle_type']?.toString() ?? 'motorcycle';
    final ok = await showModalBottomSheet<bool>(context: context,isScrollControlled:true,builder:(c)=>StatefulBuilder(builder:(c,setD)=>Padding(padding:EdgeInsets.fromLTRB(18,18,18,MediaQuery.of(c).viewInsets.bottom+20),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      Text(existing==null?'Fiyat Kuralı Ekle':'Fiyat Kuralını Düzenle',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:14),
      TextField(controller:name,decoration:_input('Kural adı')),const SizedBox(height:8),
      DropdownButtonFormField(value:vehicle,items:const [DropdownMenuItem(value:'motorcycle',child:Text('Motosiklet')),DropdownMenuItem(value:'car',child:Text('Araç'))],onChanged:(v)=>setD(()=>vehicle=v!),decoration:_input('Araç tipi')),const SizedBox(height:8),
      Row(children:[Expanded(child:TextField(controller:base,keyboardType:TextInputType.number,decoration:_input('Baz fiyat'))),const SizedBox(width:8),Expanded(child:TextField(controller:km,keyboardType:TextInputType.number,decoration:_input('Km fiyatı')))]),const SizedBox(height:8),
      Row(children:[Expanded(child:TextField(controller:min,keyboardType:TextInputType.number,decoration:_input('Minimum'))),const SizedBox(width:8),Expanded(child:TextField(controller:courier,keyboardType:TextInputType.number,decoration:_input('Kurye payı %')))]),
      SwitchListTile(value:active,onChanged:(v)=>setD(()=>active=v),title:const Text('Aktif')),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Kaydet')))
    ])))));
    if (ok==true) {
      final share = double.tryParse(courier.text.replaceAll(',','.')) ?? 80;
      final values={'name':name.text.trim(),'vehicle_type':vehicle,'base_price':double.tryParse(base.text.replaceAll(',','.'))??0,'per_km_price':double.tryParse(km.text.replaceAll(',','.'))??0,'minimum_price':double.tryParse(min.text.replaceAll(',','.'))??0,'courier_share_percent':share,'platform_commission_percent':100-share,'is_active':active,'updated_at':DateTime.now().toUtc().toIso8601String()};
      if(existing==null) await data.client.from('pricing_rules').insert(values); else await data.client.from('pricing_rules').update(values).eq('id',existing['id']);
      await _load();
    }
    name.dispose();base.dispose();km.dispose();min.dispose();courier.dispose();
  }

  Future<void> _regionDialog({Map<String, dynamic>? existing}) async {
    final name=TextEditingController(text:existing?['name']?.toString()??'');
    final city=TextEditingController(text:existing?['city']?.toString()??'İstanbul');
    final district=TextEditingController(text:existing?['district']?.toString()??'');
    final extra=TextEditingController(text:existing?['extra_fee']?.toString()??'0');
    bool active=existing?['is_active']!=false;
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(c)=>StatefulBuilder(builder:(c,setD)=>Padding(padding:EdgeInsets.fromLTRB(18,18,18,MediaQuery.of(c).viewInsets.bottom+20),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(existing==null?'Bölge Ekle':'Bölge Düzenle',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:14),TextField(controller:name,decoration:_input('Bölge adı')),const SizedBox(height:8),TextField(controller:city,decoration:_input('Şehir')),const SizedBox(height:8),TextField(controller:district,decoration:_input('İlçe')),const SizedBox(height:8),TextField(controller:extra,keyboardType:TextInputType.number,decoration:_input('Ek ücret')),SwitchListTile(value:active,onChanged:(v)=>setD(()=>active=v),title:const Text('Aktif')),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Kaydet')))])))));
    if(ok==true){final values={'name':name.text.trim(),'city':city.text.trim(),'district':district.text.trim(),'extra_fee':double.tryParse(extra.text.replaceAll(',','.'))??0,'is_active':active,'updated_at':DateTime.now().toUtc().toIso8601String()};if(existing==null)await data.client.from('service_regions').insert(values);else await data.client.from('service_regions').update(values).eq('id',existing['id']);await _load();}
    name.dispose();city.dispose();district.dispose();extra.dispose();
  }

  Future<void> _payoutDetail(Map<String, dynamic> r) async {
    await _sheet('Ödeme Detayı', Icons.account_balance_wallet_rounded, [
      _kv('Tutar', '₺${r['amount'] ?? 0}'), _kv('Kurye', r['courier_id']), _kv('Durum', _statusTr(r['status']?.toString())), _kv('Oluşturulma', _date(r['created_at'])),
      const SizedBox(height: 12),
      Wrap(spacing:8,runSpacing:8,children:[
        _payAction(r,'processing','İşleniyor'),_payAction(r,'paid','Ödendi'),_payAction(r,'failed','Başarısız'),_payAction(r,'cancelled','İptal')
      ])
    ]);
  }

  Widget _payAction(Map<String,dynamic> r,String status,String label)=>FilledButton.tonal(onPressed:()async{Navigator.pop(context);await data.client.rpc('admin_update_payout_status',params:{'p_payout_id':r['id'],'p_status':status});await _load();},child:Text(label));

  Future<void> _sheet(String title, IconData icon, List<Widget> children) => showModalBottomSheet(
    context: context,isScrollControlled:true,backgroundColor:Colors.transparent,
    builder:(c)=>Container(padding:const EdgeInsets.fromLTRB(18,16,18,24),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(28))),child:SafeArea(top:false,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,mainAxisSize:MainAxisSize.min,children:[Row(children:[CircleAvatar(backgroundColor:const Color(0xFFEAF4FF),child:Icon(icon,color:blue)),const SizedBox(width:10),Expanded(child:Text(title,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900,color:navy)))]),const SizedBox(height:16),...children])))));

  Widget _kv(String label, dynamic value) => Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:105,child:Text(label,style:const TextStyle(color:muted,fontWeight:FontWeight.w700))),Expanded(child:Text('${value ?? '-'}',style:const TextStyle(color:navy,fontWeight:FontWeight.w800)))]));
  InputDecoration _input(String label)=>InputDecoration(labelText:label,filled:true,fillColor:const Color(0xFFF4F8FC),border:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:BorderSide.none));
  String _docName(String v)=>{'license':'Ehliyet','registration':'Ruhsat','insurance':'Sigorta','other':'Diğer'}[v]??v;
  String _statusTr(String? v)=>{'pending':'Bekleyen','processing':'İşleniyor','paid':'Ödendi','failed':'Başarısız','cancelled':'İptal','approved':'Onaylı','rejected':'Reddedilen'}[v]??(v??'-');
  String _date(dynamic v){final d=DateTime.tryParse('${v??''}')?.toLocal();if(d==null)return '-';return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';}
}
