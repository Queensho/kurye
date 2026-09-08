import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const blue = Color(0xFF178EF4);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF7A8390);

  bool notifications = true;
  String language = 'Türkçe';
  String name = 'Tayfun';
  String phone = '+90 555 000 00 00';
  String email = 'tayfun@example.com';

  final List<Map<String, String>> addresses = [
    {'title': 'Ev', 'address': 'Şişli, Mecidiyeköy, İstanbul'},
    {'title': 'İş', 'address': 'Kadıköy, İstanbul'},
  ];

  final List<Map<String, String>> cards = [
    {'name': 'Visa', 'number': '•••• 4242'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Profilim', style: TextStyle(fontWeight: FontWeight.w900, color: navy)),
      ),
      body: ListView(
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
                  Text(phone, style: const TextStyle(fontSize: 13, color: muted)),
                  const SizedBox(height: 2),
                  Text(email, style: const TextStyle(fontSize: 12, color: muted)),
                ]),
              ),
              IconButton(onPressed: _editProfile, icon: const Icon(Icons.edit_rounded, color: blue)),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _stat('12', 'Gönderi', Icons.inventory_2_outlined)),
            const SizedBox(width: 10),
            Expanded(child: _stat('9', 'Tamamlandı', Icons.check_circle_outline_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _stat('4.9', 'Puan', Icons.star_outline_rounded)),
          ]),
          const SizedBox(height: 18),
          _section('Hesap', [
            _item(Icons.person_outline_rounded, 'Kişisel Bilgiler', 'Ad, telefon ve e-posta', _editProfile),
            _item(Icons.location_on_outlined, 'Kayıtlı Adresler', '${addresses.length} kayıtlı adres', _openAddresses),
            _item(Icons.credit_card_rounded, 'Ödeme Yöntemleri', '${cards.length} kart • Nakit kullanılabilir', _openPayments),
          ]),
          const SizedBox(height: 14),
          _section('Tercihler', [
            _switchItem(),
            _item(Icons.language_rounded, 'Dil', language, _chooseLanguage),
          ]),
          const SizedBox(height: 14),
          _section('Destek', [
            _item(Icons.help_outline_rounded, 'Yardım Merkezi', 'Sık sorulan sorular ve destek', _openHelp),
            _item(Icons.shield_outlined, 'Gizlilik ve Güvenlik', 'Hesap ve veri ayarları', _openPrivacy),
            _item(Icons.description_outlined, 'Kullanım Koşulları', 'Yasal bilgiler', _openTerms),
          ]),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _logout,
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
          Switch(value: notifications, onChanged: (v) => setState(() => notifications = v)),
        ]),
      );

  void _editProfile() {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);
    final emailController = TextEditingController(text: email);
    showModalBottomSheet(
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
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
            setState(() {
              name = nameController.text.trim().isEmpty ? name : nameController.text.trim();
              phone = phoneController.text.trim().isEmpty ? phone : phoneController.text.trim();
              email = emailController.text.trim().isEmpty ? email : emailController.text.trim();
            });
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil bilgileri kaydedildi.')));
          }, child: const Text('Kaydet'))),
        ]),
      ),
    );
  }

  void _openAddresses() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Kayıtlı Adreslerim', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: navy)),
              const SizedBox(height: 12),
              ...addresses.asMap().entries.map((entry) => Card(
                    elevation: 0,
                    color: const Color(0xFFF7FBFF),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFFEAF4FF), child: Icon(Icons.location_on_rounded, color: blue)),
                      title: Text(entry.value['title']!, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(entry.value['address']!),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () {
                        setState(() => addresses.removeAt(entry.key));
                        setSheetState(() {});
                      }),
                    ),
                  )),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _addAddress(sheetContext, setSheetState), icon: const Icon(Icons.add_location_alt_rounded), label: const Text('Yeni Adres Ekle'))),
            ]),
          ),
        );
      }),
    );
  }

  void _addAddress(BuildContext sheetContext, StateSetter setSheetState) {
    final title = TextEditingController();
    final address = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adres Ekle'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Başlık (Ev, İş...)')),
          const SizedBox(height: 8),
          TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Adres')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
          FilledButton(onPressed: () {
            if (title.text.trim().isEmpty || address.text.trim().isEmpty) return;
            setState(() => addresses.add({'title': title.text.trim(), 'address': address.text.trim()}));
            setSheetState(() {});
            Navigator.pop(dialogContext);
          }, child: const Text('Ekle')),
        ],
      ),
    );
  }

  void _openPayments() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ödeme Yöntemlerim', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: navy)),
            const SizedBox(height: 12),
            const ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: Color(0xFFEAF8F0), child: Icon(Icons.payments_rounded, color: Color(0xFF18A768))), title: Text('Nakit', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Teslimatta nakit ödeme')),
            ...cards.asMap().entries.map((entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEAF4FF), child: Icon(Icons.credit_card_rounded, color: blue)),
                  title: Text('${entry.value['name']} ${entry.value['number']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Online ödeme için kayıtlı kart'),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () {
                    setState(() => cards.removeAt(entry.key));
                    setSheetState(() {});
                  }),
                )),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _addCard(setSheetState), icon: const Icon(Icons.add_card_rounded), label: const Text('Kart Ekle'))),
          ]),
        ),
      )),
    );
  }

  void _addCard(StateSetter setSheetState) {
    final cardNumber = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kart Ekle'),
        content: TextField(controller: cardNumber, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kart numarası', hintText: '1234 5678 9012 3456')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
          FilledButton(onPressed: () {
            final digits = cardNumber.text.replaceAll(RegExp(r'\D'), '');
            if (digits.length < 4) return;
            setState(() => cards.add({'name': 'Kart', 'number': '•••• ${digits.substring(digits.length - 4)}'}));
            setSheetState(() {});
            Navigator.pop(dialogContext);
          }, child: const Text('Kaydet')),
        ],
      ),
    );
  }

  void _chooseLanguage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text('Dil Seçimi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
        for (final item in const ['Türkçe', 'English']) ListTile(title: Text(item), trailing: language == item ? const Icon(Icons.check_rounded, color: blue) : null, onTap: () => Navigator.pop(context, item)),
        const SizedBox(height: 12),
      ])),
    );
    if (result != null) setState(() => language = result);
  }

  void _openHelp() => _textDialog('Yardım Merkezi', 'Gönderi oluşturma, kurye takibi, ödeme ve hesap işlemleriyle ilgili destek alanı. Canlı destek bağlantısı backend aşamasında buraya bağlanabilir.');
  void _openPrivacy() => _textDialog('Gizlilik ve Güvenlik', 'Konum, bildirim ve hesap verilerini buradan yönetebilirsin. Güvenlik seçenekleri backend kimlik doğrulama sistemiyle bağlanacak.');
  void _openTerms() => _textDialog('Kullanım Koşulları', 'Kurye uygulamasını kullanarak gönderi ve ödeme kurallarını kabul etmiş olursun. Nihai yasal metin yayın öncesi buraya eklenecek.');

  void _textDialog(String title, String text) {
    showDialog(context: context, builder: (context) => AlertDialog(title: Text(title), content: Text(text), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))]));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
          FilledButton(onPressed: () {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Çıkış işlemi hazır. Giriş sistemi bağlandığında oturum kapatılacak.')));
          }, child: const Text('Çıkış Yap')),
        ],
      ),
    );
  }
}
