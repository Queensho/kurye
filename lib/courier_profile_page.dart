import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'courier_job_pool_page.dart';
import 'data/app_data_service.dart';

class CourierProfilePage extends StatefulWidget {
  const CourierProfilePage({super.key});

  @override
  State<CourierProfilePage> createState() => _CourierProfilePageState();
}

class _CourierProfilePageState extends State<CourierProfilePage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF718198);
  static const bg = Color(0xFFF5FAFF);
  static const green = Color(0xFF10B866);

  final _picker = ImagePicker();
  bool online = true, notifications = true, vibration = true, sound = true, loading = true;
  String name = 'Kurye', phone = '', email = '', vehicle = 'Motosiklet', plate = '', iban = '', bankName = '', language = 'Türkçe', mapApp = 'Google Maps';
  Uint8List? avatarBytes;
  final Map<String, String> documentStatus = {'Ehliyet': 'Yüklenmedi', 'Ruhsat': 'Yüklenmedi', 'Sigorta': 'Yüklenmedi'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await AppDataService.instance.getProfile();
      if (!mounted) return;
      setState(() {
        name = (p['full_name'] ?? 'Kurye').toString();
        phone = (p['phone'] ?? '').toString();
        email = (p['email'] ?? '').toString();
        notifications = p['notifications_enabled'] != false;
        language = (p['language'] ?? 'Türkçe').toString();
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<String?> _ask(String title, String value, {TextInputType? keyboard}) async {
    final c = TextEditingController(text: value);
    final result = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title),
        content: TextField(controller: c, autofocus: true, keyboardType: keyboard, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Kaydet'))],
      ),
    );
    c.dispose();
    return result;
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 78, maxWidth: 900);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => avatarBytes = bytes);
      _msg('Profil fotoğrafı güncellendi.');
    } catch (_) {
      _msg('Fotoğraf seçilemedi.');
    }
  }

  Future<void> _editPersonal() async {
    final n = await _ask('Ad Soyad', name); if (n == null) return;
    final p = await _ask('Telefon', phone, keyboard: TextInputType.phone); if (p == null) return;
    final e = await _ask('E-posta', email, keyboard: TextInputType.emailAddress); if (e == null) return;
    try {
      await AppDataService.instance.updateProfile(fullName: n, phone: p, email: e);
      if (!mounted) return;
      setState(() { name = n; phone = p; email = e; });
      _msg('Kişisel bilgiler kaydedildi.');
    } catch (err) { _msg('Kaydedilemedi: $err'); }
  }

  Future<void> _editVehicle() async {
    final v = await _ask('Araç', vehicle); if (v == null) return;
    final p = await _ask('Plaka', plate); if (p == null) return;
    setState(() { vehicle = v; plate = p.toUpperCase(); });
    _msg('Araç bilgileri güncellendi.');
  }

  Future<void> _payment() async {
    final b = await _ask('Banka', bankName); if (b == null) return;
    final i = await _ask('IBAN', iban); if (i == null) return;
    setState(() { bankName = b; iban = i.toUpperCase(); });
    _msg('Ödeme bilgileri güncellendi.');
  }

  Future<void> _documents() async {
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Ehliyet & Belgeler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
            const SizedBox(height: 10),
            for (final title in documentStatus.keys)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Color(0xFFEAF5FF), child: Icon(Icons.description_outlined, color: blue)),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(documentStatus[title]!, style: TextStyle(color: documentStatus[title] == 'Yüklendi' ? green : muted)),
                trailing: FilledButton.tonal(onPressed: () async {
                  final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (f == null) return;
                  setState(() => documentStatus[title] = 'Yüklendi');
                  setSheetState(() {});
                  _msg('$title yüklendi.');
                }, child: Text(documentStatus[title] == 'Yüklendi' ? 'Değiştir' : 'Yükle')),
              ),
          ]),
        ),
      )),
    );
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (_) => StatefulBuilder(builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Uygulama Ayarları', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
            SwitchListTile(title: const Text('Bildirimler'), value: notifications, onChanged: (v) async { setState(() => notifications = v); setSheetState(() {}); try { await AppDataService.instance.updateProfile(notificationsEnabled: v); } catch (_) {} }),
            SwitchListTile(title: const Text('Titreşim'), value: vibration, onChanged: (v) { setState(() => vibration = v); setSheetState(() {}); }),
            SwitchListTile(title: const Text('Ses'), value: sound, onChanged: (v) { setState(() => sound = v); setSheetState(() {}); }),
            ListTile(leading: const Icon(Icons.language_rounded), title: const Text('Dil'), subtitle: Text(language), trailing: const Icon(Icons.chevron_right_rounded), onTap: () async {
              final selected = await showDialog<String>(context: context, builder: (d) => SimpleDialog(title: const Text('Dil seç'), children: [for (final l in ['Türkçe', 'English']) SimpleDialogOption(onPressed: () => Navigator.pop(d, l), child: Text(l))]));
              if (selected == null) return; setState(() => language = selected); setSheetState(() {}); try { await AppDataService.instance.updateProfile(language: selected); } catch (_) {}
            }),
            ListTile(leading: const Icon(Icons.navigation_rounded), title: const Text('Varsayılan Navigasyon'), subtitle: Text(mapApp), trailing: const Icon(Icons.chevron_right_rounded), onTap: () async {
              final selected = await showDialog<String>(context: context, builder: (d) => SimpleDialog(title: const Text('Navigasyon uygulaması'), children: [for (final app in ['Google Maps', 'Yandex Maps', 'Waze']) SimpleDialogOption(onPressed: () => Navigator.pop(d, app), child: Text(app))]));
              if (selected != null) { setState(() => mapApp = selected); setSheetState(() {}); }
            }),
          ]),
        ),
      )),
    );
  }

  Future<void> _support() async {
    await showModalBottomSheet<void>(
      context: context, showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Yardım & Destek', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
          ListTile(leading: const Icon(Icons.support_agent_rounded), title: const Text('Destek talebi oluştur'), onTap: () async { Navigator.pop(sheetContext); final t = await _ask('Destek talebi', ''); if (t != null && t.isNotEmpty) _msg('Destek talebin oluşturuldu.'); }),
          ListTile(leading: const Icon(Icons.help_outline_rounded), title: const Text('Sık Sorulan Sorular'), onTap: () { Navigator.pop(sheetContext); showDialog<void>(context: context, builder: (d) => AlertDialog(title: const Text('Sık Sorulan Sorular'), content: const Text('• İş havuzundan işi nasıl alırım?\nİşi Al butonuna dokun.\n\n• Teslimatı nasıl tamamlarım?\nAktif İş ekranındaki adımları sırayla tamamla.'), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Kapat'))])); }),
        ]),
      )),
    );
  }

  Future<void> _showEarnings() async {
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => const SafeArea(child: Padding(
      padding: EdgeInsets.fromLTRB(18, 6, 18, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Kazançlar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
        ListTile(title: Text('Bugün'), trailing: Text('₺1.250', style: TextStyle(fontWeight: FontWeight.w900, color: green))),
        ListTile(title: Text('Bu Hafta'), trailing: Text('₺6.480', style: TextStyle(fontWeight: FontWeight.w900, color: green))),
        ListTile(title: Text('Bu Ay'), trailing: Text('₺24.900', style: TextStyle(fontWeight: FontWeight.w900, color: green))),
      ]),
    )));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('Çıkış yapılsın mı?'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Çıkış Yap'))]));
    if (ok != true) return;
    try { await AppDataService.instance.signOut(); if (mounted) _msg('Çıkış yapıldı.'); } catch (_) { _msg('Çıkış işlemi tamamlanamadı.'); }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final compact = w < 390;
      final side = compact ? 14.0 : 18.0;
      final gap = compact ? 12.0 : 15.0;
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(children: [
                Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : ListView(
                  padding: EdgeInsets.fromLTRB(side, 12, side, 16),
                  children: [
                    _header(compact), SizedBox(height: gap), _profile(compact), SizedBox(height: gap), _stats(compact), SizedBox(height: gap), _vehicleCard(compact), SizedBox(height: gap), _status(compact), SizedBox(height: gap), _menus(compact), SizedBox(height: gap), _logoutButton(compact),
                  ],
                )),
                _nav(compact),
              ]),
            ),
          ),
        ),
      );
    });
  }

  Widget _header(bool compact) => Row(children: [
    _squareButton(Icons.arrow_back_rounded, () => Navigator.maybePop(context), compact),
    Expanded(child: Column(children: [
      Text('Kurye Profilim', maxLines: 1, style: TextStyle(color: navy, fontSize: compact ? 20 : 23, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text('Hesabını yönet, bilgilerini güncelle.', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: compact ? 11 : 12)),
    ])),
    _squareButton(Icons.settings_rounded, _settings, compact),
  ]);

  Widget _squareButton(IconData icon, VoidCallback onTap, bool compact) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(18),
    child: Container(width: compact ? 46 : 50, height: compact ? 46 : 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: navy, size: compact ? 23 : 25)),
  );

  Widget _profile(bool compact) {
    final r = compact ? 43.0 : 48.0;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      InkWell(onTap: _pickAvatar, borderRadius: BorderRadius.circular(60), child: Stack(clipBehavior: Clip.none, children: [
        CircleAvatar(radius: r, backgroundColor: const Color(0xFFE4F2FF), backgroundImage: avatarBytes == null ? null : MemoryImage(avatarBytes!), child: avatarBytes == null ? Icon(Icons.person_rounded, color: blue, size: compact ? 52 : 58) : null),
        Positioned(right: -2, bottom: -2, child: CircleAvatar(radius: compact ? 16 : 17, backgroundColor: navy, child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: compact ? 16 : 17))),
      ])),
      SizedBox(width: compact ? 12 : 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(name.isEmpty ? 'Kurye' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: navy, fontSize: compact ? 18 : 21, fontWeight: FontWeight.w900))), const SizedBox(width: 4), Icon(Icons.verified_rounded, color: blue, size: compact ? 20 : 22)]),
        const SizedBox(height: 3),
        Text(phone.isEmpty ? 'Telefon ekle' : phone, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: compact ? 12 : 13)),
        const SizedBox(height: 5),
        Row(children: [const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18), const SizedBox(width: 3), Text('4.9', style: TextStyle(color: navy, fontSize: compact ? 12 : 13, fontWeight: FontWeight.w900)), Flexible(child: Text('  (320 değerlendirme)', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: compact ? 10 : 11)))]),
        const SizedBox(height: 7),
        Container(padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 11, vertical: 4), decoration: BoxDecoration(color: online ? const Color(0xFFE8FBF2) : const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(14)), child: Text(online ? '● Aktif' : '● Pasif', style: TextStyle(color: online ? green : muted, fontSize: compact ? 11 : 12, fontWeight: FontWeight.w800))),
      ])),
    ]);
  }

  Widget _stats(bool compact) => Row(children: [
    _stat(Icons.inventory_2_outlined, '1.248', 'Toplam Teslimat', compact), const SizedBox(width: 7),
    _stat(Icons.emoji_events_outlined, '%98', 'Başarı Oranı', compact), const SizedBox(width: 7),
    _stat(Icons.schedule_rounded, '4.9', 'Müşteri Puanı', compact),
  ]);

  Widget _stat(IconData icon, String value, String label, bool compact) => Expanded(child: Container(
    height: compact ? 78 : 84, padding: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircleAvatar(radius: compact ? 17 : 19, backgroundColor: const Color(0xFFEAF5FF), child: Icon(icon, color: blue, size: compact ? 18 : 20)),
      SizedBox(width: compact ? 6 : 8),
      Flexible(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(color: navy, fontSize: compact ? 17 : 19, fontWeight: FontWeight.w900))),
        const SizedBox(height: 2),
        Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: compact ? 9 : 10, height: 1.05)),
      ])),
    ]),
  ));

  Widget _vehicleCard(bool compact) => InkWell(onTap: _editVehicle, borderRadius: BorderRadius.circular(23), child: _card(Row(children: [
    Container(width: compact ? 64 : 72, height: compact ? 64 : 72, decoration: BoxDecoration(color: const Color(0xFFEAF5FF), borderRadius: BorderRadius.circular(18)), child: Icon(Icons.two_wheeler_rounded, size: compact ? 39 : 43, color: blue)),
    SizedBox(width: compact ? 10 : 13),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(vehicle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: navy, fontWeight: FontWeight.w900, fontSize: compact ? 16 : 18)), const SizedBox(height: 3), Text(plate.isEmpty ? 'Plaka ekle' : plate, style: TextStyle(color: muted, fontSize: compact ? 12 : 13))])),
    SizedBox(width: compact ? 8 : 12),
    Flexible(child: FilledButton.tonal(onPressed: _editVehicle, style: FilledButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: FittedBox(fit: BoxFit.scaleDown, child: Text('Araç Bilgilerini\nDüzenle', textAlign: TextAlign.center, style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w800))))),
  ]), compact));

  Widget _status(bool compact) => Container(
    padding: EdgeInsets.all(compact ? 14 : 16), decoration: BoxDecoration(color: const Color(0xFFEAF6FF), borderRadius: BorderRadius.circular(24)),
    child: Column(children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Çalışma Durumu', style: TextStyle(color: navy, fontSize: compact ? 17 : 19, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(online ? 'Şu anda yeni iş alabilirsin.' : 'Çevrimdışısın.', style: TextStyle(color: muted, fontSize: compact ? 11 : 12))])), Switch(value: online, onChanged: (v) => setState(() => online = v))]),
      const SizedBox(height: 10),
      FilledButton.icon(onPressed: () => setState(() => online = !online), icon: Icon(online ? Icons.play_arrow_rounded : Icons.pause_rounded), label: Text(online ? 'İşe Hazırım' : 'Çevrimdışı', style: const TextStyle(fontWeight: FontWeight.w900)), style: FilledButton.styleFrom(minimumSize: Size.fromHeight(compact ? 48 : 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)))),
    ]),
  );

  Widget _card(Widget child, bool compact) => Container(padding: EdgeInsets.all(compact ? 13 : 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: child);

  Widget _menus(bool compact) {
    final items = [
      (Icons.person_outline_rounded, 'Kişisel Bilgiler', 'Ad, soyad, telefon, e-posta', _editPersonal),
      (Icons.description_outlined, 'Ehliyet & Belgeler', 'Ehliyet, ruhsat, sigorta', _documents),
      (Icons.account_balance_outlined, 'Ödeme Bilgileri', iban.isEmpty ? 'Banka hesabı ve kazanç ayarları' : '$bankName • ${iban.length > 8 ? '${iban.substring(0, 4)}••••${iban.substring(iban.length - 4)}' : iban}', _payment),
      (Icons.settings_outlined, 'Uygulama Ayarları', 'Bildirimler, harita, dil', _settings),
      (Icons.support_agent_rounded, 'Yardım & Destek', 'Sık sorulan sorular', _support),
    ];
    return _card(Column(children: [for (int i = 0; i < items.length; i++) ...[
      ListTile(
        dense: compact,
        minVerticalPadding: compact ? 7 : 9,
        contentPadding: EdgeInsets.zero,
        onTap: items[i].$4,
        leading: CircleAvatar(radius: compact ? 20 : 22, backgroundColor: const Color(0xFFEAF5FF), child: Icon(items[i].$1, color: blue, size: compact ? 21 : 23)),
        title: Text(items[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: compact ? 13 : 14)),
        subtitle: Text(items[i].$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: compact ? 10 : 11)),
        trailing: const Icon(Icons.chevron_right_rounded, color: muted),
      ),
      if (i < items.length - 1) const Divider(height: 1, color: Color(0xFFE8EEF5)),
    ]]), compact);
  }

  Widget _logoutButton(bool compact) => FilledButton.icon(onPressed: _logout, icon: const Icon(Icons.logout_rounded), label: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.w800)), style: FilledButton.styleFrom(minimumSize: Size.fromHeight(compact ? 50 : 54), backgroundColor: const Color(0xFFFFEDEE), foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))));

  Widget _nav(bool compact) => Container(
    margin: EdgeInsets.fromLTRB(compact ? 12 : 16, 5, compact ? 12 : 16, 8),
    padding: EdgeInsets.symmetric(horizontal: 4, vertical: compact ? 7 : 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 5))]),
    child: Row(children: [
      _navItem(Icons.home_rounded, 'Anasayfa', () => Navigator.maybePop(context), compact),
      _navItem(Icons.inventory_2_outlined, 'İşler', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourierJobPoolPage())), compact),
      _navItem(Icons.bar_chart_rounded, 'Kazançlar', _showEarnings, compact),
      _navItem(Icons.person_rounded, 'Profil', () {}, compact, selected: true),
    ]),
  );

  Widget _navItem(IconData icon, String label, VoidCallback onTap, bool compact, {bool selected = false}) => Expanded(child: InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 7),
      decoration: selected ? BoxDecoration(color: const Color(0xFFEAF5FF), borderRadius: BorderRadius.circular(18)) : null,
      child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: selected ? blue : muted, size: compact ? 22 : 24), const SizedBox(height: 2), Text(label, maxLines: 1, style: TextStyle(fontSize: compact ? 9 : 10, color: selected ? blue : muted, fontWeight: selected ? FontWeight.w800 : FontWeight.w600))]),
    ),
  ));
}
