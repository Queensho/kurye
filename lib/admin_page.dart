import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  static const blue = Color(0xFF168CF5);
  static const green = Color(0xFF20C997);
  static const purple = Color(0xFF7C5CFC);
  static const orange = Color(0xFFFFA726);
  static const red = Color(0xFFFF4D67);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF74839A);
  static const bg = Color(0xFFF4F8FC);

  final data = AppDataService.instance;
  final email = TextEditingController(text: 'admin@kurye.app');
  final password = TextEditingController();

  bool loading = true;
  bool authorized = false;
  String? error;
  int tab = 0;
  String shipmentFilter = 'Tümü';
  String courierFilter = 'Tümü';

  Map<String, dynamic> counts = const {};
  List<Map<String, dynamic>> users = const [];
  List<Map<String, dynamic>> couriers = const [];
  List<Map<String, dynamic>> shipments = const [];
  List<Map<String, dynamic>> documents = const [];
  List<Map<String, dynamic>> promos = const [];

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      if (!data.isSignedIn) {
        if (mounted) setState(() { authorized = false; loading = false; });
        return;
      }
      final row = await data.client
          .from('admin_users')
          .select('role')
          .eq('user_id', data.userId)
          .maybeSingle();
      if (row == null) {
        if (mounted) {
          setState(() {
            authorized = false;
            loading = false;
            error = 'Bu hesap admin yetkisine sahip değil.';
          });
        }
        return;
      }
      authorized = true;
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() {
          authorized = false;
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  Future<void> _login() async {
    final mail = email.text.trim();
    if (mail.isEmpty || password.text.isEmpty) {
      setState(() => error = 'E-posta ve şifreyi gir.');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      await data.client.auth.signInWithPassword(
        email: mail,
        password: password.text,
      );
      await _check();
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Giriş yapılamadı: E-posta veya şifre hatalı.';
        });
      }
    }
  }

  Future<void> _logout() async {
    await data.client.auth.signOut();
    if (!mounted) return;
    setState(() {
      authorized = false;
      tab = 0;
      loading = false;
    });
  }

  Future<void> _load() async {
    try {
      final countsValue = await data.client.rpc('admin_dashboard_counts');
      final usersValue = await data.client.rpc('admin_list_users');
      final couriersValue = await data.client.rpc('admin_list_couriers');
      final shipmentsValue = await data.client.rpc('admin_list_shipments');
      final documentsValue = await data.client
          .from('courier_documents')
          .select()
          .order('created_at', ascending: false);
      final promosValue = await data.client
          .from('promo_banners')
          .select()
          .order('sort_order')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        counts = Map<String, dynamic>.from(countsValue as Map);
        users = List<Map<String, dynamic>>.from(usersValue as List);
        couriers = List<Map<String, dynamic>>.from(couriersValue as List);
        shipments = List<Map<String, dynamic>>.from(shipmentsValue as List);
        documents = List<Map<String, dynamic>>.from(documentsValue);
        promos = List<Map<String, dynamic>>.from(promosValue);
        loading = false;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> _setUserStatus(Map<String, dynamic> user) async {
    final next = user['account_status'] == 'suspended' ? 'active' : 'suspended';
    await data.client.rpc('admin_set_user_status', params: {
      'p_user_id': user['id'],
      'p_status': next,
    });
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
    await data.client.rpc('admin_cancel_shipment', params: {
      'p_shipment_id': shipment['id'],
    });
    await _load();
  }

  Future<void> _reviewDocument(Map<String, dynamic> doc, String status) async {
    String? reason;
    if (status == 'rejected') {
      final c = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (d) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Belgeyi reddet'),
          content: TextField(
            controller: c,
            decoration: _input('Red nedeni', Icons.info_outline_rounded),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: () => Navigator.pop(d, c.text.trim()),
              child: const Text('Reddet'),
            ),
          ],
        ),
      );
      c.dispose();
      if (reason == null) return;
    }
    await data.client.rpc('admin_review_document', params: {
      'p_document_id': doc['id'],
      'p_status': status,
      'p_reason': reason,
    });
    await _load();
  }

  Future<void> _promoDialog({Map<String, dynamic>? existing, String? presetAudience}) async {
    final title = TextEditingController(text: existing?['title']?.toString() ?? '');
    final subtitle = TextEditingController(text: existing?['subtitle']?.toString() ?? '');
    final image = TextEditingController(text: existing?['image_url']?.toString() ?? '');
    final actionLabel = TextEditingController(text: existing?['action_label']?.toString() ?? '');
    final actionUrl = TextEditingController(text: existing?['action_url']?.toString() ?? '');
    final sortOrder = TextEditingController(text: '${existing?['sort_order'] ?? 0}');
    bool active = existing?['is_active'] != false;
    String audience = existing?['audience']?.toString() ?? presetAudience ?? 'customer';

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setD) => Container(
          constraints: const BoxConstraints(maxWidth: 680),
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7E0EA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.campaign_rounded, color: blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              existing == null ? 'Promo Banner Ekle' : 'Promo Banner Düzenle',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: navy,
                              ),
                            ),
                            const Text(
                              'Müşteri ve kurye uygulamalarında gösterilir.',
                              style: TextStyle(color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Gösterilecek alan', style: TextStyle(fontWeight: FontWeight.w800, color: navy)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _audienceChoice('customer', 'Müşteri', Icons.person_rounded, audience, (v) => setD(() => audience = v)),
                      _audienceChoice('courier', 'Kurye', Icons.two_wheeler_rounded, audience, (v) => setD(() => audience = v)),
                      _audienceChoice('all', 'Her İkisi', Icons.groups_rounded, audience, (v) => setD(() => audience = v)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: title, decoration: _input('Başlık', Icons.title_rounded)),
                  const SizedBox(height: 10),
                  TextField(controller: subtitle, maxLines: 2, decoration: _input('Alt başlık', Icons.notes_rounded)),
                  const SizedBox(height: 10),
                  TextField(controller: image, keyboardType: TextInputType.url, decoration: _input('Görsel URL', Icons.image_outlined)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: actionLabel, decoration: _input('Buton yazısı', Icons.smart_button_rounded))),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 105,
                        child: TextField(
                          controller: sortOrder,
                          keyboardType: TextInputType.number,
                          decoration: _input('Sıra', Icons.sort_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: actionUrl, keyboardType: TextInputType.url, decoration: _input('Buton URL', Icons.link_rounded)),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    activeColor: green,
                    onChanged: (v) => setD(() => active = v),
                    title: const Text('Banner aktif', style: TextStyle(fontWeight: FontWeight.w800, color: navy)),
                    subtitle: Text(active ? 'Uygulamada gösterilecek' : 'Yayından kaldırıldı'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (ok == true && title.text.trim().isNotEmpty) {
      final values = <String, dynamic>{
        'title': title.text.trim(),
        'subtitle': subtitle.text.trim(),
        'image_url': image.text.trim(),
        'action_label': actionLabel.text.trim(),
        'action_url': actionUrl.text.trim(),
        'audience': audience,
        'sort_order': int.tryParse(sortOrder.text.trim()) ?? 0,
        'is_active': active,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (existing == null) {
        await data.client.from('promo_banners').insert(values);
      } else {
        await data.client.from('promo_banners').update(values).eq('id', existing['id']);
      }
      await _load();
    }

    title.dispose();
    subtitle.dispose();
    image.dispose();
    actionLabel.dispose();
    actionUrl.dispose();
    sortOrder.dispose();
  }

  Widget _audienceChoice(
    String value,
    String label,
    IconData icon,
    String selected,
    ValueChanged<String> onTap,
  ) {
    final active = value == selected;
    return ChoiceChip(
      selected: active,
      onSelected: (_) => onTap(value),
      avatar: Icon(icon, size: 17, color: active ? Colors.white : blue),
      label: Text(label),
      labelStyle: TextStyle(
        color: active ? Colors.white : navy,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: blue,
      backgroundColor: const Color(0xFFF0F6FC),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Future<void> _togglePromo(Map<String, dynamic> promo) async {
    await data.client.from('promo_banners').update({
      'is_active': promo['is_active'] != true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', promo['id']);
    await _load();
  }

  Future<void> _deletePromo(Map<String, dynamic> promo) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Banner silinsin mi?'),
        content: Text('“${promo['title'] ?? ''}” kalıcı olarak silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: red),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await data.client.from('promo_banners').delete().eq('id', promo['id']);
    await _load();
  }

  InputDecoration _input(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF6F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: blue)),
      );
    }
    if (!authorized) return _loginView();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: IndexedStack(
              index: tab,
              children: [
                _home(),
                _shipmentsPage(),
                _couriersPage(),
                _reportsPage(),
                _menuPage(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _loginView() => Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 170,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF168CF5), Color(0xFF39B8FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: blue.withOpacity(.22),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text('K', style: TextStyle(color: Color(0xFF6DFF5A), fontSize: 42, fontWeight: FontWeight.w900)),
                              Text('Kurye', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          Text('Admin Panel', style: TextStyle(color: Colors.white70, fontSize: 15)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Admin Girişi', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: navy)),
                    const SizedBox(height: 6),
                    const Text('Yönetim paneline güvenli giriş yap.', style: TextStyle(color: muted)),
                    const SizedBox(height: 22),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: _input('E-posta', Icons.email_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      onSubmitted: (_) => _login(),
                      decoration: _input('Şifre', Icons.lock_outline_rounded),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(error!, style: const TextStyle(color: red, fontWeight: FontWeight.w700)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _login,
                        child: const Text('Giriş Yap', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _header(String title, {String? subtitle, Widget? action}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: navy)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: muted)),
                  ],
                ],
              ),
            ),
            if (action != null) action,
          ],
        ),
      );

  Widget _home() => RefreshIndicator(
        onRefresh: _load,
        color: blue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF168CF5), Color(0xFF45C5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: blue.withOpacity(.22), blurRadius: 24, offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Text('K', style: TextStyle(color: Color(0xFF68FF55), fontSize: 34, fontWeight: FontWeight.w900)),
                            Text('Kurye', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      _circleAction(Icons.refresh_rounded, _load),
                      const SizedBox(width: 8),
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white24,
                        child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text('Merhaba, Admin 👋', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  const Text('Bugün platformda neler oluyor?', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, c) {
                  final width = (c.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metric(width, 'Gönderi', counts['shipments'], Icons.inventory_2_rounded, purple, 'Toplam'),
                      _metric(width, 'Kurye', counts['couriers'], Icons.two_wheeler_rounded, orange, '${_onlineCouriers()} online'),
                      _metric(width, 'Kullanıcı', counts['users'], Icons.people_alt_rounded, blue, 'Kayıtlı'),
                      _metric(width, 'Aktif Promo', counts['active_promos'], Icons.campaign_rounded, green, 'Yayında'),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Hızlı Erişim'),
            SizedBox(
              height: 122,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _quick('Siparişler', Icons.inventory_2_rounded, purple, () => setState(() => tab = 1)),
                  _quick('Kuryeler', Icons.two_wheeler_rounded, green, () => setState(() => tab = 2)),
                  _quick('Raporlar', Icons.bar_chart_rounded, blue, () => setState(() => tab = 3)),
                  _quick('Promo', Icons.campaign_rounded, orange, () => setState(() => tab = 4)),
                ],
              ),
            ),
            _sectionTitle('Son Gönderiler', action: TextButton(onPressed: () => setState(() => tab = 1), child: const Text('Tümünü Gör'))),
            ...shipments.take(4).map(_shipmentCard),
            if (shipments.isEmpty) _empty('Henüz gönderi yok', Icons.inventory_2_outlined),
          ],
        ),
      );

  int _onlineCouriers() => couriers.where((c) => c['is_online'] == true).length;

  Widget _metric(double width, String title, dynamic value, IconData icon, Color color, String note) => Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: navy.withOpacity(.05), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 13),
            Text('${value ?? 0}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: navy)),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
            const SizedBox(height: 2),
            Text(note, style: const TextStyle(fontSize: 12, color: muted)),
          ],
        ),
      );

  Widget _quick(String label, IconData icon, Color color, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(23),
          onTap: onTap,
          child: Container(
            width: 105,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 49,
                  height: 49,
                  decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
              ],
            ),
          ),
        ),
      );

  Widget _shipmentsPage() {
    final filtered = shipments.where((s) {
      final status = (s['status'] ?? '').toString();
      if (shipmentFilter == 'Tümü') return true;
      if (shipmentFilter == 'Yeni') return status == 'searching' || status == 'pending';
      if (shipmentFilter == 'Yolda') return ['accepted', 'at_pickup', 'picked_up', 'at_dropoff'].contains(status);
      if (shipmentFilter == 'Teslim') return status == 'delivered';
      if (shipmentFilter == 'İptal') return status == 'cancelled';
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 26),
        children: [
          _header('Siparişler', subtitle: '${shipments.length} gönderi', action: _roundIcon(Icons.refresh_rounded, _load)),
          _filterRow(['Tümü', 'Yeni', 'Yolda', 'Teslim', 'İptal'], shipmentFilter, (v) => setState(() => shipmentFilter = v)),
          const SizedBox(height: 8),
          ...filtered.map(_shipmentCard),
          if (filtered.isEmpty) _empty('Bu filtrede gönderi yok', Icons.inventory_2_outlined),
        ],
      ),
    );
  }

  Widget _shipmentCard(Map<String, dynamic> s) {
    final status = (s['status'] ?? '').toString();
    final code = (s['public_code'] ?? '#Gönderi').toString();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [BoxShadow(color: navy.withOpacity(.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: orange.withOpacity(.13), borderRadius: BorderRadius.circular(17)),
            child: const Icon(Icons.inventory_2_rounded, color: orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(code, style: const TextStyle(fontWeight: FontWeight.w900, color: navy))),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 6),
                Text((s['pickup_address'] ?? 'Alım adresi').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: navy)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_rounded, size: 15, color: muted),
                    const SizedBox(width: 4),
                    Expanded(child: Text((s['dropoff_address'] ?? 'Teslimat adresi').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 13))),
                  ],
                ),
                if (status != 'delivered' && status != 'cancelled') ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: red),
                      onPressed: () => _cancelShipment(s),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('İptal Et'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color c;
    String text;
    switch (status) {
      case 'delivered': c = green; text = 'Teslim'; break;
      case 'cancelled': c = red; text = 'İptal'; break;
      case 'searching': c = purple; text = 'Havuzda'; break;
      case 'accepted': c = blue; text = 'Alındı'; break;
      case 'at_pickup': c = orange; text = 'Alımda'; break;
      case 'picked_up': c = blue; text = 'Yolda'; break;
      case 'at_dropoff': c = green; text = 'Teslimatta'; break;
      default: c = muted; text = status.isEmpty ? 'Yeni' : status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: c.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }

  Widget _couriersPage() {
    final filtered = couriers.where((c) {
      if (courierFilter == 'Tümü') return true;
      if (courierFilter == 'Online') return c['is_online'] == true;
      if (courierFilter == 'Onaylı') return c['is_approved'] == true;
      if (courierFilter == 'Bekleyen') return c['is_approved'] != true;
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 26),
        children: [
          _header('Kuryeler', subtitle: '${_onlineCouriers()} kurye online', action: _roundIcon(Icons.refresh_rounded, _load)),
          _filterRow(['Tümü', 'Online', 'Onaylı', 'Bekleyen'], courierFilter, (v) => setState(() => courierFilter = v)),
          const SizedBox(height: 8),
          ...filtered.map(_courierCard),
          if (filtered.isEmpty) _empty('Kurye bulunamadı', Icons.two_wheeler_rounded),
        ],
      ),
    );
  }

  Widget _courierCard(Map<String, dynamic> c) {
    final online = c['is_online'] == true;
    final approved = c['is_approved'] == true;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23)),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFEAF4FF),
                child: Icon(Icons.person_rounded, color: online ? blue : muted),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: online ? green : const Color(0xFFBCC5D1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kurye ${_shortId(c['user_id'])}', style: const TextStyle(fontWeight: FontWeight.w900, color: navy)),
                const SizedBox(height: 3),
                Text('${c['vehicle_type'] ?? 'Araç belirtilmedi'} • ${online ? 'Online' : 'Offline'}', style: TextStyle(color: online ? green : muted, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: approved ? red : green,
              backgroundColor: (approved ? red : green).withOpacity(.10),
            ),
            onPressed: () => _setCourierApproval(c),
            child: Text(approved ? 'Onayı Kaldır' : 'Onayla'),
          ),
        ],
      ),
    );
  }

  String _shortId(dynamic id) {
    final s = (id ?? '').toString();
    if (s.length <= 6) return s;
    return s.substring(0, 6).toUpperCase();
  }

  Widget _reportsPage() {
    final delivered = shipments.where((s) => s['status'] == 'delivered').length;
    final cancelled = shipments.where((s) => s['status'] == 'cancelled').length;
    final active = shipments.length - delivered - cancelled;
    final total = shipments.isEmpty ? 1 : shipments.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 26),
        children: [
          _header('Raporlar', subtitle: 'Platform özeti', action: _roundIcon(Icons.refresh_rounded, _load)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _reportSummary('Toplam Gönderi', shipments.length, Icons.inventory_2_rounded, purple)),
                const SizedBox(width: 10),
                Expanded(child: _reportSummary('Aktif Kurye', _onlineCouriers(), Icons.two_wheeler_rounded, green)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sipariş Durumları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: navy)),
                const SizedBox(height: 18),
                _progress('Teslim Edildi', delivered, total, green),
                const SizedBox(height: 14),
                _progress('Aktif / Yolda', active < 0 ? 0 : active, total, blue),
                const SizedBox(height: 14),
                _progress('İptal', cancelled, total, red),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yönetim Durumu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: navy)),
                const SizedBox(height: 14),
                _infoLine(Icons.description_rounded, 'Bekleyen belge', '${counts['pending_documents'] ?? 0}', orange),
                _infoLine(Icons.campaign_rounded, 'Aktif promo', '${counts['active_promos'] ?? 0}', purple),
                _infoLine(Icons.people_alt_rounded, 'Kullanıcı', '${counts['users'] ?? 0}', blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportSummary(String label, int value, IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text('$value', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: navy)),
            Text(label, style: const TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      );

  Widget _progress(String label, int value, int total, Color color) {
    final ratio = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: navy))),
            Text('$value', style: TextStyle(fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: ratio,
            backgroundColor: color.withOpacity(.10),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _menuPage() => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            _header('Menü', subtitle: 'Yönetim ve içerik ayarları'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: const Row(
                children: [
                  CircleAvatar(radius: 27, backgroundColor: Color(0xFFEAF4FF), child: Text('A', style: TextStyle(color: blue, fontWeight: FontWeight.w900, fontSize: 20))),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: navy)),
                    Text('admin@kurye.app', style: TextStyle(color: muted)),
                  ])),
                  Icon(Icons.verified_rounded, color: blue),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('Promo Banner Yönetimi', action: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: blue),
              onPressed: () => _promoDialog(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Yeni'),
            )),
            _promoAudienceSection('Müşteri Uygulaması', 'customer', Icons.person_rounded, blue),
            _promoAudienceSection('Kurye Uygulaması', 'courier', Icons.two_wheeler_rounded, green),
            _promoAudienceSection('Her İkisinde', 'all', Icons.groups_rounded, purple),
            const SizedBox(height: 18),
            _sectionTitle('Kurye Belgeleri'),
            ...documents.take(8).map(_documentCard),
            if (documents.isEmpty) _empty('Henüz yüklenmiş belge yok', Icons.description_outlined),
            const SizedBox(height: 18),
            _sectionTitle('Kullanıcı Yönetimi'),
            ...users.take(8).map(_userCard),
            if (users.isEmpty) _empty('Kullanıcı bulunamadı', Icons.people_outline_rounded),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _promoAudienceSection(String title, String audience, IconData icon, Color color) {
    final list = promos.where((p) => p['audience'] == audience).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: navy)),
                Text('${list.length} banner', style: const TextStyle(color: muted, fontSize: 12)),
              ])),
              IconButton(
                tooltip: 'Banner ekle',
                onPressed: () => _promoDialog(presetAudience: audience),
                icon: const Icon(Icons.add_circle_rounded, color: blue),
              ),
            ],
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text('$title için banner yok.', style: const TextStyle(color: muted)),
            ),
          ...list.map(_promoCard),
        ],
      ),
    );
  }

  Widget _promoCard(Map<String, dynamic> p) {
    final active = p['is_active'] == true;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EEF6)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: active ? [blue, const Color(0xFF52C7FF)] : [const Color(0xFFADB8C6), const Color(0xFFD0D7DF)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.campaign_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((p['title'] ?? 'Banner').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: navy)),
                const SizedBox(height: 3),
                Text(active ? 'Aktif • Sıra ${p['sort_order'] ?? 0}' : 'Pasif • Sıra ${p['sort_order'] ?? 0}', style: TextStyle(color: active ? green : muted, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _promoDialog(existing: p);
              if (v == 'toggle') _togglePromo(p);
              if (v == 'delete') _deletePromo(p);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Düzenle'))),
              PopupMenuItem(value: 'toggle', child: ListTile(leading: Icon(active ? Icons.visibility_off_outlined : Icons.visibility_outlined), title: Text(active ? 'Pasif Yap' : 'Aktif Yap'))),
              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded, color: red), title: Text('Sil'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _documentCard(Map<String, dynamic> d) {
    final status = (d['status'] ?? 'pending').toString();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21)),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Color(0xFFEAF4FF), child: Icon(Icons.description_rounded, color: blue)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((d['document_type'] ?? 'Belge').toString(), style: const TextStyle(fontWeight: FontWeight.w900, color: navy)),
            Text('${_shortId(d['courier_id'])} • $status', style: const TextStyle(color: muted, fontSize: 12)),
          ])),
          if (status == 'pending') ...[
            IconButton(onPressed: () => _reviewDocument(d, 'approved'), icon: const Icon(Icons.check_circle_rounded, color: green)),
            IconButton(onPressed: () => _reviewDocument(d, 'rejected'), icon: const Icon(Icons.cancel_rounded, color: red)),
          ] else
            _statusBadge(status),
        ],
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> u) {
    final suspended = u['account_status'] == 'suspended';
    final name = (u['full_name'] ?? 'Kullanıcı').toString();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF4FF),
            child: Text(name.isEmpty ? 'K' : name[0].toUpperCase(), style: const TextStyle(color: blue, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w900, color: navy)),
            Text((u['phone'] ?? u['email'] ?? '').toString(), style: const TextStyle(color: muted, fontSize: 12)),
          ])),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: suspended ? green : red),
            onPressed: () => _setUserStatus(u),
            child: Text(suspended ? 'Aktifleştir' : 'Askıya Al'),
          ),
        ],
      ),
    );
  }

  Widget _filterRow(List<String> items, String selected, ValueChanged<String> onChanged) => SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final value = items[i];
            final active = value == selected;
            return ChoiceChip(
              selected: active,
              onSelected: (_) => onChanged(value),
              label: Text(value),
              labelStyle: TextStyle(color: active ? Colors.white : navy, fontWeight: FontWeight.w800),
              selectedColor: blue,
              backgroundColor: Colors.white,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            );
          },
        ),
      );

  Widget _sectionTitle(String title, {Widget? action}) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 2, 16, 10),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: navy))),
            if (action != null) action,
          ],
        ),
      );

  Widget _infoLine(IconData icon, String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: navy))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: navy)),
          ],
        ),
      );

  Widget _empty(String text, IconData icon) => Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: Column(
          children: [
            Icon(icon, size: 36, color: const Color(0xFFB6C3D2)),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: muted, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _circleAction(IconData icon, VoidCallback onTap) => Material(
        color: Colors.white24,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 42, height: 42, child: Icon(icon, color: Colors.white)),
        ),
      );

  Widget _roundIcon(IconData icon, VoidCallback onTap) => IconButton.filledTonal(
        style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: blue),
        onPressed: onTap,
        icon: Icon(icon),
      );

  Widget _bottomNav() => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(27),
            boxShadow: [BoxShadow(color: navy.withOpacity(.10), blurRadius: 25, offset: const Offset(0, 8))],
          ),
          child: NavigationBar(
            height: 64,
            elevation: 0,
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0xFFE8F4FF),
            selectedIndex: tab,
            onDestinationSelected: (v) => setState(() => tab = v),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: blue), label: 'Ana Sayfa'),
              NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded, color: blue), label: 'Siparişler'),
              NavigationDestination(icon: Icon(Icons.two_wheeler_outlined), selectedIcon: Icon(Icons.two_wheeler_rounded, color: blue), label: 'Kuryeler'),
              NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded, color: blue), label: 'Raporlar'),
              NavigationDestination(icon: Icon(Icons.menu_rounded), selectedIcon: Icon(Icons.menu_rounded, color: blue), label: 'Menü'),
            ],
          ),
        ),
      );
}