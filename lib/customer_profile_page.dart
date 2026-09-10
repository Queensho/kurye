import 'package:flutter/material.dart';

import 'create_shipment_page_v2.dart';
import 'customer_phone_auth_page.dart';
import 'data/app_data_service.dart';
import 'home_pixel_preview.dart';
import 'my_shipments_page.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF171052);
  static const purple = Color(0xFF261168);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);
  static const softOrange = Color(0xFFFFEEE8);

  final data = AppDataService.instance;
  bool loading = true;
  Map<String, dynamic> profile = {};
  List<Map<String, dynamic>> addresses = [];
  List<Map<String, dynamic>> shipments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([data.getProfile(), data.getAddresses(), data.getShipments()]);
      if (!mounted) return;
      setState(() {
        profile = Map<String, dynamic>.from(values[0] as Map);
        addresses = List<Map<String, dynamic>>.from(values[1] as List);
        shipments = List<Map<String, dynamic>>.from(values[2] as List);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil yüklenemedi: $e')));
    }
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(text: (profile['full_name'] ?? '').toString());
    final phone = TextEditingController(text: (profile['phone'] ?? '').toString());
    final email = TextEditingController(text: (profile['email'] ?? '').toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kişisel Bilgiler', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad Soyad')),
          const SizedBox(height: 10),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon')),
          const SizedBox(height: 10),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: orange), onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (saved != true) return;
    await data.updateProfile(fullName: name.text.trim(), phone: phone.text.trim(), email: email.text.trim());
    await _load();
  }

  Future<void> _addAddress() async {
    final label = TextEditingController();
    final address = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adres Ekle', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: label, decoration: const InputDecoration(labelText: 'Adres adı', hintText: 'Ev, İş...')),
          const SizedBox(height: 10),
          TextField(controller: address, maxLines: 3, decoration: const InputDecoration(labelText: 'Açık adres')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: orange), onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (saved != true || label.text.trim().isEmpty || address.text.trim().isEmpty) return;
    await data.addAddress(label: label.text.trim(), addressLine: address.text.trim(), isDefault: addresses.isEmpty);
    await _load();
  }

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
        content: const Text('Hesabından çıkış yapmak istiyor musun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: orange), onPressed: () => Navigator.pop(context, true), child: const Text('Çıkış Yap')),
        ],
      ),
    );
    if (yes != true) return;
    await data.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const CustomerPhoneAuthPage()), (_) => false);
  }

  void _openAddresses() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Expanded(child: Text('Kayıtlı Adresler', style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900))),
              TextButton.icon(onPressed: () { Navigator.pop(context); _addAddress(); }, icon: const Icon(Icons.add_rounded), label: const Text('Ekle')),
            ]),
            if (addresses.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Kayıtlı adres yok', style: TextStyle(color: muted)))
            else
              ...addresses.take(5).map((a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: softOrange, child: Icon(Icons.location_on_rounded, color: orange)),
                title: Text((a['label'] ?? 'Adres').toString(), style: const TextStyle(color: navy, fontWeight: FontWeight.w800)),
                subtitle: Text((a['address_line'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
              )),
          ]),
        ),
      ),
    );
  }

  void _comingSoon(String title) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title yakında aktif olacak.')));

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: bg, body: Center(child: CircularProgressIndicator(color: orange)));

    final name = (profile['full_name'] ?? '').toString().trim();
    final phone = (profile['phone'] ?? '').toString().trim();
    final avatarUrl = (profile['avatar_url'] ?? '').toString().trim();
    final delivered = shipments.where((e) => e['status'] == 'delivered').length;
    final cancelled = shipments.where((e) => e['status'] == 'cancelled').length;
    final active = shipments.where((e) => e['status'] != 'delivered' && e['status'] != 'cancelled').length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = (constraints.maxWidth / 390).clamp(.92, 1.06).toDouble();
            return Column(children: [
              Expanded(
                child: RefreshIndicator(
                  color: orange,
                  onRefresh: _load,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(18 * s, 12 * s, 18 * s, 22 * s),
                    children: [
                      _titleRow(s),
                      SizedBox(height: 8 * s),
                      _profileHero(name, phone, avatarUrl, s),
                      SizedBox(height: 12 * s),
                      _stats(shipments.length, delivered, active, cancelled, s),
                      SizedBox(height: 12 * s),
                      _plusBanner(s),
                      SizedBox(height: 12 * s),
                      _menuGroup([
                        _MenuData(Icons.person_rounded, 'Kişisel Bilgiler', 'Ad, telefon, e-posta, adres', _editProfile),
                        _MenuData(Icons.account_balance_wallet_outlined, 'Ödeme Yöntemleri', 'Kartlarım, bakiye, faturalar', () => _comingSoon('Ödeme yöntemleri')),
                        _MenuData(Icons.location_on_rounded, 'Kayıtlı Adresler', 'Teslimat adreslerin', _openAddresses),
                        _MenuData(Icons.favorite_rounded, 'Favoriler', 'Kayıtlı konumların', () => _comingSoon('Favoriler')),
                      ], s),
                      SizedBox(height: 10 * s),
                      _menuGroup([
                        _MenuData(Icons.notifications_rounded, 'Bildirim Ayarları', 'Anlık bildirimleri yönet', () => _comingSoon('Bildirim ayarları')),
                        _MenuData(Icons.shield_rounded, 'Güvenlik', 'Şifre, oturumlar, iki adımlı doğrulama', () => _comingSoon('Güvenlik')),
                        _MenuData(Icons.help_rounded, 'Yardım & Destek', 'SSS, canlı destek', () => _comingSoon('Yardım & Destek')),
                        _MenuData(Icons.info_rounded, 'Hakkında', 'Uygulama sürümü, gizlilik politikası', () => _comingSoon('Hakkında')),
                      ], s),
                      SizedBox(height: 10 * s),
                      _logoutButton(s),
                    ],
                  ),
                ),
              ),
              _bottomNav(context, s),
            ]);
          },
        ),
      ),
    );
  }

  Widget _titleRow(double s) => Row(children: [
    Expanded(child: Text('Profil', style: TextStyle(color: navy, fontSize: 27 * s, fontWeight: FontWeight.w900, letterSpacing: -1))),
    Container(width: 38 * s, height: 38 * s, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13 * s), boxShadow: const [BoxShadow(color: Color(0x09000000), blurRadius: 10)]), child: IconButton(padding: EdgeInsets.zero, onPressed: () => _comingSoon('Ayarlar'), icon: Icon(Icons.settings_outlined, color: navy, size: 21 * s))),
  ]);

  Widget _profileHero(String name, String phone, String avatarUrl, double s) => InkWell(
    onTap: _editProfile,
    borderRadius: BorderRadius.circular(16 * s),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 2 * s),
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 78 * s,
            height: 78 * s,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE9E8F2), image: avatarUrl.isNotEmpty ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null),
            child: avatarUrl.isEmpty ? Icon(Icons.person_rounded, color: muted, size: 42 * s) : null,
          ),
          Positioned(right: -2 * s, bottom: 1 * s, child: Container(width: 28 * s, height: 28 * s, decoration: const BoxDecoration(color: orange, shape: BoxShape.circle), child: Icon(Icons.edit_rounded, color: Colors.white, size: 15 * s))),
        ]),
        SizedBox(width: 17 * s),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.isEmpty ? 'Profilini tamamla' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: navy, fontSize: 19 * s, fontWeight: FontWeight.w900)),
          SizedBox(height: 2 * s),
          Text(phone.isEmpty ? 'Telefon bilgisi ekle' : phone, style: TextStyle(color: muted, fontSize: 12.5 * s, fontWeight: FontWeight.w500)),
          SizedBox(height: 8 * s),
          Container(padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 5 * s), decoration: BoxDecoration(color: softOrange, borderRadius: BorderRadius.circular(12 * s)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.workspace_premium_rounded, color: orange, size: 15 * s), SizedBox(width: 5 * s), Text('Standart Üye', style: TextStyle(color: orange, fontSize: 10 * s, fontWeight: FontWeight.w800))])),
        ])),
        Icon(Icons.chevron_right_rounded, color: navy, size: 24 * s),
      ]),
    ),
  );

  Widget _stats(int total, int delivered, int active, int cancelled, double s) {
    final values = [
      (Icons.inventory_2_outlined, '$total', 'Toplam Gönderi'),
      (Icons.check_circle_outline_rounded, '$delivered', 'Tamamlandı'),
      (Icons.access_time_rounded, '$active', 'Devam Ediyor'),
      (Icons.cancel_outlined, '$cancelled', 'İptal Edildi'),
    ];
    return Row(children: [for (int i = 0; i < values.length; i++) ...[
      if (i > 0) SizedBox(width: 7 * s),
      Expanded(child: Container(height: 72 * s, padding: EdgeInsets.symmetric(vertical: 8 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15 * s), boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 10)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(values[i].$1, color: i == 0 ? orange : navy, size: 21 * s), SizedBox(height: 3 * s), Text(values[i].$2, style: TextStyle(color: navy, fontSize: 14 * s, fontWeight: FontWeight.w900)), Text(values[i].$3, textAlign: TextAlign.center, maxLines: 1, style: TextStyle(color: muted, fontSize: 7.7 * s, fontWeight: FontWeight.w500))]))),
    ]]);
  }

  Widget _plusBanner(double s) => InkWell(
    onTap: () => _comingSoon('Plus üyelik'),
    borderRadius: BorderRadius.circular(17 * s),
    child: Container(
      height: 88 * s,
      decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(17 * s)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17 * s),
        child: Stack(children: [
          Positioned(right: -32 * s, top: -72 * s, width: 190 * s, height: 190 * s, child: Container(decoration: const BoxDecoration(color: orange, shape: BoxShape.circle))),
          Positioned(right: 6 * s, bottom: -24 * s, width: 120 * s, height: 105 * s, child: Image.asset('assets/images/3d_kurye.png', fit: BoxFit.contain, alignment: Alignment.bottomRight)),
          Positioned(left: 13 * s, top: 20 * s, child: Container(width: 45 * s, height: 45 * s, decoration: BoxDecoration(color: orange.withValues(alpha: .18), shape: BoxShape.circle), child: Icon(Icons.workspace_premium_rounded, color: const Color(0xFFFFC85E), size: 27 * s))),
          Positioned(left: 70 * s, top: 18 * s, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hızlı ve avantajlı gönderim için', style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 9 * s)),
            SizedBox(height: 4 * s),
            Row(children: [Text("Plus'a Geç", style: TextStyle(color: Colors.white, fontSize: 17 * s, fontWeight: FontWeight.w900)), SizedBox(width: 5 * s), Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20 * s)]),
            SizedBox(height: 4 * s),
            Text('Öncelikli kurye, özel fiyatlar ve daha fazlası.', style: TextStyle(color: const Color(0xFFD8D1F1), fontSize: 8.2 * s)),
          ])),
        ]),
      ),
    ),
  );

  Widget _menuGroup(List<_MenuData> items, double s) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16 * s)),
    child: Column(children: [for (int i = 0; i < items.length; i++) ...[
      _menuRow(items[i], s),
      if (i < items.length - 1) Divider(height: 1, thickness: 1, indent: 52 * s, color: const Color(0xFFF0EFF4)),
    ]]),
  );

  Widget _menuRow(_MenuData item, double s) => InkWell(
    onTap: item.onTap,
    child: SizedBox(
      height: 54 * s,
      child: Row(children: [
        SizedBox(width: 12 * s),
        Container(width: 34 * s, height: 34 * s, decoration: BoxDecoration(color: softOrange, borderRadius: BorderRadius.circular(10 * s)), child: Icon(item.icon, color: orange, size: 19 * s)),
        SizedBox(width: 11 * s),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: TextStyle(color: navy, fontSize: 11.2 * s, fontWeight: FontWeight.w800)), SizedBox(height: 2 * s), Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 8.8 * s))])),
        Icon(Icons.chevron_right_rounded, color: navy, size: 21 * s),
        SizedBox(width: 10 * s),
      ]),
    ),
  );

  Widget _logoutButton(double s) => InkWell(
    onTap: _logout,
    borderRadius: BorderRadius.circular(15 * s),
    child: Container(height: 52 * s, decoration: BoxDecoration(color: const Color(0xFFFFEDEA), borderRadius: BorderRadius.circular(15 * s)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout_rounded, color: orange, size: 21 * s), SizedBox(width: 8 * s), Text('Çıkış Yap', style: TextStyle(color: orange, fontSize: 12 * s, fontWeight: FontWeight.w900))])),
  );

  Widget _bottomNav(BuildContext context, double s) => Container(
    height: 72 * s,
    padding: EdgeInsets.fromLTRB(10 * s, 6 * s, 10 * s, 9 * s),
    decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, -3))]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _nav(Icons.home_outlined, 'Ana Sayfa', false, () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomePixelPreview()), (_) => false), s),
      _nav(Icons.add_circle_outline_rounded, 'Gönderi Oluştur', false, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateShipmentPage())), s),
      _nav(Icons.layers_outlined, 'Gönderilerim', false, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyShipmentsPage())), s),
      _nav(Icons.notifications_none_rounded, 'Bildirimler', false, () => _comingSoon('Bildirimler'), s),
      _nav(Icons.person_rounded, 'Profil', true, () {}, s),
    ]),
  );

  Widget _nav(IconData icon, String label, bool active, VoidCallback onTap, double s) {
    final color = active ? orange : const Color(0xFF667085);
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(11 * s), child: SizedBox(width: 66 * s, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 20 * s), SizedBox(height: 3 * s), Text(label, maxLines: 1, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 7.7 * s, fontWeight: active ? FontWeight.w800 : FontWeight.w500)), if (active) ...[SizedBox(height: 4 * s), Container(width: 29 * s, height: 2.5 * s, decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(4 * s)))]])));
  }
}

class _MenuData {
  const _MenuData(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}
