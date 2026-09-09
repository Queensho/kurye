import 'package:flutter/material.dart';

import 'customer_phone_auth_page.dart';
import 'data/app_data_service.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  static const blue = Color(0xFF178EF4);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF7A8390);

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
      final values = await Future.wait([
        data.getProfile(),
        data.getAddresses(),
        data.getShipments(),
      ]);
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
        title: const Text('Profil Bilgileri'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad Soyad')),
          const SizedBox(height: 10),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon')),
          const SizedBox(height: 10),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
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
        title: const Text('Adres Ekle'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: label, decoration: const InputDecoration(labelText: 'Adres adı', hintText: 'Ev, İş...')),
          const SizedBox(height: 10),
          TextField(controller: address, maxLines: 3, decoration: const InputDecoration(labelText: 'Açık adres')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (saved != true || label.text.trim().isEmpty || address.text.trim().isEmpty) return;
    await data.addAddress(label: label.text.trim(), addressLine: address.text.trim(), isDefault: addresses.isEmpty);
    await _load();
  }

  Future<void> _deleteAddress(String id) async {
    await data.deleteAddress(id);
    await _load();
  }

  Future<void> _setDefault(String id) async {
    await data.setDefaultAddress(id);
    await _load();
  }

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkış yapmak istiyor musun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Çıkış Yap')),
        ],
      ),
    );
    if (yes != true) return;
    await data.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const CustomerPhoneAuthPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final name = (profile['full_name'] ?? '').toString().trim();
    final phone = (profile['phone'] ?? '').toString();
    final email = (profile['email'] ?? '').toString();
    final delivered = shipments.where((e) => e['status'] == 'delivered').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Profilim', style: TextStyle(fontWeight: FontWeight.w900, color: navy)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: blue))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Row(children: [
                const CircleAvatar(radius: 34, backgroundColor: Color(0xFFEAF4FF), child: Icon(Icons.person_rounded, color: blue, size: 38)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name.isEmpty ? 'Profilini tamamla' : name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
                  if (phone.isNotEmpty) Text(phone, style: const TextStyle(color: muted)),
                  if (email.isNotEmpty) Text(email, style: const TextStyle(color: muted)),
                ])),
                IconButton.filledTonal(onPressed: _editProfile, icon: const Icon(Icons.edit_rounded)),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _stat('Toplam Gönderi', '${shipments.length}', Icons.inventory_2_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _stat('Teslim Edildi', '$delivered', Icons.check_circle_outline_rounded)),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Expanded(child: Text('Adreslerim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: navy))),
                  TextButton.icon(onPressed: _addAddress, icon: const Icon(Icons.add_rounded), label: const Text('Ekle')),
                ]),
                if (addresses.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Center(child: Text('Kayıtlı adres yok', style: TextStyle(color: muted))))
                else
                  for (final item in addresses) ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: const Color(0xFFEAF4FF), child: Icon(item['is_default'] == true ? Icons.home_rounded : Icons.location_on_outlined, color: blue)),
                    title: Text((item['label'] ?? 'Adres').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text((item['address_line'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'default') await _setDefault(item['id'].toString());
                        if (value == 'delete') await _deleteAddress(item['id'].toString());
                      },
                      itemBuilder: (_) => [
                        if (item['is_default'] != true) const PopupMenuItem(value: 'default', child: Text('Varsayılan yap')),
                        const PopupMenuItem(value: 'delete', child: Text('Sil')),
                      ],
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Çıkış Yap'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), foregroundColor: const Color(0xFFD94A4A), side: const BorderSide(color: Color(0xFFFFC7C7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            ),
            const SizedBox(height: 24),
            const Center(child: Text('Müşteri • v1.0.0', style: TextStyle(color: muted, fontSize: 11))),
          ],
        ),
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [CircleAvatar(backgroundColor: const Color(0xFFEAF4FF), child: Icon(icon, color: blue)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)), Text(title, style: const TextStyle(fontSize: 10, color: muted))]))]),
  );
}
