import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'create_shipment_page_v2.dart';
import 'customer_phone_auth_page.dart';
import 'customer_support_tickets_page.dart';
import 'data/app_data_service.dart';
import 'data/customer_delivery_extensions.dart';
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
    final contactName = TextEditingController(text: (profile['full_name'] ?? '').toString());
    final contactPhone = TextEditingController(text: (profile['phone'] ?? '').toString());
    final building = TextEditingController();
    final floor = TextEditingController();
    final apartment = TextEditingController();
    final doorNote = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adres Ekle', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: label, decoration: const InputDecoration(labelText: 'Adres adı', hintText: 'Ev, İş...')),
            const SizedBox(height: 10),
            TextField(controller: address, maxLines: 3, decoration: const InputDecoration(labelText: 'Açık adres')),
            const SizedBox(height: 10),
            TextField(controller: contactName, decoration: const InputDecoration(labelText: 'Kişi adı')),
            const SizedBox(height: 10),
            TextField(controller: contactPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: building, decoration: const InputDecoration(labelText: 'Bina / Blok'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: floor, decoration: const InputDecoration(labelText: 'Kat'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: apartment, decoration: const InputDecoration(labelText: 'Daire'))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: doorNote, maxLines: 2, decoration: const InputDecoration(labelText: 'Kapı / kurye notu')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: orange), onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (saved != true || label.text.trim().isEmpty || address.text.trim().isEmpty) return;
    await data.saveDetailedAddress(
      label: label.text.trim(),
      addressLine: address.text.trim(),
      contactName: contactName.text.trim(),
      contactPhone: contactPhone.text.trim(),
      buildingName: building.text.trim(),
      floorNo: floor.text.trim(),
      apartmentNo: apartment.text.trim(),
      doorNote: doorNote.text.trim(),
      isDefault: addresses.isEmpty,
    );
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
      isScrollControlled: true,
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
              ...addresses.take(8).map((a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: softOrange, child: Icon(Icons.location_on_rounded, color: orange)),
                title: Text((a['label'] ?? 'Adres').toString(), style: const TextStyle(color: navy, fontWeight: FontWeight.w800)),
                subtitle: Text((a['address_line'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'default') await data.setDefaultAddress(a['id'].toString());
                    if (value == 'delete') await data.deleteAddress(a['id'].toString());
                    if (mounted) { Navigator.pop(context); await _load(); _openAddresses(); }
                  },
                  itemBuilder: (_) => [
                    if (a['is_default'] != true) const PopupMenuItem(value: 'default', child: Text('Varsayılan yap')),
                    const PopupMenuItem(value: 'delete', child: Text('Sil')),
                  ],
                ),
              )),
          ]),
        ),
      ),
    );
  }

  Future<void> _openPayments() async {
    List<Map<String, dynamic>> cards = [];
    try { cards = await data.getPaymentMethods(); } catch (_) {}
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ödeme Yöntemleri', style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (cards.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Kayıtlı ödeme yöntemi yok.', style: TextStyle(color: muted)))
            else
              ...cards.map((c) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: softOrange, child: Icon(Icons.credit_card_rounded, color: orange)),
                title: Text('${c['brand'] ?? 'Kart'} •••• ${c['last4'] ?? ''}', style: const TextStyle(color: navy, fontWeight: FontWeight.w800)),
                subtitle: Text(c['is_default'] == true ? 'Varsayılan kart' : 'Kayıtlı kart', style: const TextStyle(color: muted)),
                trailing: c['is_default'] == true ? const Icon(Icons.check_circle_rounded, color: orange) : TextButton(onPressed: () async { await data.setDefaultPaymentMethod(c['id'].toString()); if (sheetContext.mounted) Navigator.pop(sheetContext); _openPayments(); }, child: const Text('Varsayılan')),
              )),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { Navigator.pop(sheetContext); _addCard(); }, icon: const Icon(Icons.add_rounded), label: const Text('Kart Ekle'))),
          ]),
        ),
      ),
    );
  }

  Future<void> _addCard() async {
    final brand = TextEditingController();
    final last4 = TextEditingController();
    final saved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Kart Ekle', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: brand, decoration: const InputDecoration(labelText: 'Kart adı', hintText: 'Visa, Mastercard...')),
        const SizedBox(height: 10),
        TextField(controller: last4, maxLength: 4, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Son 4 hane')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')), FilledButton(style: FilledButton.styleFrom(backgroundColor: orange), onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet'))],
    ));
    if (saved != true || last4.text.trim().length != 4) return;
    await data.addCard(brand: brand.text.trim().isEmpty ? 'Kart' : brand.text.trim(), last4: last4.text.trim(), isDefault: (await data.getPaymentMethods()).isEmpty);
    if (mounted) _openPayments();
  }

  void _openFavorites() {
    showModalBottomSheet(context: context, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))), builder: (context) => SafeArea(child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Favoriler', style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Kayıtlı adreslerin hızlı seçim için burada gösterilir.', style: TextStyle(color: muted)),
        const SizedBox(height: 12),
        if (addresses.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Henüz favori konum yok.', style: TextStyle(color: muted))) else ...addresses.take(6).map((a) => ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(backgroundColor: softOrange, child: Icon(Icons.favorite_rounded, color: orange)), title: Text((a['label'] ?? 'Adres').toString(), style: const TextStyle(color: navy, fontWeight: FontWeight.w800)), subtitle: Text((a['address_line'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis))),
      ]),
    )));
  }

  Future<void> _openNotificationSettings() async {
    bool enabled = profile['notifications_enabled'] != false;
    await showModalBottomSheet(context: context, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))), builder: (context) => StatefulBuilder(builder: (context, setLocal) => SafeArea(child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Bildirim Ayarları', style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        SwitchListTile(contentPadding: EdgeInsets.zero, activeThumbColor: orange, title: const Text('Anlık bildirimler', style: TextStyle(color: navy, fontWeight: FontWeight.w800)), subtitle: const Text('Gönderi ve kurye durum güncellemeleri'), value: enabled, onChanged: (value) async { setLocal(() => enabled = value); await data.updateProfile(notificationsEnabled: value); if (mounted) setState(() => profile['notifications_enabled'] = value); }),
      ]),
    ))));
  }

  Future<void> _openSecurity() async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final changed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Güvenlik', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Align(alignment: Alignment.centerLeft, child: Text('Şifreni değiştir', style: TextStyle(color: muted))),
        const SizedBox(height: 10),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni şifre')),
        const SizedBox(height: 10),
        TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni şifre tekrar')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')), FilledButton(style: FilledButton.styleFrom(backgroundColor: orange), onPressed: () => Navigator.pop(context, true), child: const Text('Değiştir'))],
    ));
    if (changed != true) return;
    if (password.text.length < 6 || password.text != confirm.text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifreler eşleşmeli ve en az 6 karakter olmalı.'))); return; }
    try {
      await data.client.auth.updateUser(UserAttributes(password: password.text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifren güncellendi.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Şifre güncellenemedi: $e'))); }
  }

  void _openSupportTickets() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerSupportTicketsPage()));

  void _openHelp() => _infoSheet('Yardım & Destek', const [
    ('Gönderim nasıl oluşturulur?', 'Ana sayfadaki Gönderi Oluştur alanından alım ve teslimat adresini seçerek ilerleyebilirsin.'),
    ('Kuryemi nasıl takip ederim?', 'Kurye işi aldıktan sonra Gönderilerim veya Takip alanından canlı konumu izleyebilirsin.'),
    ('Bir sorun yaşarsam?', 'Gönderi kodunu not ederek destek talebinde kullanabilirsin.'),
  ]);

  void _openAbout() => _infoSheet('Hakkında', const [
    ('Open', 'Hızlı ve kolay şehir içi gönderi deneyimi.'),
    ('Sürüm', '1.0.0'),
    ('Gizlilik', 'Konum ve hesap verileri yalnızca uygulama işlevleri için kullanılır.'),
  ]);

  void _openSettings() => _infoSheet('Ayarlar', const [
    ('Profil', 'Kişisel bilgilerini profil kartından düzenleyebilirsin.'),
    ('Bildirimler', 'Bildirim tercihlerini Bildirim Ayarları bölümünden yönetebilirsin.'),
    ('Güvenlik', 'Şifreni Güvenlik bölümünden değiştirebilirsin.'),
  ]);

  void _openPlus() => _infoSheet("Open Plus", const [
    ('Öncelikli deneyim', 'Plus üyelik avantajları burada yönetilecek.'),
    ('Üyelik durumu', 'Şu anda Standart Üye hesabını kullanıyorsun.'),
  ]);

  void _infoSheet(String title, List<(String, String)> rows) {
    showModalBottomSheet(context: context, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))), builder: (context) => SafeArea(child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        ...rows.map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.$1, style: const TextStyle(color: navy, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(r.$2, style: const TextStyle(color: muted, height: 1.35))]))),
      ]),
    )));
  }

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
            final v = constraints.maxHeight < 760 ? .88 : 1.0;
            return Column(children: [
              Expanded(child: RefreshIndicator(color: orange, onRefresh: _load, child: ListView(physics: const BouncingScrollPhysics(), padding: EdgeInsets.fromLTRB(18 * s, 12 * s, 18 * s, 22 * s), children: [
                _titleRow(s), SizedBox(height: 8 * s), _profileHero(name, phone, avatarUrl, s), SizedBox(height: 12 * s), _stats(shipments.length, delivered, active, cancelled, s), SizedBox(height: 12 * s), _plusBanner(s), SizedBox(height: 12 * s),
                _menuGroup([
                  _MenuData(Icons.person_rounded, 'Kişisel Bilgiler', 'Ad, telefon, e-posta, adres', _editProfile),
                  _MenuData(Icons.account_balance_wallet_outlined, 'Ödeme Yöntemleri', 'Kartlarım, bakiye, faturalar', _openPayments),
                  _MenuData(Icons.location_on_rounded, 'Kayıtlı Adresler', 'Teslimat adreslerin', _openAddresses),
                  _MenuData(Icons.favorite_rounded, 'Favoriler', 'Kayıtlı konumların', _openFavorites),
                ], s),
                SizedBox(height: 10 * s),
                _menuGroup([
                  _MenuData(Icons.notifications_rounded, 'Bildirim Ayarları', 'Anlık bildirimleri yönet', _openNotificationSettings),
                  _MenuData(Icons.shield_rounded, 'Güvenlik', 'Şifre ve hesap güvenliği', _openSecurity),
                  _MenuData(Icons.help_rounded, 'Yardım & Destek', 'SSS ve destek', _openHelp),
                  _MenuData(Icons.support_agent_rounded, 'Destek Taleplerim', 'Açık, inceleniyor ve çözülen kayıtlar', _openSupportTickets),
                  _MenuData(Icons.info_rounded, 'Hakkında', 'Uygulama sürümü, gizlilik', _openAbout),
                ], s),
                SizedBox(height: 10 * s), _logoutButton(s),
              ]))),
              _bottomNav(context, s, v),
            ]);
          },
        ),
      ),
    );
  }

  Widget _titleRow(double s) => Row(children: [Expanded(child: Text('Profil', style: TextStyle(color: navy, fontSize: 27 * s, fontWeight: FontWeight.w900, letterSpacing: -1))), Container(width: 38 * s, height: 38 * s, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13 * s), boxShadow: const [BoxShadow(color: Color(0x09000000), blurRadius: 10)]), child: IconButton(padding: EdgeInsets.zero, onPressed: _openSettings, icon: Icon(Icons.settings_outlined, color: navy, size: 21 * s)))]);

  Widget _profileHero(String name, String phone, String avatarUrl, double s) => InkWell(onTap: _editProfile, borderRadius: BorderRadius.circular(16 * s), child: Padding(padding: EdgeInsets.symmetric(vertical: 2 * s), child: Row(children: [
    Stack(clipBehavior: Clip.none, children: [Container(width: 78 * s, height: 78 * s, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE9E8F2), image: avatarUrl.isNotEmpty ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null), child: avatarUrl.isEmpty ? Icon(Icons.person_rounded, color: muted, size: 42 * s) : null), Positioned(right: -2 * s, bottom: 1 * s, child: Container(width: 28 * s, height: 28 * s, decoration: const BoxDecoration(color: orange, shape: BoxShape.circle), child: Icon(Icons.edit_rounded, color: Colors.white, size: 15 * s))) ]),
    SizedBox(width: 17 * s), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name.isEmpty ? 'Profilini tamamla' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: navy, fontSize: 19 * s, fontWeight: FontWeight.w900)), SizedBox(height: 2 * s), Text(phone.isEmpty ? 'Telefon bilgisi ekle' : phone, style: TextStyle(color: muted, fontSize: 12.5 * s, fontWeight: FontWeight.w500)), SizedBox(height: 8 * s), Container(padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 5 * s), decoration: BoxDecoration(color: softOrange, borderRadius: BorderRadius.circular(12 * s)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.workspace_premium_rounded, color: orange, size: 15 * s), SizedBox(width: 5 * s), Text('Standart Üye', style: TextStyle(color: orange, fontSize: 10 * s, fontWeight: FontWeight.w800))]))])), Icon(Icons.chevron_right_rounded, color: navy, size: 24 * s),
  ])));

  Widget _stats(int total, int delivered, int active, int cancelled, double s) { final values = [(Icons.inventory_2_outlined, '$total', 'Toplam Gönderi'), (Icons.check_circle_outline_rounded, '$delivered', 'Tamamlandı'), (Icons.access_time_rounded, '$active', 'Devam Ediyor'), (Icons.cancel_outlined, '$cancelled', 'İptal Edildi')]; return Row(children: [for (int i = 0; i < values.length; i++) ...[if (i > 0) SizedBox(width: 7 * s), Expanded(child: Container(height: 72 * s, padding: EdgeInsets.symmetric(vertical: 8 * s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15 * s), boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 10)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(values[i].$1, color: i == 0 ? orange : navy, size: 21 * s), SizedBox(height: 3 * s), Text(values[i].$2, style: TextStyle(color: navy, fontSize: 14 * s, fontWeight: FontWeight.w900)), Text(values[i].$3, textAlign: TextAlign.center, maxLines: 1, style: TextStyle(color: muted, fontSize: 7.7 * s))])))] ]); }

  Widget _plusBanner(double s) => InkWell(onTap: _openPlus, borderRadius: BorderRadius.circular(17 * s), child: Container(height: 88 * s, decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(17 * s)), child: ClipRRect(borderRadius: BorderRadius.circular(17 * s), child: Stack(children: [
    Positioned(right: -32 * s, top: -72 * s, width: 190 * s, height: 190 * s, child: Container(decoration: const BoxDecoration(color: orange, shape: BoxShape.circle))), Positioned(right: 6 * s, bottom: -24 * s, width: 120 * s, height: 105 * s, child: Image.asset('assets/images/3d_kurye.png', fit: BoxFit.contain, alignment: Alignment.bottomRight)), Positioned(left: 13 * s, top: 20 * s, child: Container(width: 45 * s, height: 45 * s, decoration: BoxDecoration(color: orange.withValues(alpha: .18), shape: BoxShape.circle), child: Icon(Icons.workspace_premium_rounded, color: const Color(0xFFFFC85E), size: 27 * s))), Positioned(left: 70 * s, top: 18 * s, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hızlı ve avantajlı gönderim için', style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 9 * s)), SizedBox(height: 4 * s), Row(children: [Text("Plus'a Geç", style: TextStyle(color: Colors.white, fontSize: 17 * s, fontWeight: FontWeight.w900)), SizedBox(width: 5 * s), Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20 * s)]), SizedBox(height: 4 * s), Text('Öncelikli kurye, özel fiyatlar ve daha fazlası.', style: TextStyle(color: const Color(0xFFD8D1F1), fontSize: 8.2 * s))]))
  ]))));

  Widget _menuGroup(List<_MenuData> items, double s) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16 * s)), child: Column(children: [for (int i = 0; i < items.length; i++) ...[_menuRow(items[i], s), if (i < items.length - 1) Divider(height: 1, indent: 52 * s, color: const Color(0xFFF0EFF4))]]));
  Widget _menuRow(_MenuData item, double s) => InkWell(onTap: item.onTap, child: SizedBox(height: 54 * s, child: Row(children: [SizedBox(width: 12 * s), Container(width: 34 * s, height: 34 * s, decoration: BoxDecoration(color: softOrange, borderRadius: BorderRadius.circular(10 * s)), child: Icon(item.icon, color: orange, size: 19 * s)), SizedBox(width: 11 * s), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: TextStyle(color: navy, fontSize: 11.2 * s, fontWeight: FontWeight.w800)), SizedBox(height: 2 * s), Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 8.8 * s))])), Icon(Icons.chevron_right_rounded, color: navy, size: 21 * s), SizedBox(width: 10 * s)])));
  Widget _logoutButton(double s) => InkWell(onTap: _logout, borderRadius: BorderRadius.circular(15 * s), child: Container(height: 52 * s, decoration: BoxDecoration(color: const Color(0xFFFFEDEA), borderRadius: BorderRadius.circular(15 * s)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout_rounded, color: orange, size: 21 * s), SizedBox(width: 8 * s), Text('Çıkış Yap', style: TextStyle(color: orange, fontSize: 12 * s, fontWeight: FontWeight.w900))])));

  Widget _bottomNav(BuildContext context, double s, double v) => Container(height: 68 * v, padding: EdgeInsets.fromLTRB(14 * s, 7 * v, 14 * s, 10 * v), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24 * s), topRight: Radius.circular(24 * s)), boxShadow: const [BoxShadow(color: Color(0x110D082F), blurRadius: 18, offset: Offset(0, -4))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
    _navItem(Icons.home_rounded, 'Ana Sayfa', false, () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomePixelPreview()), (_) => false), s, v),
    _navItem(Icons.inventory_2_outlined, 'Gönderi', false, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyShipmentsPage())), s, v),
    _navItem(Icons.location_on_outlined, 'Takip', false, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyShipmentsPage())), s, v),
    _navItem(Icons.person_outline_rounded, 'Profil', true, () {}, s, v),
  ]));

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap, double s, double v) { final color = active ? orange : const Color(0xFF7C8192); return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14 * s), child: Padding(padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 3 * v), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 21 * s), SizedBox(height: 3 * v), Text(label, style: TextStyle(color: color, fontSize: 9.5 * s, fontWeight: active ? FontWeight.w800 : FontWeight.w500))]))); }
}

class _MenuData {
  const _MenuData(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}
