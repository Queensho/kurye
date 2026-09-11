import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'courier_earnings_page.dart';
import 'data/app_data_service.dart';

class CourierProfilePage extends StatefulWidget {
  const CourierProfilePage({super.key});

  @override
  State<CourierProfilePage> createState() => _CourierProfilePageState();
}

class _CourierProfilePageState extends State<CourierProfilePage> {
  static const purple = Color(0xFF4B20B8);
  static const deepPurple = Color(0xFF28106E);
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF171052);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);
  static const green = Color(0xFF20C875);

  final data = AppDataService.instance;
  bool loading = true;
  Map<String, dynamic> profile = {};
  Map<String, dynamic> courier = {};
  Map<String, dynamic> earnings = {};
  List<Map<String, dynamic>> shipments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await data.getProfile();
      Map<String, dynamic> c = {};
      Map<String, dynamic> e = {};
      List<Map<String, dynamic>> s = [];
      try {
        final raw = await data.client.from('couriers').select().eq('user_id', data.userId).maybeSingle();
        if (raw != null) c = Map<String, dynamic>.from(raw);
      } catch (_) {}
      try { e = await data.getCourierEarningsSummary(); } catch (_) {}
      try {
        final raw = await data.client.from('shipments').select().eq('courier_id', data.userId).order('created_at', ascending: false).limit(250);
        s = List<Map<String, dynamic>>.from(raw);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        profile = p;
        courier = c;
        earnings = e;
        shipments = s;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  String get _name => (profile['full_name'] ?? 'Kurye').toString().trim();
  String get _city => (profile['city'] ?? 'İstanbul').toString().trim();
  String get _avatar => (profile['avatar_url'] ?? '').toString().trim();

  int get _completed => shipments.where((e) => e['status'] == 'delivered').length;
  int get _countable => shipments.where((e) => e['status'] != 'cancelled').length;
  int get _completionRate => _countable == 0 ? 0 : ((_completed / _countable) * 100).round().clamp(0, 100);
  double get _rating {
    final raw = courier['rating'] ?? profile['rating'];
    return raw is num ? raw.toDouble() : 0;
  }

  double get _todayDistance {
    final now = DateTime.now();
    double total = 0;
    for (final item in shipments) {
      final d = DateTime.tryParse((item['created_at'] ?? '').toString())?.toLocal();
      if (d != null && d.year == now.year && d.month == now.month && d.day == now.day) {
        final km = item['distance_km'];
        if (km is num) total += km.toDouble();
      }
    }
    return total;
  }

  int get _todayDeliveries {
    final now = DateTime.now();
    return shipments.where((item) {
      final d = DateTime.tryParse((item['delivered_at'] ?? item['created_at'] ?? '').toString())?.toLocal();
      return item['status'] == 'delivered' && d != null && d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
  }

  String _money(dynamic raw) {
    if (raw is num) {
      final d = raw.toDouble();
      return d == d.roundToDouble() ? '₺${d.toInt()}' : '₺${d.toStringAsFixed(2)}';
    }
    return '₺0';
  }

  Future<void> _openEdit() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourierProfileEditPage(profile: profile, courier: courier)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: purple))
            : LayoutBuilder(builder: (context, constraints) {
                final s = (constraints.maxWidth / 390).clamp(.92, 1.08).toDouble();
                return Column(children: [
                  Expanded(child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Column(children: [
                    _hero(s),
                    Transform.translate(offset: Offset(0, -28 * s), child: _profileCard(s)),
                    Transform.translate(offset: Offset(0, -16 * s), child: _stats(s)),
                    Transform.translate(offset: Offset(0, -8 * s), child: _trust(s)),
                    _earningsSection(s),
                    SizedBox(height: 14 * s),
                    _dayStats(s),
                    SizedBox(height: 22 * s),
                  ]))),
                  _bottomNav(s),
                ]);
              }),
      ),
    );
  }

  Widget _hero(double s) => SizedBox(
        height: 286 * s,
        child: Stack(fit: StackFit.expand, children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [deepPurple, Color(0xFF5B26CE)]), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)))),
          Positioned(left: -22 * s, bottom: -16 * s, width: 300 * s, height: 260 * s, child: Image.asset('assets/images/Ofline.png', fit: BoxFit.cover, alignment: Alignment.bottomLeft)),
          Positioned(left: 18 * s, top: 18 * s, child: Text('Profilim', style: TextStyle(color: Colors.white, fontSize: 23 * s, fontWeight: FontWeight.w900))),
          Positioned(right: 17 * s, top: 14 * s, child: Material(color: Colors.white.withValues(alpha: .13), shape: const CircleBorder(), child: InkWell(onTap: _openEdit, customBorder: const CircleBorder(), child: SizedBox(width: 42 * s, height: 42 * s, child: Icon(Icons.settings_rounded, color: Colors.white, size: 22 * s))))),
          Positioned(right: 24 * s, bottom: 50 * s, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Yola\nDevam!', textAlign: TextAlign.right, style: TextStyle(color: Colors.white.withValues(alpha: .62), fontSize: 22 * s, height: 1.05, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700)),
            SizedBox(height: 12 * s),
            Container(padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 8 * s), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(17 * s)), child: Row(children: [Icon(Icons.workspace_premium_rounded, color: const Color(0xFFFFC83D), size: 17 * s), SizedBox(width: 6 * s), Text('Kurye', style: TextStyle(color: Colors.white, fontSize: 11 * s, fontWeight: FontWeight.w800))])),
          ])),
        ]),
      );

  Widget _profileCard(double s) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * s),
        child: Container(
          padding: EdgeInsets.fromLTRB(15 * s, 13 * s, 15 * s, 15 * s),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23 * s), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 7))]),
          child: Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              CircleAvatar(radius: 38 * s, backgroundColor: const Color(0xFFEDE8FF), backgroundImage: _avatar.isEmpty ? null : NetworkImage(_avatar), child: _avatar.isEmpty ? Icon(Icons.person_rounded, size: 42 * s, color: purple) : null),
              Positioned(right: -1, bottom: 0, child: Container(width: 18 * s, height: 18 * s, decoration: BoxDecoration(color: green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: Icon(Icons.check, size: 10 * s, color: Colors.white))),
            ]),
            SizedBox(width: 12 * s),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_name.isEmpty ? 'Kurye' : _name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: navy, fontSize: 18 * s, fontWeight: FontWeight.w900)), SizedBox(height: 2 * s), Text('Uber Kurye • $_city', style: TextStyle(color: muted, fontSize: 10.5 * s))])),
            OutlinedButton.icon(onPressed: _openEdit, icon: Icon(Icons.edit_outlined, size: 16 * s), label: Text('Profili Düzenle', style: TextStyle(fontSize: 9.5 * s, fontWeight: FontWeight.w800)), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: purple, side: BorderSide.none, padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 12 * s), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17 * s))))
          ]),
        ),
      );

  Widget _stats(double s) {
    final ratingText = _rating > 0 ? _rating.toStringAsFixed(1) : '—';
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16 * s), child: Row(children: [
      Expanded(child: _statCard(Icons.star_rounded, const Color(0xFFFFB321), ratingText, 'Değerlendirme', s)),
      SizedBox(width: 8 * s),
      Expanded(child: _statCard(Icons.inventory_2_rounded, purple, '$_completed', 'Teslimat', s)),
      SizedBox(width: 8 * s),
      Expanded(child: _statCard(Icons.verified_user_rounded, green, '%$_completionRate', 'Tamamlama', s)),
    ]));
  }

  Widget _statCard(IconData icon, Color color, String value, String label, double s) => Container(height: 84 * s, padding: EdgeInsets.all(10 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17 * s), boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 10, offset: Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Row(children: [Icon(icon, color: color, size: 19 * s), SizedBox(width: 5 * s), Flexible(child: Text(value, maxLines: 1, style: TextStyle(color: navy, fontSize: 17 * s, fontWeight: FontWeight.w900)))]), SizedBox(height: 4 * s), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 9 * s))]));

  Widget _trust(double s) => Padding(padding: EdgeInsets.symmetric(horizontal: 16 * s), child: Container(height: 58 * s, padding: EdgeInsets.symmetric(horizontal: 13 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17 * s)), child: Row(children: [Container(width: 36 * s, height: 36 * s, decoration: const BoxDecoration(color: Color(0xFFFFF3CF), shape: BoxShape.circle), child: Icon(Icons.workspace_premium_rounded, color: const Color(0xFFFFA900), size: 23 * s)), SizedBox(width: 10 * s), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Güvenilir Kurye', style: TextStyle(color: navy, fontSize: 12.5 * s, fontWeight: FontWeight.w900)), Text('Performansını yüksek tut, avantajları artır.', style: TextStyle(color: muted, fontSize: 9 * s))])), Icon(Icons.chevron_right_rounded, color: navy, size: 23 * s)])));

  Widget _earningsSection(double s) {
    final daily = earnings['today_earnings'] ?? earnings['available_balance'] ?? 0;
    final week = earnings['week_earnings'] ?? 0;
    final month = earnings['month_earnings'] ?? 0;
    final values = [0.32, 0.48, 0.63, 0.43, 0.78, 0.58, 0.68, 0.88];
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16 * s), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Kazançlarım', style: TextStyle(color: navy, fontSize: 15.5 * s, fontWeight: FontWeight.w900))), TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourierEarningsPage())), child: Text('Tümünü Gör', style: TextStyle(color: purple, fontSize: 10 * s, fontWeight: FontWeight.w700)))]),
      Container(height: 38 * s, padding: EdgeInsets.all(3 * s), decoration: BoxDecoration(color: const Color(0xFFEFEFF4), borderRadius: BorderRadius.circular(20 * s)), child: Row(children: [Expanded(child: Container(alignment: Alignment.center, decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(17 * s)), child: Text('Günlük', style: TextStyle(color: Colors.white, fontSize: 9.5 * s, fontWeight: FontWeight.w700)))), Expanded(child: Center(child: Text('Haftalık', style: TextStyle(color: muted, fontSize: 9.5 * s)))), Expanded(child: Center(child: Text('Aylık', style: TextStyle(color: muted, fontSize: 9.5 * s))))])),
      SizedBox(height: 14 * s),
      SizedBox(height: 118 * s, child: Column(children: [Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [for (final v in values) Container(width: 26 * s, height: 78 * s * v, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [purple.withValues(alpha: .9), purple.withValues(alpha: .38)]), borderRadius: BorderRadius.circular(5 * s)))])), SizedBox(height: 6 * s), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [for (final d in ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz','']) SizedBox(width: 26 * s, child: Text(d, textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 8 * s)))])])),
      SizedBox(height: 4 * s),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bugün ${_money(daily)}', style: TextStyle(color: navy, fontSize: 10 * s, fontWeight: FontWeight.w800)), Text('Hafta ${_money(week)} • Ay ${_money(month)}', style: TextStyle(color: muted, fontSize: 9 * s))]),
    ]));
  }

  Widget _dayStats(double s) => Padding(padding: EdgeInsets.symmetric(horizontal: 16 * s), child: GridView.count(crossAxisCount: 2, physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, childAspectRatio: 1.7, mainAxisSpacing: 9 * s, crossAxisSpacing: 9 * s, children: [
    _miniCard(Icons.timer_outlined, purple, 'Aktif Süre', '—', 'Bugün', s),
    _miniCard(Icons.route_rounded, orange, 'Mesafe', '${_todayDistance.toStringAsFixed(0)} km', 'Bugün', s),
    _miniCard(Icons.inventory_2_rounded, const Color(0xFFFFA14A), 'Teslimat', '$_todayDeliveries', 'Bugün', s),
    _miniCard(Icons.bolt_rounded, const Color(0xFFFFB11B), 'Ortalama Süre', '—', 'Teslimat başına', s),
  ]));

  Widget _miniCard(IconData icon, Color color, String title, String value, String subtitle, double s) => Container(padding: EdgeInsets.all(12 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17 * s), border: Border.all(color: const Color(0xFFEAE8F0))), child: Row(children: [Container(width: 39 * s, height: 39 * s, decoration: BoxDecoration(color: color.withValues(alpha: .10), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22 * s)), SizedBox(width: 10 * s), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: muted, fontSize: 9 * s)), SizedBox(height: 2 * s), Text(value, style: TextStyle(color: navy, fontSize: 14 * s, fontWeight: FontWeight.w900)), Text(subtitle, style: TextStyle(color: muted, fontSize: 8 * s))]))]));

  Widget _bottomNav(double s) => Container(height: 72 * s, padding: EdgeInsets.fromLTRB(7 * s, 7 * s, 7 * s, 9 * s), decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -3))]), child: Row(children: [
    _nav(Icons.layers_rounded, 'Havuz', false, () => Navigator.maybePop(context), s),
    _nav(Icons.work_outline_rounded, 'Atananlar', false, () => Navigator.maybePop(context), s),
    _nav(Icons.bar_chart_rounded, 'Kazançlar', false, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourierEarningsPage())), s),
    _nav(Icons.person_rounded, 'Profil', true, () {}, s),
  ]));

  Widget _nav(IconData icon, String label, bool active, VoidCallback onTap, double s) => Expanded(child: InkWell(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: active ? orange : const Color(0xFF687084), size: 20 * s), SizedBox(height: 4 * s), Text(label, style: TextStyle(color: active ? orange : const Color(0xFF687084), fontSize: 8.5 * s, fontWeight: active ? FontWeight.w800 : FontWeight.w500))])));
}

class CourierProfileEditPage extends StatefulWidget {
  const CourierProfileEditPage({super.key, required this.profile, required this.courier});
  final Map<String, dynamic> profile;
  final Map<String, dynamic> courier;

  @override
  State<CourierProfileEditPage> createState() => _CourierProfileEditPageState();
}

class _CourierProfileEditPageState extends State<CourierProfileEditPage> {
  static const purple = Color(0xFF4B20B8);
  static const deepPurple = Color(0xFF28106E);
  static const navy = Color(0xFF171052);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);
  static const red = Color(0xFFE33A3A);

  final data = AppDataService.instance;
  final picker = ImagePicker();
  late TextEditingController name, phone, email, city, vehicle, plate, color, license;
  Uint8List? avatarBytes;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: (widget.profile['full_name'] ?? '').toString());
    phone = TextEditingController(text: (widget.profile['phone'] ?? '').toString());
    email = TextEditingController(text: (widget.profile['email'] ?? '').toString());
    city = TextEditingController(text: (widget.profile['city'] ?? '').toString());
    vehicle = TextEditingController(text: (widget.courier['vehicle_model'] ?? widget.courier['vehicle_type'] ?? '').toString());
    plate = TextEditingController(text: (widget.courier['plate'] ?? '').toString());
    color = TextEditingController(text: (widget.courier['vehicle_color'] ?? '').toString());
    license = TextEditingController(text: (widget.courier['license_class'] ?? '').toString());
  }

  @override
  void dispose() {
    name.dispose(); phone.dispose(); email.dispose(); city.dispose(); vehicle.dispose(); plate.dispose(); color.dispose(); license.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 900);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => avatarBytes = bytes);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await data.updateProfile(fullName: name.text.trim(), phone: phone.text.trim(), email: email.text.trim());
      try { await data.client.from('profiles').update({'city': city.text.trim()}).eq('id', data.userId); } catch (_) {}
      final update = <String, dynamic>{};
      if (widget.courier.containsKey('vehicle_model')) update['vehicle_model'] = vehicle.text.trim();
      if (widget.courier.containsKey('plate')) update['plate'] = plate.text.trim().toUpperCase();
      if (widget.courier.containsKey('vehicle_color')) update['vehicle_color'] = color.text.trim();
      if (widget.courier.containsKey('license_class')) update['license_class'] = license.text.trim().toUpperCase();
      if (update.isNotEmpty) { try { await data.client.from('couriers').update(update).eq('user_id', data.userId); } catch (_) {} }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _logout() async {
    await data.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = (widget.profile['avatar_url'] ?? '').toString();
    return Scaffold(backgroundColor: bg, body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
      final s = (constraints.maxWidth / 390).clamp(.92, 1.08).toDouble();
      return SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _editHero(avatarUrl, s),
        Padding(padding: EdgeInsets.fromLTRB(17 * s, 18 * s, 17 * s, 26 * s), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Temel Bilgiler', s), SizedBox(height: 10 * s),
          _group([_field(Icons.person_outline_rounded, 'Ad Soyad', name, s), _field(Icons.phone_outlined, 'Telefon', phone, s, keyboard: TextInputType.phone), _field(Icons.mail_outline_rounded, 'E-posta', email, s, keyboard: TextInputType.emailAddress), _field(Icons.location_on_outlined, 'Şehir', city, s)], s),
          SizedBox(height: 20 * s), _sectionTitle('Araç Bilgileri', s), SizedBox(height: 10 * s),
          _group([_field(Icons.two_wheeler_rounded, 'Araç', vehicle, s), _field(Icons.pin_outlined, 'Plaka', plate, s), _field(Icons.water_drop_outlined, 'Renk', color, s), _field(Icons.description_outlined, 'Ehliyet', license, s)], s),
          SizedBox(height: 20 * s), _sectionTitle('Hesap ve Güvenlik', s), SizedBox(height: 10 * s), _menuGroup(s), SizedBox(height: 18 * s),
          SizedBox(width: double.infinity, height: 52 * s, child: FilledButton.icon(onPressed: _logout, icon: Icon(Icons.logout_rounded, size: 19 * s), label: Text('Hesaptan Çıkış Yap', style: TextStyle(fontSize: 11 * s, fontWeight: FontWeight.w800)), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFEAEA), foregroundColor: red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17 * s))))),
        ])),
      ]));
    })));
  }

  Widget _editHero(String avatarUrl, double s) => Container(height: 250 * s, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [deepPurple, purple]), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(42), bottomRight: Radius.circular(42))), child: Stack(children: [
    Positioned(left: 15 * s, top: 16 * s, child: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 25 * s))),
    Positioned(top: 22 * s, left: 0, right: 0, child: Text('Profili Düzenle', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18 * s, fontWeight: FontWeight.w900))),
    Positioned(right: 18 * s, top: 22 * s, child: InkWell(onTap: saving ? null : _save, child: Text(saving ? 'Kaydediliyor...' : 'Kaydet', style: TextStyle(color: Colors.white, fontSize: 11 * s, fontWeight: FontWeight.w600)))),
    Align(alignment: const Alignment(0, .22), child: Column(mainAxisSize: MainAxisSize.min, children: [
      InkWell(onTap: _pickAvatar, customBorder: const CircleBorder(), child: Stack(clipBehavior: Clip.none, children: [CircleAvatar(radius: 52 * s, backgroundColor: Colors.white12, backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes!) : (avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) as ImageProvider : null), child: avatarBytes == null && avatarUrl.isEmpty ? Icon(Icons.person_rounded, color: Colors.white, size: 52 * s) : null), Positioned(right: -2, bottom: 2, child: Container(width: 33 * s, height: 33 * s, decoration: BoxDecoration(color: deepPurple, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF7B56DE), width: 2)), child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 17 * s)))])),
      SizedBox(height: 10 * s), Text(name.text.isEmpty ? 'Kurye' : name.text, style: TextStyle(color: Colors.white, fontSize: 16 * s, fontWeight: FontWeight.w900)), SizedBox(height: 3 * s), Text('Uber Kurye • ${city.text.isEmpty ? 'İstanbul' : city.text}', style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 9.5 * s)),
    ])),
  ]));

  Widget _sectionTitle(String text, double s) => Text(text, style: TextStyle(color: navy, fontSize: 15 * s, fontWeight: FontWeight.w900));
  Widget _group(List<Widget> rows, double s) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s), border: Border.all(color: const Color(0xFFE7E5ED))), child: Column(children: [for (int i = 0; i < rows.length; i++) ...[rows[i], if (i != rows.length - 1) Divider(height: 1, indent: 48 * s, color: const Color(0xFFEDEBF2))]]));
  Widget _field(IconData icon, String label, TextEditingController controller, double s, {TextInputType? keyboard}) => SizedBox(height: 55 * s, child: Row(children: [SizedBox(width: 48 * s, child: Icon(icon, color: const Color(0xFF6F7186), size: 21 * s)), SizedBox(width: 90 * s, child: Text(label, style: TextStyle(color: muted, fontSize: 10 * s))), Expanded(child: TextField(controller: controller, keyboardType: keyboard, style: TextStyle(color: navy, fontSize: 10.5 * s, fontWeight: FontWeight.w600), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))), Padding(padding: EdgeInsets.only(right: 10 * s), child: Icon(Icons.chevron_right_rounded, color: muted, size: 20 * s))]));
  Widget _menuGroup(double s) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s), border: Border.all(color: const Color(0xFFE7E5ED))), child: Column(children: [_menuRow(Icons.shield_outlined, 'Şifreyi Değiştir', null, s), _divider(s), _menuRow(Icons.lock_outline_rounded, 'İki Faktörlü Doğrulama', 'Kapalı', s), _divider(s), _menuRow(Icons.notifications_none_rounded, 'Bildirim Ayarları', null, s), _divider(s), _menuRow(Icons.visibility_outlined, 'Gizlilik Ayarları', null, s)]));
  Widget _menuRow(IconData icon, String title, String? trailingText, double s) => InkWell(onTap: () {}, child: SizedBox(height: 55 * s, child: Row(children: [SizedBox(width: 48 * s, child: Icon(icon, color: const Color(0xFF6F7186), size: 21 * s)), Expanded(child: Text(title, style: TextStyle(color: navy, fontSize: 10.5 * s, fontWeight: FontWeight.w500))), if (trailingText != null) Text(trailingText, style: TextStyle(color: muted, fontSize: 9 * s)), SizedBox(width: 6 * s), Icon(Icons.chevron_right_rounded, color: muted, size: 20 * s), SizedBox(width: 10 * s)])));
  Widget _divider(double s) => Divider(height: 1, indent: 48 * s, color: const Color(0xFFEDEBF2));
}
