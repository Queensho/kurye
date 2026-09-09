import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const blue = Color(0xFF178EF4);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF7A8390);

  final data = AppDataService.instance;
  bool loading = true;
  bool notifications = true;
  String language = 'Türkçe';
  String name = 'Profilini tamamla';
  String phone = '';
  String email = '';
  List<Map<String, dynamic>> addresses = [];
  List<Map<String, dynamic>> cards = [];
  List<Map<String, dynamic>> shipments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await data.getProfile();
      final savedAddresses = await data.getAddresses();
      final savedCards = await data.getPaymentMethods();
      final savedShipments = await data.getShipments();
      if (!mounted) return;
      setState(() {
        final fullName = (profile['full_name'] ?? '').toString().trim();
        name = fullName.isEmpty ? 'Profilini tamamla' : fullName;
        phone = (profile['phone'] ?? '').toString();
        email = (profile['email'] ?? '').toString();
        notifications = profile['notifications_enabled'] != false;
        language = profile['language'] == 'en' ? 'English' : 'Türkçe';
        addresses = savedAddresses;
        cards = savedCards;
        shipments = savedShipments;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil verileri alınamadı: $e')));
    }
  }

  int get completedCount => shipments.where((s) => s['status'] == 'delivered').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Profilim', style: TextStyle(fontWeight: FontWeight.w900, color: navy)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: blue))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFEAF6FF), Color(0xFFF8FCFF)]),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB9DAFF), width: 2)),
                        child: const Icon(Icons.person_rounded, color: blue, size: 43),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: navy)),
                          const SizedBox(height: 4),
                          Text(phone.isEmpty ? 'Telefon eklenmedi' : phone, style: const TextStyle(fontSize: 13, color: muted)),
                          const SizedBox(height: 2),
                          Text(email.isEmpty ? 'E-posta eklenmedi' : email, style: const TextStyle(fontSize: 12, color: muted)),
                        ]),
                      ),
                      IconButton(onPressed: _editProfile, icon: const Icon(Icons.edit_rounded, color: blue)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _stat('${shipments.length}', 'Gönderi', Icons.inventory_2_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _stat('$completedCount', 'Tamamlandı', Icons.check_circle_outline_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _stat('—', 'Puan', Icons.star_outline_rounded)),
                  ]),
                  const SizedBox(height: 18),
                  _section('Hesap', [
                    _item(Icons.person_outline_rounded, 'Kişisel Bilgiler', 'Ad, telefon ve e-posta', _editProfile),
                    _item(Icons.location_on_outlined, 'Kayıtlı Adresler', '${addresses.length} kayıtlı adres', _openAddresses),
                    _item(Icons.credit_card_rounded, 'Ödeme Yöntemleri', '${cards.length} kayıtlı kart • Nakit kullanılabilir', _openPayments),
                  ]),
                  const SizedBox(height: 14),
                  _section('Tercihler', [
                    _switchItem(),
                    _item(Icons.language_rounded, 'Dil', language, _chooseLanguage),
                  ]),
                  const SizedBox(height: 14),
                  _section('Destek', [
                    _item(Icons.help_outline_rounded, 'Yardım Merkezi', 'Sık sorulan sorular ve destek', () => _infoPage('Yardım Merkezi', 'Gönderi, ödeme, kurye ve hesap konularında destek içerikleri burada yer alacak.')),
                    _item(Icons.shield_outlined, 'Gizlilik ve Güvenlik', 'Hesap ve veri ayarları', () => _infoPage('Gizlilik ve Güvenlik', 'Verilerin kullanıcı hesabına bağlı tutulur. Kartın tam numarası veya CVV bilgisi veritabanına kaydedilmez.')),
                    _item(Icons.description_outlined, 'Kullanım Koşulları', 'Yasal bilgiler', () => _infoPage('Kullanım Koşulları', 'Kurye hizmeti kullanım koşulları ve yasal metinler bu bölümde yayınlanacak.')),
                  ]),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _logoutInfo,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Çıkış Yap'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD94A4A),
                      side: const BorderSide(color: Color(0xFFFFD6D6)),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(child: Text('Kurye • v1.0.0', style: TextStyle(fontSize: 11, color: muted))),
                ],
              ),
            ),
    );
  }

  Widget _stat(String value, String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Icon(icon, color: blue, size: 22),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
          Text(label, style: const TextStyle(fontSize: 10.5, color: muted)),
        ]),
      );

  Widget _section(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: navy))),
          Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Column(children: children)),
        ],
      );

  Widget _item(IconData icon, String title, String subtitle, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: blue, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: navy)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 10.5, color: muted)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B96A8)),
          ]),
        ),
      );

  Widget _switchItem() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.notifications_none_rounded, color: blue, size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bildirimler', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: navy)),
            SizedBox(height: 2),
            Text('Gönderi ve mesaj bildirimleri', style: TextStyle(fontSize: 10.5, color: muted)),
          ])),
          Switch(
            value: notifications,
            onChanged: (v) async {
              setState(() => notifications = v);
              try {
                await data.updateProfile(notificationsEnabled: v);
              } catch (_) {
                if (mounted) setState(() => notifications = !v);
              }
            },
          ),
        ]),
      );

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: name == 'Profilini tamamla' ? '' : name);
    final phoneController = TextEditingController(text: phone);
    final emailController = TextEditingController(text: email);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Profili Düzenle', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: navy)),
          const SizedBox(height: 16),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ad Soyad', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
            await data.updateProfile(fullName: nameController.text.trim(), phone: phoneController.text.trim(), email: emailController.text.trim());
            if (!sheetContext.mounted) return;
            Navigator.pop(sheetContext);
          }, child: const Text('Kaydet'))),
        ]),
      ),
    );
    await _load();
  }

  Future<void> _openAddresses() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) {
        Future<void> refresh() async {
          addresses = await data.getAddresses();
          if (mounted) setState(() {});
          setSheetState(() {});
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Kayıtlı Adreslerim', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: navy)),
              const SizedBox(height: 12),
              if (addresses.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Henüz kayıtlı adres yok.'))),
              ...addresses.map((entry) => Card(
                    elevation: 0,
                    color: const Color(0xFFF7FBFF),
                    child: ListTile(
                      onTap: () async { await data.setDefaultAddress(entry['id'].toString()); await refresh(); },
                      leading: CircleAvatar(backgroundColor: const Color(0xFFEAF4FF), child: Icon(entry['is_default'] == true ? Icons.home_rounded : Icons.location_on_rounded, color: blue)),
                      title: Row(children: [Expanded(child: Text((entry['label'] ?? 'Adres').toString(), style: const TextStyle(fontWeight: FontWeight.w800))), if (entry['is_default'] == true) const Text('Varsayılan', style: TextStyle(fontSize: 10, color: blue, fontWeight: FontWeight.w800))]),
                      subtitle: Text((entry['address_line'] ?? '').toString()),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () async { await data.deleteAddress(entry['id'].toString()); await refresh(); }),
                    ),
                  )),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _addAddress(sheetContext, refresh), icon: const Icon(Icons.add_location_alt_rounded), label: const Text('Yeni Adres Ekle'))),
            ]),
          ),
        );
      }),
    );
    await _load();
  }

  Future<void> _addAddress(BuildContext sheetContext, Future<void> Function() refresh) async {
    final title = TextEditingController();
    final address = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adres Ekle'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Başlık (Ev, İş...)')),
          const SizedBox(height: 8),
          TextField(controller: address, maxLines: 3, decoration: const InputDecoration(labelText: 'Adres')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
          FilledButton(onPressed: () async {
            if (title.text.trim().isEmpty || address.text.trim().isEmpty) return;
            await data.addAddress(label: title.text.trim(), addressLine: address.text.trim(), isDefault: addresses.isEmpty);
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);
          }, child: const Text('Ekle')),
        ],
      ),
    );
    if (sheetContext.mounted) await refresh();
  }

  Future<void> _openPayments() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) {
        Future<void> refresh() async {
          cards = await data.getPaymentMethods();
          if (mounted) setState(() {});
          setSheetState(() {});
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ödeme Yöntemlerim', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: navy)),
              const SizedBox(height: 12),
              const ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: Color(0xFFEAF8F0), child: Icon(Icons.payments_rounded, color: Color(0xFF18A768))), title: Text('Nakit', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Teslimatta nakit ödeme')),
              ...cards.map((entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () async { await data.setDefaultPaymentMethod(entry['id'].toString()); await refresh(); },
                    leading: const CircleAvatar(backgroundColor: Color(0xFFEAF4FF), child: Icon(Icons.credit_card_rounded, color: blue)),
                    title: Text('${entry['brand'] ?? 'Kart'} •••• ${entry['last4'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(entry['is_default'] == true ? 'Varsayılan online ödeme kartı' : 'Online ödeme için kayıtlı kart'),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () async { await data.deletePaymentMethod(entry['id'].toString()); await refresh(); }),
                  )),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _addCard(refresh), icon: const Icon(Icons.add_card_rounded), label: const Text('Kart Ekle'))),
              const SizedBox(height: 8),
              const Text('Güvenlik: Tam kart numarası ve CVV kaydedilmez. Şimdilik yalnızca kart markası ve son 4 hane saklanır.', style: TextStyle(fontSize: 10, color: muted)),
            ]),
          ),
        );
      }),
    );
    await _load();
  }

  Future<void> _addCard(Future<void> Function() refresh) async {
    final cardNumber = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kart Ekle'),
        content: TextField(controller: cardNumber, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kart numarası', hintText: '1234 5678 9012 3456')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
          FilledButton(onPressed: () async {
            final digits = cardNumber.text.replaceAll(RegExp(r'\D'), '');
            if (digits.length < 12) return;
            final brand = digits.startsWith('4') ? 'Visa' : digits.startsWith('5') ? 'Mastercard' : 'Kart';
            await data.addCard(brand: brand, last4: digits.substring(digits.length - 4), isDefault: cards.isEmpty);
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);
          }, child: const Text('Kaydet')),
        ],
      ),
    );
    await refresh();
  }

  Future<void> _chooseLanguage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text('Dil Seçimi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
        for (final item in const ['Türkçe', 'English']) ListTile(title: Text(item), trailing: language == item ? const Icon(Icons.check_rounded, color: blue) : null, onTap: () => Navigator.pop(context, item)),
        const SizedBox(height: 12),
      ])),
    );
    if (result == null) return;
    await data.updateProfile(language: result == 'English' ? 'en' : 'tr');
    await _load();
  }

  void _infoPage(String title, String text) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
      body: Padding(padding: const EdgeInsets.all(20), child: Text(text, style: const TextStyle(fontSize: 15, height: 1.55))),
    )));
  }

  void _logoutInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Verilerin artık gerçek kullanıcı oturumuna bağlı. Telefon/SMS giriş ekranını eklediğimizde bu düğme güvenli çıkış ve yeniden giriş akışını tamamlayacak.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
      ),
    );
  }
}
