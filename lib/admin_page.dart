import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF718198);
  final data = AppDataService.instance;

  bool loading = true;
  bool authorized = false;
  String? error;
  Map<String, dynamic> counts = const {};
  List<Map<String, dynamic>> users = const [];
  List<Map<String, dynamic>> couriers = const [];
  List<Map<String, dynamic>> shipments = const [];
  List<Map<String, dynamic>> documents = const [];
  List<Map<String, dynamic>> promos = const [];

  final phone = TextEditingController();
  final password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _check();
  }

  String _phone() {
    var v = phone.text.replaceAll(RegExp(r'\D'), '');
    if (v.startsWith('0')) v = v.substring(1);
    if (v.startsWith('90')) return '+$v';
    return '+90$v';
  }

  Future<void> _check() async {
    setState(() { loading = true; error = null; });
    try {
      if (!data.isSignedIn) {
        setState(() { authorized = false; loading = false; });
        return;
      }
      final row = await data.client.from('admin_users').select('role').eq('user_id', data.userId).maybeSingle();
      if (row == null) {
        setState(() { authorized = false; loading = false; error = 'Bu hesap admin yetkisine sahip değil.'; });
        return;
      }
      authorized = true;
      await _load();
    } catch (e) {
      setState(() { authorized = false; loading = false; error = e.toString(); });
    }
  }

  Future<void> _login() async {
    setState(() { loading = true; error = null; });
    try {
      await data.signInWithPhonePassword(phone: _phone(), password: password.text);
      await _check();
    } catch (e) {
      setState(() { loading = false; error = 'Giriş yapılamadı: $e'; });
    }
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        data.client.rpc('admin_dashboard_counts'),
        data.client.rpc('admin_list_users'),
        data.client.rpc('admin_list_couriers'),
        data.client.rpc('admin_list_shipments'),
        data.client.from('courier_documents').select().order('created_at', ascending: false),
        data.client.from('promo_banners').select().order('sort_order').order('created_at', ascending: false),
      ]);
      if (!mounted) return;
      setState(() {
        counts = Map<String, dynamic>.from(values[0] as Map);
        users = List<Map<String, dynamic>>.from(values[1] as List);
        couriers = List<Map<String, dynamic>>.from(values[2] as List);
        shipments = List<Map<String, dynamic>>.from(values[3] as List);
        documents = List<Map<String, dynamic>>.from(values[4] as List);
        promos = List<Map<String, dynamic>>.from(values[5] as List);
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> _setUserStatus(Map<String, dynamic> user) async {
    final next = user['account_status'] == 'suspended' ? 'active' : 'suspended';
    await data.client.rpc('admin_set_user_status', params: {'p_user_id': user['id'], 'p_status': next});
    await _load();
  }

  Future<void> _setCourierApproval(Map<String, dynamic> courier) async {
    await data.client.rpc('admin_set_courier_approval', params: {
      'p_user_id': courier['user_id'],
      'p_approved': courier['is_approved'] != true,
    });
    await _load();
  }

  Future<void> _cancelShipment(Map<String, dynamic> shipment) async {
    await data.client.rpc('admin_cancel_shipment', params: {'p_shipment_id': shipment['id']});
    await _load();
  }

  Future<void> _reviewDocument(Map<String, dynamic> doc, String status) async {
    String? reason;
    if (status == 'rejected') {
      final c = TextEditingController();
      reason = await showDialog<String>(context: context, builder: (d) => AlertDialog(
        title: const Text('Red nedeni'),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Örn. belge okunmuyor')),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Reddet'))],
      ));
      c.dispose();
      if (reason == null) return;
    }
    await data.client.rpc('admin_review_document', params: {'p_document_id': doc['id'], 'p_status': status, 'p_reason': reason});
    await _load();
  }

  Future<void> _promoDialog([Map<String, dynamic>? existing]) async {
    final title = TextEditingController(text: existing?['title']?.toString() ?? '');
    final subtitle = TextEditingController(text: existing?['subtitle']?.toString() ?? '');
    final image = TextEditingController(text: existing?['image_url']?.toString() ?? '');
    final actionLabel = TextEditingController(text: existing?['action_label']?.toString() ?? '');
    final actionUrl = TextEditingController(text: existing?['action_url']?.toString() ?? '');
    bool active = existing?['is_active'] != false;
    String audience = existing?['audience']?.toString() ?? 'customer';
    final ok = await showDialog<bool>(context: context, builder: (d) => StatefulBuilder(builder: (context, setD) => AlertDialog(
      title: Text(existing == null ? 'Promo Banner Ekle' : 'Promo Banner Düzenle'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Başlık')),
        TextField(controller: subtitle, decoration: const InputDecoration(labelText: 'Alt başlık')),
        TextField(controller: image, decoration: const InputDecoration(labelText: 'Görsel URL')),
        TextField(controller: actionLabel, decoration: const InputDecoration(labelText: 'Buton yazısı')),
        TextField(controller: actionUrl, decoration: const InputDecoration(labelText: 'Buton URL')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: audience, items: const [
          DropdownMenuItem(value: 'customer', child: Text('Müşteri')),
          DropdownMenuItem(value: 'courier', child: Text('Kurye')),
          DropdownMenuItem(value: 'all', child: Text('Tümü')),
        ], onChanged: (v) => setD(() => audience = v ?? 'customer'), decoration: const InputDecoration(labelText: 'Hedef')),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: active, onChanged: (v) => setD(() => active = v), title: const Text('Aktif')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Kaydet'))],
    )));
    if (ok == true && title.text.trim().isNotEmpty) {
      final values = {
        'title': title.text.trim(), 'subtitle': subtitle.text.trim(), 'image_url': image.text.trim(),
        'action_label': actionLabel.text.trim(), 'action_url': actionUrl.text.trim(), 'audience': audience,
        'is_active': active, 'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (existing == null) {
        await data.client.from('promo_banners').insert(values);
      } else {
        await data.client.from('promo_banners').update(values).eq('id', existing['id']);
      }
      await _load();
    }
    title.dispose(); subtitle.dispose(); image.dispose(); actionLabel.dispose(); actionUrl.dispose();
  }

  Future<void> _togglePromo(Map<String, dynamic> promo) async {
    await data.client.from('promo_banners').update({'is_active': promo['is_active'] != true, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', promo['id']);
    await _load();
  }

  Future<void> _deletePromo(Map<String, dynamic> promo) async {
    await data.client.from('promo_banners').delete().eq('id', promo['id']);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!authorized) return _loginView();

    return DefaultTabController(length: 5, child: Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Kurye Admin', style: TextStyle(fontWeight: FontWeight.w900, color: navy)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
        bottom: const TabBar(isScrollable: true, tabs: [
          Tab(text: 'Genel'), Tab(text: 'Kuryeler'), Tab(text: 'Kullanıcılar'), Tab(text: 'Gönderiler'), Tab(text: 'Belgeler & Promo'),
        ]),
      ),
      body: TabBarView(children: [_overview(), _couriers(), _users(), _shipments(), _documentsAndPromos()]),
    ));
  }

  Widget _loginView() => Scaffold(
    backgroundColor: const Color(0xFFF5FAFF),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.admin_panel_settings_rounded, size: 64, color: blue),
        const SizedBox(height: 14),
        const Text('Admin Girişi', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 20),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon', prefixText: '+90 ', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder())),
        if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: Colors.red))],
        const SizedBox(height: 14),
        FilledButton(onPressed: _login, child: const Text('Giriş Yap')),
      ]),
    ))),
  );

  Widget _overview() => RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Genel Bakış', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: navy)),
    const SizedBox(height: 14),
    Wrap(spacing: 10, runSpacing: 10, children: [
      _count('Kullanıcı', counts['users'], Icons.people_alt_rounded),
      _count('Kurye', counts['couriers'], Icons.two_wheeler_rounded),
      _count('Gönderi', counts['shipments'], Icons.inventory_2_rounded),
      _count('Bekleyen Belge', counts['pending_documents'], Icons.description_rounded),
      _count('Aktif Promo', counts['active_promos'], Icons.campaign_rounded),
    ]),
  ]));

  Widget _count(String label, dynamic value, IconData icon) => Container(width: 165, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: blue), const SizedBox(height: 10), Text('${value ?? 0}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: navy)), Text(label, style: const TextStyle(color: muted))]));

  Widget _couriers() => ListView.builder(padding: const EdgeInsets.all(14), itemCount: couriers.length, itemBuilder: (_, i) {
    final c = couriers[i];
    return Card(child: ListTile(
      leading: CircleAvatar(backgroundColor: const Color(0xFFEAF5FF), child: Icon(c['is_online'] == true ? Icons.two_wheeler : Icons.person, color: blue)),
      title: Text(c['user_id'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${c['vehicle_type'] ?? '-'} • ${c['is_online'] == true ? 'Online' : 'Offline'}'),
      trailing: FilledButton.tonal(onPressed: () => _setCourierApproval(c), child: Text(c['is_approved'] == true ? 'Onayı Kaldır' : 'Onayla')),
    ));
  });

  Widget _users() => ListView.builder(padding: const EdgeInsets.all(14), itemCount: users.length, itemBuilder: (_, i) {
    final u = users[i];
    final suspended = u['account_status'] == 'suspended';
    return Card(child: ListTile(
      leading: CircleAvatar(child: Text(((u['full_name'] ?? 'K').toString().trim().isEmpty ? 'K' : (u['full_name'] ?? 'K').toString()[0]).toUpperCase())),
      title: Text((u['full_name'] ?? 'Kullanıcı').toString()),
      subtitle: Text('${u['phone'] ?? ''}\n${u['email'] ?? ''}'),
      isThreeLine: true,
      trailing: FilledButton.tonal(onPressed: () => _setUserStatus(u), child: Text(suspended ? 'Aktifleştir' : 'Askıya Al')),
    ));
  });

  Widget _shipments() => ListView.builder(padding: const EdgeInsets.all(14), itemCount: shipments.length, itemBuilder: (_, i) {
    final s = shipments[i];
    final status = (s['status'] ?? '').toString();
    return Card(child: ListTile(
      leading: const CircleAvatar(backgroundColor: Color(0xFFEAF5FF), child: Icon(Icons.local_shipping_rounded, color: blue)),
      title: Text('${s['public_code'] ?? 'Gönderi'} • $status'),
      subtitle: Text('${s['pickup_address'] ?? ''}\n→ ${s['dropoff_address'] ?? ''}'),
      isThreeLine: true,
      trailing: status == 'delivered' || status == 'cancelled' ? null : IconButton(onPressed: () => _cancelShipment(s), icon: const Icon(Icons.cancel_outlined, color: Colors.red)),
    ));
  });

  Widget _documentsAndPromos() => ListView(padding: const EdgeInsets.all(14), children: [
    Row(children: [const Expanded(child: Text('Kurye Belgeleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy))), Text('${documents.length} belge', style: const TextStyle(color: muted))]),
    const SizedBox(height: 8),
    if (documents.isEmpty) const Card(child: ListTile(title: Text('Henüz yüklenmiş belge yok.'))),
    ...documents.map((d) => Card(child: ListTile(
      leading: const Icon(Icons.description_outlined, color: blue),
      title: Text('${d['document_type']} • ${d['status']}'),
      subtitle: Text('Kurye: ${d['courier_id']}${d['rejection_reason'] == null ? '' : '\n${d['rejection_reason']}'}'),
      trailing: d['status'] == 'pending' ? Wrap(spacing: 4, children: [IconButton(onPressed: () => _reviewDocument(d, 'approved'), icon: const Icon(Icons.check_circle, color: Colors.green)), IconButton(onPressed: () => _reviewDocument(d, 'rejected'), icon: const Icon(Icons.cancel, color: Colors.red))]) : null,
    ))),
    const SizedBox(height: 22),
    Row(children: [const Expanded(child: Text('Promo Bannerlar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy))), FilledButton.icon(onPressed: () => _promoDialog(), icon: const Icon(Icons.add), label: const Text('Ekle'))]),
    const SizedBox(height: 8),
    if (promos.isEmpty) const Card(child: ListTile(title: Text('Promo banner yok.'))),
    ...promos.map((p) => Card(child: ListTile(
      leading: CircleAvatar(backgroundColor: p['is_active'] == true ? const Color(0xFFE8FBF2) : const Color(0xFFF0F2F5), child: Icon(Icons.campaign_rounded, color: p['is_active'] == true ? Colors.green : muted)),
      title: Text((p['title'] ?? '').toString()),
      subtitle: Text('${p['audience']} • ${p['is_active'] == true ? 'Aktif' : 'Pasif'}'),
      onTap: () => _promoDialog(p),
      trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'toggle') _togglePromo(p); if (v == 'delete') _deletePromo(p); }, itemBuilder: (_) => [PopupMenuItem(value: 'toggle', child: Text(p['is_active'] == true ? 'Pasif Yap' : 'Aktif Yap')), const PopupMenuItem(value: 'delete', child: Text('Sil'))]),
    ))),
  ]);
}