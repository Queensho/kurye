import 'package:flutter/material.dart';

import 'data/app_data_service.dart';
import 'data/customer_delivery_extensions.dart';

class CustomerSupportTicketsPage extends StatefulWidget {
  const CustomerSupportTicketsPage({super.key});

  @override
  State<CustomerSupportTicketsPage> createState() => _CustomerSupportTicketsPageState();
}

class _CustomerSupportTicketsPageState extends State<CustomerSupportTicketsPage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF171052);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);

  final data = AppDataService.instance;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> tickets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final rows = await data.getCustomerSupportTickets();
      if (!mounted) return;
      setState(() { tickets = rows; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString(); });
    }
  }

  String _statusLabel(String status) => switch (status) {
        'open' => 'Açık',
        'in_review' => 'İnceleniyor',
        'resolved' => 'Çözüldü',
        'closed' => 'Kapatıldı',
        _ => status,
      };

  Color _statusColor(String status) => switch (status) {
        'resolved' || 'closed' => const Color(0xFF159B68),
        'in_review' => const Color(0xFF6C5CE7),
        _ => orange,
      };

  String _categoryLabel(String category) {
    if (category.startsWith('payment_dispute:')) {
      final reason = category.split(':').last;
      return switch (reason) {
        'cancellation_fee' => 'İptal bedeli itirazı',
        'wrong_amount' => 'Yanlış ücret',
        'duplicate_charge' => 'Çift çekim',
        'undelivered_charge' => 'Teslim edilmeyen gönderi ücreti',
        'refund_missing' => 'İade ulaşmadı',
        _ => 'Ödeme itirazı',
      };
    }
    return switch (category) {
      'courier_missing' => 'Kurye gelmedi',
      'damaged_package' => 'Paket hasarlı',
      'wrong_delivery' => 'Yanlış teslimat',
      'pricing' => 'Ücret sorunu',
      _ => 'Destek talebi',
    };
  }

  String _date(dynamic raw) {
    final dt = DateTime.tryParse('${raw ?? ''}')?.toLocal();
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.${dt.year} • $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Destek Taleplerim', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const ListView(children: [SizedBox(height: 260), Center(child: CircularProgressIndicator(color: orange))])
            : error != null
                ? ListView(children: [
                    const SizedBox(height: 160),
                    const Icon(Icons.error_outline_rounded, size: 48, color: muted),
                    const SizedBox(height: 12),
                    Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('Destek kayıtları alınamadı.\n$error', textAlign: TextAlign.center, style: const TextStyle(color: muted)))),
                  ])
                : tickets.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 180),
                        Icon(Icons.support_agent_rounded, size: 56, color: Color(0xFFB9B7C8)),
                        SizedBox(height: 12),
                        Center(child: Text('Henüz destek talebin yok.', style: TextStyle(color: navy, fontWeight: FontWeight.w800))),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        itemCount: tickets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final ticket = tickets[index];
                          final status = (ticket['status'] ?? 'open').toString();
                          final color = _statusColor(status);
                          final description = (ticket['description'] ?? '').toString();
                          final shipmentId = ticket['shipment_id']?.toString();
                          final shipmentShort = shipmentId == null ? '' : shipmentId.substring(0, shipmentId.length < 8 ? shipmentId.length : 8);
                          return Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 12, offset: Offset(0, 4))],
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .10), shape: BoxShape.circle), child: Icon(Icons.support_agent_rounded, color: color)),
                                const SizedBox(width: 11),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(_categoryLabel((ticket['category'] ?? '').toString()), style: const TextStyle(color: navy, fontSize: 14, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 2),
                                  Text(_date(ticket['created_at']), style: const TextStyle(color: muted, fontSize: 10.5)),
                                ])),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)), child: Text(_statusLabel(status), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800))),
                              ]),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(description, style: const TextStyle(color: navy, height: 1.35)),
                              ],
                              if (shipmentId != null && shipmentId.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text('Gönderi: $shipmentShort', style: const TextStyle(color: muted, fontSize: 10.5)),
                              ],
                            ]),
                          );
                        },
                      ),
      ),
    );
  }
}
