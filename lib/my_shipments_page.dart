import 'package:flutter/material.dart';

import 'create_shipment_page_v2.dart';
import 'data/app_data_service.dart';

class MyShipmentsPage extends StatefulWidget {
  const MyShipmentsPage({super.key});

  @override
  State<MyShipmentsPage> createState() => _MyShipmentsPageState();
}

class _MyShipmentsPageState extends State<MyShipmentsPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF7C879C);
  static const green = Color(0xFF19C983);

  final data = AppDataService.instance;
  int tab = 0;

  bool _isPast(Map<String, dynamic> s) {
    final status = (s['status'] ?? '').toString();
    return status == 'delivered' || status == 'cancelled';
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'searching': return 'Kurye aranıyor';
      case 'courier_found': return 'Kurye bulundu';
      case 'pickup': return 'Kurye alımda';
      case 'picked_up': return 'Teslimatta';
      case 'delivered': return 'Teslim edildi';
      case 'cancelled': return 'İptal edildi';
      default: return value.isEmpty ? 'Aktif' : value;
    }
  }

  Color _statusColor(String value) {
    if (value == 'delivered') return green;
    if (value == 'cancelled') return const Color(0xFFE65252);
    if (value == 'pickup') return const Color(0xFFFFA726);
    return blue;
  }

  String _dateLabel(dynamic raw) {
    final dt = DateTime.tryParse((raw ?? '').toString())?.toLocal();
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.${dt.year} $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Gönderilerim', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: data.watchShipments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Gönderiler alınamadı: ${snapshot.error}', textAlign: TextAlign.center)));
          }
          final all = snapshot.data ?? const <Map<String, dynamic>>[];
          final active = all.where((s) => !_isPast(s)).toList();
          final past = all.where(_isPast).toList();
          final list = tab == 0 ? active : past;

          return Column(children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFF0F5FA), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Expanded(child: _tabButton('Aktif', 0, active.length)),
                  Expanded(child: _tabButton('Geçmiş', 1, past.length)),
                ]),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(tab == 0 ? Icons.local_shipping_outlined : Icons.history_rounded, size: 54, color: const Color(0xFFB9C4D3)),
                      const SizedBox(height: 10),
                      Text(tab == 0 ? 'Aktif gönderin yok' : 'Geçmiş gönderin yok', style: const TextStyle(color: muted, fontWeight: FontWeight.w800)),
                    ]))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
                      children: [
                        if (tab == 0) _summaryCard(active.length),
                        if (tab == 0) const SizedBox(height: 12),
                        ...list.map(_shipmentCard),
                      ],
                    ),
            ),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateShipmentPage())),
        backgroundColor: blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Gönderi', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _tabButton(String label, int index, int count) {
    final selected = tab == index;
    return InkWell(
      onTap: () => setState(() => tab = index),
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: selected ? const [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 3))] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: TextStyle(color: selected ? navy : muted, fontWeight: FontWeight.w800)),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: selected ? const Color(0xFFEAF4FF) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(fontSize: 11, color: selected ? blue : muted, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }

  Widget _summaryCard(int count) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF168CF5), Color(0xFF49B4FF)]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x24168CF5), blurRadius: 16, offset: Offset(0, 7))],
        ),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Color(0x33FFFFFF), child: Icon(Icons.local_shipping_rounded, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$count aktif gönderin var', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 3),
            const Text('Canlı durumlarını buradan takip edebilirsin.', style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 11)),
          ])),
        ]),
      );

  Widget _shipmentCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString();
    final color = _statusColor(status);
    final route = '${item['pickup_address'] ?? ''} → ${item['dropoff_address'] ?? ''}';
    final type = '${item['package_type'] ?? 'Paket'}${item['weight_label'] == null ? '' : ' • ${item['weight_label']}'}';
    final price = item['estimated_price'] == null ? '—' : '₺${item['estimated_price']}';
    final code = (item['public_code'] ?? '').toString();
    return InkWell(
      onTap: () => _showShipment(item),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, 5))]),
        child: Column(children: [
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(status == 'delivered' ? Icons.check_circle_rounded : Icons.local_shipping_rounded, color: color, size: 25)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(route, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: navy, fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text('$code • $type', style: const TextStyle(color: muted, fontSize: 10.5)),
            ])),
            Text(price, style: const TextStyle(color: blue, fontSize: 16, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(11)),
              child: Row(children: [Icon(Icons.circle, size: 7, color: color), const SizedBox(width: 5), Text(_statusLabel(status), style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800))]),
            ),
            const Spacer(),
            Text(_dateLabel(item['created_at']), style: const TextStyle(color: muted, fontSize: 10.5)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: muted, size: 19),
          ]),
        ]),
      ),
    );
  }

  void _showShipment(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${item['public_code'] ?? ''} • ${_statusLabel(status)}', style: const TextStyle(fontSize: 20, color: navy, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text('${item['pickup_address'] ?? ''}\n→ ${item['dropoff_address'] ?? ''}', style: const TextStyle(fontSize: 15, color: navy, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('${item['package_type'] ?? 'Paket'} • ${item['weight_label'] ?? 'Ağırlık belirtilmedi'} • ${item['payment_type'] == 'online' ? 'Online' : 'Nakit'} • ${item['estimated_price'] == null ? '—' : '₺${item['estimated_price']}'}', style: const TextStyle(color: muted)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))),
        ]),
      ),
    );
  }
}
