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

  bool online = true;
  bool notifications = true;
  bool loading = true;
  bool vibration = true;
  bool sound = true;

  String name = 'Kurye';
  String phone = '';
  String email = '';
  String vehicle = 'Motosiklet';
  String plate = '';
  String iban = '';
  String bankName = '';
  String language = 'Türkçe';
  String mapApp = 'Google Maps';

  Uint8List? avatarBytes;

  final Map<String, String> documentStatus = {
    'Ehliyet': 'Yüklenmedi',
    'Ruhsat': 'Yüklenmedi',
    'Sigorta': 'Yüklenmedi',
  };

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
    final controller = TextEditingController(text: value);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboard,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Kaydet')),
        ],
      ),
    );
    controller.dispose();
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
    final n = await _ask('Ad Soyad', name);
    if (n == null) return;
    final p = await _ask('Telefon', phone, keyboard: TextInputType.phone);
    if (p == null) return;
    final e = await _ask('E-posta', email, keyboard: TextInputType.emailAddress);
    if (e == null) return;
    try {
      await AppDataService.instance.updateProfile(fullName: n, phone: p, email: e);
      if (!mounted) return;
      setState(() {
        name = n;
        phone = p;
        email = e;
      });
      _msg('Kişisel bilgiler kaydedildi.');
    } catch (err) {
      _msg('Kaydedilemedi: $err');
    }
  }

  Future<void> _editVehicle() async {
    final v = await _ask('Araç', vehicle);
    if (v == null) return;
    final p = await _ask('Plaka', plate);
    if (p == null) return;
    setState(() {
      vehicle = v;
      plate = p.toUpperCase();
    });
    _msg('Araç bilgileri güncellendi.');
  }

  Future<void> _payment() async {
    final bank = await _ask('Banka', bankName);
    if (bank == null) return;
    final value = await _ask('IBAN', iban);
    if (value == null) return;
    setState(() {
      bankName = bank;
      iban = value.toUpperCase();
    });
    _msg('Ödeme bilgileri güncellendi.');
  }

  Future<void> _documents() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ehliyet & Belgeler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: navy)),
              const SizedBox(height: 8),
              const Text('Belgelerini ekle ve durumlarını takip et.', style: TextStyle(color: muted)),
              const SizedBox(height: 14),
              for (final title in documentStatus.keys)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: const Color(0xFFEAF5FF), child: const Icon(Icons.description_outlined, color: blue)),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(documentStatus[title]!, style: TextStyle(color: documentStatus[title] == 'Yüklendi' ? green : muted)),
                  trailing: FilledButton.tonal(
                    onPressed: () async {
                      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (file == null) return;
                      setState(() => documentStatus[title] = 'Yüklendi');
                      setSheetState(() {});
                      _msg('$title yüklendi.');
                    },
                    child: Text(documentStatus[title] == 'Yüklendi' ? 'Değiştir' : 'Yükle'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Uygulama Ayarları', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: navy)),
              SwitchListTile(
                title: const Text('Bildirimler'),
                value: notifications,
                onChanged: (v) async {
                  setState(() => notifications = v);
                  setSheetState(() {});
                  try {
                    await AppDataService.instance.updateProfile(notificationsEnabled: v);
                  } catch (_) {}
                },
              ),
              SwitchListTile(title: const Text('Titreşim'), value: vibration, onChanged: (v) { setState(() => vibration = v); setSheetState(() {}); }),
              SwitchListTile(title: const Text('Ses'), value: sound, onChanged: (v) { setState(() => sound = v); setSheetState(() {}); }),
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('Dil'),
                subtitle: Text(language),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (d) => SimpleDialog(
                      title: const Text('Dil seç'),
                      children: [for (final l in ['Türkçe', 'English']) SimpleDialogOption(onPressed: () => Navigator.pop(d, l), child: Text(l))],
                    ),
                  );
                  if (selected == null) return;
                  setState(() => language = selected);
                  setSheetState(() {});
                  try { await AppDataService.instance.updateProfile(language: selected); } catch (_) {}
                },
              ),
              ListTile(
                leading: const Icon(Icons.navigation_rounded),
                title: const Text('Varsayılan Navigasyon'),
                subtitle: Text(mapApp),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (d) => SimpleDialog(
                      title: const Text('Navigasyon uygulaması'),
                      children: [for (final app in ['Google Maps', 'Yandex Maps', 'Waze']) SimpleDialogOption(onPressed: () => Navigator.pop(d, app), child: Text(app))],
                    ),
                  );
                  if (selected != null) { setState(() => mapApp = selected); setSheetState(() {}); }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _support() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yardım & Destek', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: navy)),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.support_agent_rounded)),
              title: const Text('Destek talebi oluştur'),
              subtitle: const Text('Sorununu bize bildir'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                Navigator.pop(sheetContext);
                final text = await _ask('Destek talebi', '');
                if (text != null && text.isNotEmpty) _msg('Destek talebin oluşturuldu.');
              },
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.help_outline_rounded)),
              title: const Text('Sık Sorulan Sorular'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(sheetContext);
                showDialog<void>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Sık Sorulan Sorular'),
                    content: const Text('• İş havuzundan işi nasıl alırım?\nİşi Al butonuna dokun.\n\n• Teslimatı nasıl tamamlarım?\nAktif İş ekranındaki adımları sırayla tamamla.\n\n• Kazanç ne zaman görünür?\nTeslimat tamamlandığında kazanç hesabına işlenir.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Kapat'))],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEarnings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Kazançlar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: navy)),
          SizedBox(height: 18),
          ListTile(leading: Icon(Icons.today_rounded, color: blue), title: Text('Bugün'), trailing: Text('₺1.250', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: green))),
          ListTile(leading: Icon(Icons.calendar_view_week_rounded, color: blue), title: Text('Bu Hafta'), trailing: Text('₺6.480', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: green))),
          ListTile(leading: Icon(Icons.calendar_month_rounded, color: blue), title: Text('Bu Ay'), trailing: Text('₺24.900', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: green))),
        ]),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text('Bu cihazdaki oturum kapatılacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Çıkış Yap')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AppDataService.instance.signOut();
      if (!mounted) return;
      _msg('Çıkış yapıldı.');
    } catch (_) {
      _msg('Çıkış işlemi tamamlanamadı.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        _header(),
                        const SizedBox(height: 20),
                        _profile(),
                        const SizedBox(height: 16),
                        _stats(),
                        const SizedBox(height: 16),
                        _vehicleCard(),
                        const SizedBox(height: 16),
                        _status(),
                        const SizedBox(height: 16),
                        _menus(),
                        const SizedBox(height: 16),
                        _logoutButton(),
                      ],
                    ),
            ),
            _nav(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Row(
        children: [
          _iconButton(Icons.arrow_back_rounded, () => Navigator.maybePop(context)),
          const Expanded(
            child: Column(children: [
              Text('Kurye Profilim', style: TextStyle(color: navy, fontSize: 25, fontWeight: FontWeight.w900)),
              Text('Hesabını yönet, bilgilerini güncelle.', style: TextStyle(color: muted)),
            ]),
          ),
          _iconButton(Icons.settings_rounded, _settings),
        ],
      );

  Widget _iconButton(IconData icon, VoidCallback onTap) => IconButton.filledTonal(onPressed: onTap, icon: Icon(icon));

  Widget _profile() => Row(
        children: [
          InkWell(
            onTap: _pickAvatar,
            borderRadius: BorderRadius.circular(60),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xFFE4F2FF),
                  backgroundImage: avatarBytes == null ? null : MemoryImage(avatarBytes!),
                  child: avatarBytes == null ? const Icon(Icons.person_rounded, color: blue, size: 62) : null,
                ),
                const Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 18, backgroundColor: navy, child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18))),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: Text(name.isEmpty ? 'Kurye' : name, style: const TextStyle(color: navy, fontSize: 22, fontWeight: FontWeight.w900))), const Icon(Icons.verified_rounded, color: blue)]),
                Text(phone.isEmpty ? 'Telefon ekle' : phone, style: const TextStyle(color: muted)),
                const SizedBox(height: 7),
                const Text('⭐ 4.9  •  320 değerlendirme', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: online ? const Color(0xFFE8FBF2) : const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(14)),
                  child: Text(online ? '● Aktif' : '● Pasif', style: TextStyle(color: online ? green : muted, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _stats() => Row(children: [
        _stat('1.248', 'Teslimat'),
        const SizedBox(width: 8),
        _stat('%98', 'Başarı'),
        const SizedBox(width: 8),
        _stat('4.9', 'Puan'),
      ]);

  Widget _stat(String value, String label) => Expanded(
        child: Container(
          height: 82,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: muted))]),
        ),
      );

  Widget _vehicleCard() => InkWell(
        onTap: _editVehicle,
        borderRadius: BorderRadius.circular(24),
        child: _card(
          Row(children: [
            const CircleAvatar(radius: 30, backgroundColor: Color(0xFFEAF5FF), child: Icon(Icons.two_wheeler_rounded, size: 35, color: blue)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(vehicle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), Text(plate.isEmpty ? 'Plaka ekle' : plate, style: const TextStyle(color: muted))])),
            const Icon(Icons.edit_rounded, color: blue),
          ]),
        ),
      );

  Widget _status() => _card(
        Row(children: [
          const Icon(Icons.power_settings_new_rounded, color: blue, size: 30),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Çalışma Durumu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), Text(online ? 'Yeni iş alabilirsin.' : 'Çevrimdışısın.', style: const TextStyle(color: muted))])),
          Switch(value: online, onChanged: (v) => setState(() => online = v)),
        ]),
      );

  Widget _card(Widget child) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: child);

  Widget _menus() {
    final items = [
      (Icons.person_outline_rounded, 'Kişisel Bilgiler', 'Ad, soyad, telefon, e-posta', _editPersonal),
      (Icons.description_outlined, 'Ehliyet & Belgeler', 'Ehliyet, ruhsat, sigorta', _documents),
      (Icons.account_balance_outlined, 'Ödeme Bilgileri', iban.isEmpty ? 'Banka hesabı ve IBAN' : '$bankName • ${iban.length > 8 ? iban.substring(0, 4) + '••••' + iban.substring(iban.length - 4) : iban}', _payment),
      (Icons.settings_outlined, 'Uygulama Ayarları', 'Bildirimler, harita, dil', _settings),
      (Icons.support_agent_rounded, 'Yardım & Destek', 'SSS ve destek talebi', _support),
    ];
    return _card(
      Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: items[i].$4,
              leading: CircleAvatar(backgroundColor: const Color(0xFFEAF5FF), child: Icon(items[i].$1, color: blue)),
              title: Text(items[i].$2, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(items[i].$3, style: const TextStyle(color: muted, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
            if (i < items.length - 1) const Divider(height: 1, color: Color(0xFFE8EEF5)),
          ],
        ],
      ),
    );
  }

  Widget _logoutButton() => FilledButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Çıkış Yap'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(55), backgroundColor: const Color(0xFFFFEDEE), foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      );

  Widget _nav() => _card(
        Row(children: [
          _navItem(Icons.home_rounded, 'Anasayfa', () => Navigator.maybePop(context)),
          _navItem(Icons.inventory_2_outlined, 'İşler', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourierJobPoolPage()))),
          _navItem(Icons.bar_chart_rounded, 'Kazançlar', _showEarnings),
          _navItem(Icons.person_rounded, 'Profil', () {}, selected: true),
        ]),
      );

  Widget _navItem(IconData icon, String label, VoidCallback onTap, {bool selected = false}) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: selected ? blue : muted), Text(label, style: TextStyle(fontSize: 10, color: selected ? blue : muted, fontWeight: selected ? FontWeight.w800 : FontWeight.w500))]),
          ),
        ),
      );
}
