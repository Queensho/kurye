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
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFB9DAFF), width: 2),
                ),
                child: const Icon(Icons.person_rounded, color: blue, size: 43),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tayfun', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: navy)),
                  SizedBox(height: 4),
                  Text('+90 5•• ••• •• ••', style: TextStyle(fontSize: 13, color: muted)),
                  SizedBox(height: 2),
                  Text('tayfun@example.com', style: TextStyle(fontSize: 12, color: muted)),
                ]),
              ),
              IconButton(
                onPressed: () => _editProfile(context),
                icon: const Icon(Icons.edit_rounded, color: blue),
              ),
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
            _item(Icons.person_outline_rounded, 'Kişisel Bilgiler', 'Ad, telefon ve e-posta', () => _editProfile(context)),
            _item(Icons.location_on_outlined, 'Kayıtlı Adresler', 'Ev ve iş adreslerini yönet', () => _showInfo('Kayıtlı adresler')),
            _item(Icons.credit_card_rounded, 'Ödeme Yöntemleri', 'Kart ve ödeme ayarları', () => _showInfo('Ödeme yöntemleri')),
          ]),
          const SizedBox(height: 14),
          _section('Tercihler', [
            _switchItem(Icons.notifications_none_rounded, 'Bildirimler', 'Gönderi ve mesaj bildirimleri'),
            _item(Icons.language_rounded, 'Dil', 'Türkçe', () => _showInfo('Dil seçimi')),
          ]),
          const SizedBox(height: 14),
          _section('Destek', [
            _item(Icons.help_outline_rounded, 'Yardım Merkezi', 'Sık sorulan sorular ve destek', () => _showInfo('Yardım merkezi')),
            _item(Icons.shield_outlined, 'Gizlilik ve Güvenlik', 'Hesap ve veri ayarları', () => _showInfo('Gizlilik ve güvenlik')),
            _item(Icons.description_outlined, 'Kullanım Koşulları', 'Yasal bilgiler', () => _showInfo('Kullanım koşulları')),
          ]),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _showInfo('Çıkış işlemi'),
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
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: navy)),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
            child: Column(children: children),
          ),
        ],
      );

  Widget _item(IconData icon, String title, String subtitle, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: blue, size: 20),
            ),
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

  Widget _switchItem(IconData icon, String title, String subtitle) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: blue, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bildirimler', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: navy)),
            SizedBox(height: 2),
            Text('Gönderi ve mesaj bildirimleri', style: TextStyle(fontSize: 10.5, color: muted)),
          ])),
          Switch(value: notifications, onChanged: (v) => setState(() => notifications = v)),
        ]),
      );

  void _showInfo(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$text açıldı.')));
  }

  void _editProfile(BuildContext context) {
    final name = TextEditingController(text: 'Tayfun');
    final phone = TextEditingController(text: '+90 555 000 00 00');
    final email = TextEditingController(text: 'tayfun@example.com');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Profili Düzenle', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: navy)),
          const SizedBox(height: 16),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad Soyad', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil bilgileri kaydedildi.')));
              },
              child: const Text('Kaydet'),
            ),
          ),
        ]),
      ),
    );
  }
}
