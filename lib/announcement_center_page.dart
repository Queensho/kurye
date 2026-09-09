import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class AnnouncementCenterPage extends StatelessWidget {
  const AnnouncementCenterPage({super.key, required this.audience});

  final String audience;

  @override
  Widget build(BuildContext context) {
    final data = AppDataService.instance;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: data.client
            .from('announcements')
            .stream(primaryKey: ['id'])
            .eq('is_active', true)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          final rows = (snapshot.data ?? const <Map<String, dynamic>>[])
              .where((r) => r['audience'] == 'all' || r['audience'] == audience)
              .toList();
          if (snapshot.connectionState == ConnectionState.waiting && rows.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (rows.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 58, color: Color(0xFF8A97A8)),
                  SizedBox(height: 12),
                  Text('Henüz bildirim yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = rows[i];
              final created = DateTime.tryParse((r['created_at'] ?? '').toString())?.toLocal();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, 5))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF168CF5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((r['title'] ?? '').toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10213E))),
                          const SizedBox(height: 4),
                          Text((r['body'] ?? '').toString(), style: const TextStyle(color: Color(0xFF74839A), height: 1.35)),
                          if (created != null) ...[
                            const SizedBox(height: 8),
                            Text('${created.day.toString().padLeft(2, '0')}.${created.month.toString().padLeft(2, '0')}.${created.year}  ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: Color(0xFF9AA5B5))),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminAnnouncementPage extends StatefulWidget {
  const AdminAnnouncementPage({super.key});

  @override
  State<AdminAnnouncementPage> createState() => _AdminAnnouncementPageState();
}

class _AdminAnnouncementPageState extends State<AdminAnnouncementPage> {
  final data = AppDataService.instance;
  final title = TextEditingController();
  final body = TextEditingController();
  String audience = 'all';
  bool sending = false;

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Başlık ve mesaj zorunlu.')));
      return;
    }
    setState(() => sending = true);
    try {
      await data.client.from('announcements').insert({
        'title': title.text.trim(),
        'body': body.text.trim(),
        'audience': audience,
        'is_active': true,
        'created_by': data.userId,
      });
      if (!mounted) return;
      title.clear();
      body.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duyuru gönderildi.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gönderilemedi: $e')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> row) async {
    await data.client.from('announcements').update({
      'is_active': row['is_active'] != true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', row['id']);
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    await data.client.from('announcements').delete().eq('id', row['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Duyuru & Bildirim', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(children: [
                  CircleAvatar(backgroundColor: Color(0xFFE8F4FF), child: Icon(Icons.campaign_rounded, color: Color(0xFF168CF5))),
                  SizedBox(width: 10),
                  Expanded(child: Text('Yeni duyuru gönder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                ]),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('Müşteri'), selected: audience == 'customer', onSelected: (_) => setState(() => audience = 'customer')),
                    ChoiceChip(label: const Text('Kurye'), selected: audience == 'courier', onSelected: (_) => setState(() => audience = 'courier')),
                    ChoiceChip(label: const Text('Her İkisi'), selected: audience == 'all', onSelected: (_) => setState(() => audience = 'all')),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Başlık', filled: true, border: OutlineInputBorder(borderSide: BorderSide.none))),
                const SizedBox(height: 10),
                TextField(controller: body, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'Mesaj / duyuru', alignLabelWithHint: true, filled: true, border: OutlineInputBorder(borderSide: BorderSide.none))),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: sending ? null : _send,
                    icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
                    label: Text(sending ? 'Gönderiliyor...' : 'Bildirimi Gönder', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Seçtiğin hedefe göre müşteri, kurye veya her iki uygulamanın Bildirimler alanında anında görünür.', style: TextStyle(fontSize: 12, color: Color(0xFF74839A))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Gönderilen Duyurular', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: data.client.from('announcements').stream(primaryKey: ['id']).order('created_at', ascending: false),
            builder: (context, snapshot) {
              final rows = snapshot.data ?? const <Map<String, dynamic>>[];
              if (rows.isEmpty) return const Card(child: ListTile(title: Text('Henüz duyuru gönderilmedi.')));
              return Column(
                children: rows.map((r) => Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: const Color(0xFFE8F4FF), child: Icon(r['audience'] == 'courier' ? Icons.two_wheeler_rounded : r['audience'] == 'customer' ? Icons.person_rounded : Icons.groups_rounded, color: const Color(0xFF168CF5))),
                    title: Text((r['title'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${r['body'] ?? ''}\n${r['audience'] == 'all' ? 'Her İkisi' : r['audience'] == 'courier' ? 'Kurye' : 'Müşteri'} • ${r['is_active'] == true ? 'Aktif' : 'Pasif'}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'toggle') await _toggle(r);
                        if (v == 'delete') await _delete(r);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'toggle', child: Text(r['is_active'] == true ? 'Pasif Yap' : 'Aktif Yap')),
                        const PopupMenuItem(value: 'delete', child: Text('Sil')),
                      ],
                    ),
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class NotificationBellOverlay extends StatelessWidget {
  const NotificationBellOverlay({super.key, required this.child, required this.audience});

  final Widget child;
  final String audience;

  @override
  Widget build(BuildContext context) {
    final data = AppDataService.instance;
    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          right: 14,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: data.client.from('announcements').stream(primaryKey: ['id']).eq('is_active', true),
            builder: (context, snapshot) {
              final count = (snapshot.data ?? const <Map<String, dynamic>>[])
                  .where((r) => r['audience'] == 'all' || r['audience'] == audience)
                  .length;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AnnouncementCenterPage(audience: audience))),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4))]),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Center(child: Icon(Icons.notifications_none_rounded, color: Color(0xFF168CF5))),
                        if (count > 0)
                          Positioned(
                            right: -2,
                            top: -3,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: Color(0xFFFF4D67), shape: BoxShape.circle),
                              child: Text(count > 9 ? '9+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
