import 'package:flutter/material.dart';

import 'courier_search_page.dart';
import 'create_shipment_page_v2.dart';
import 'customer_live_tracking_page.dart';
import 'data/app_data_service.dart';

class MyShipmentsPage extends StatefulWidget {
  const MyShipmentsPage({super.key});

  @override
  State<MyShipmentsPage> createState() => _MyShipmentsPageState();
}

class _MyShipmentsPageState extends State<MyShipmentsPage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF171052);
  static const purple = Color(0xFF261168);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);
  static const green = Color(0xFF159B68);

  final data = AppDataService.instance;
  int tab = 0;

  bool _isPast(Map<String, dynamic> s) {
    final status = (s['status'] ?? '').toString();
    return status == 'delivered' || status == 'cancelled';
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'searching': return 'Kurye aranıyor';
      case 'accepted': return 'Kurye yolda';
      case 'at_pickup': return 'Kurye alımda';
      case 'picked_up': return 'Gönderi yolda';
      case 'at_dropoff': return 'Teslimat noktasında';
      case 'delivered': return 'Teslim edildi';
      case 'cancelled': return 'İptal edildi';
      default: return 'Aktif';
    }
  }

  Color _statusColor(String value) {
    if (value == 'delivered') return green;
    if (value == 'cancelled') return const Color(0xFFE65252);
    return orange;
  }

  String _typeLabel(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'document': return 'Evrak';
      case 'food': return 'Market';
      case 'other': return 'Gönderi';
      default: return 'Paket';
    }
  }

  String _shortAddress(dynamic raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return 'Adres bilgisi yok';
    final parts = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return text;
    return parts.take(3).join(', ');
  }

  String _money(dynamic value) {
    if (value is num) {
      final d = value.toDouble();
      return d == d.roundToDouble() ? '₺${d.toInt()}' : '₺${d.toStringAsFixed(2)}';
    }
    return value == null ? '—' : '₺$value';
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
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = (constraints.maxWidth / 390).clamp(.92, 1.08).toDouble();
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: data.watchShipments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: orange));
                }
                if (snapshot.hasError) {
                  return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Gönderiler alınamadı: ${snapshot.error}', textAlign: TextAlign.center)));
                }

                final all = snapshot.data ?? const <Map<String, dynamic>>[];
                final active = all.where((e) => !_isPast(e)).toList();
                final past = all.where(_isPast).toList();
                final list = tab == 0 ? active : past;

                return Stack(
                  children: [
                    Column(
                      children: [
                        _header(context, s),
                        _tabs(active.length, past.length, s),
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(15 * s, 14 * s, 15 * s, 104 * s),
                            children: [
                              if (tab == 0) ...[
                                _summaryCard(active.length, s),
                                SizedBox(height: 10 * s),
                              ],
                              if (list.isEmpty)
                                _emptyState(s)
                              else
                                ...list.map((item) => Padding(
                                  padding: EdgeInsets.only(bottom: 10 * s),
                                  child: _shipmentCard(item, s),
                                )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 16 * s,
                      bottom: 18 * s,
                      child: _newShipmentButton(context, s),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, double s) => Container(
    height: 72 * s,
    padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 8 * s),
    child: Row(children: [
      InkWell(
        onTap: () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(14 * s),
        child: Container(
          width: 42 * s,
          height: 42 * s,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14 * s), boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 10)]),
          child: Icon(Icons.arrow_back_rounded, color: navy, size: 25 * s),
        ),
      ),
      SizedBox(width: 16 * s),
      Text('Gönderilerim', style: TextStyle(color: navy, fontSize: 25 * s, fontWeight: FontWeight.w900, letterSpacing: -.8)),
    ]),
  );

  Widget _tabs(int activeCount, int pastCount, double s) => Container(
    height: 58 * s,
    margin: EdgeInsets.fromLTRB(15 * s, 2 * s, 15 * s, 0),
    padding: EdgeInsets.all(3 * s),
    decoration: BoxDecoration(color: const Color(0xFFF1F1F7), borderRadius: BorderRadius.circular(18 * s)),
    child: Row(children: [
      Expanded(child: _tabButton('Aktif', 0, activeCount, s)),
      Expanded(child: _tabButton('Geçmiş', 1, pastCount, s)),
    ]),
  );

  Widget _tabButton(String label, int index, int count, double s) {
    final selected = tab == index;
    return InkWell(
      onTap: () => setState(() => tab = index),
      borderRadius: BorderRadius.circular(16 * s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52 * s,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16 * s),
          border: selected ? Border.all(color: orange, width: 1) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: TextStyle(color: selected ? orange : muted, fontSize: 12.5 * s, fontWeight: FontWeight.w800)),
          SizedBox(width: 8 * s),
          Container(
            constraints: BoxConstraints(minWidth: 27 * s),
            height: 27 * s,
            padding: EdgeInsets.symmetric(horizontal: 7 * s),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: selected ? orange : const Color(0xFFE4E3EC), borderRadius: BorderRadius.circular(14 * s)),
            child: Text('$count', style: TextStyle(color: selected ? Colors.white : muted, fontSize: 11 * s, fontWeight: FontWeight.w900)),
          ),
        ]),
      ),
    );
  }

  Widget _summaryCard(int count, double s) => Container(
    height: 90 * s,
    decoration: BoxDecoration(color: const Color(0xFF0B1234), borderRadius: BorderRadius.circular(17 * s), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 5))]),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(17 * s),
      child: Stack(children: [
        Positioned(right: -28 * s, top: -58 * s, width: 170 * s, height: 170 * s, child: Container(decoration: const BoxDecoration(color: purple, shape: BoxShape.circle))),
        Positioned(right: 14 * s, bottom: -20 * s, width: 125 * s, height: 110 * s, child: Image.asset('assets/images/3d_kurye.png', fit: BoxFit.contain, alignment: Alignment.bottomRight)),
        Positioned(left: 15 * s, top: 18 * s, child: Container(width: 48 * s, height: 48 * s, decoration: BoxDecoration(color: orange.withValues(alpha: .18), shape: BoxShape.circle), child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 25 * s))),
        Positioned(
          left: 75 * s,
          top: 21 * s,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text('$count', style: TextStyle(color: orange, fontSize: 22 * s, fontWeight: FontWeight.w900)), SizedBox(width: 5 * s), Text('aktif gönderin var', style: TextStyle(color: Colors.white, fontSize: 14 * s, fontWeight: FontWeight.w800))]),
            SizedBox(height: 4 * s),
            Text('Kuryeyi haritada canlı takip edebilirsin.', style: TextStyle(color: const Color(0xFFD8D9E4), fontSize: 9.3 * s)),
          ]),
        ),
      ]),
    ),
  );

  Widget _shipmentCard(Map<String, dynamic> item, double s) {
    final status = (item['status'] ?? '').toString();
    final color = _statusColor(status);
    final active = !_isPast(item);
    final code = (item['public_code'] ?? '').toString();
    final weight = (item['weight_label'] ?? '').toString();
    final type = _typeLabel(item['package_type']);
    final title = _shortAddress(item['pickup_address']);
    final price = _money(item['estimated_price']);

    return InkWell(
      onTap: () {
        final id = item['id']?.toString();
        if (id == null || id.isEmpty) return;

        if (status == 'searching') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourierSearchPage(shipmentId: id)));
        } else if (active) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerLiveTrackingPage(shipmentId: id)));
        } else {
          _showShipment(item);
        }
      },
      borderRadius: BorderRadius.circular(17 * s),
      child: Container(
        height: 102 * s,
        padding: EdgeInsets.fromLTRB(12 * s, 12 * s, 11 * s, 10 * s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17 * s), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 4))]),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 45 * s, height: 45 * s, decoration: BoxDecoration(color: color.withValues(alpha: .10), shape: BoxShape.circle), child: Icon(Icons.local_shipping_rounded, color: color, size: 24 * s)),
          SizedBox(width: 11 * s),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: navy, fontSize: 13.5 * s, fontWeight: FontWeight.w900))),
                SizedBox(width: 8 * s),
                Text(price, style: TextStyle(color: navy, fontSize: 17 * s, fontWeight: FontWeight.w900)),
                SizedBox(width: 3 * s),
                Icon(Icons.chevron_right_rounded, color: muted, size: 21 * s),
              ]),
              SizedBox(height: 3 * s),
              Text('${code.isEmpty ? '' : '#$code  •  '}$type${weight.isEmpty ? '' : '  •  $weight'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 10 * s, fontWeight: FontWeight.w500)),
              const Spacer(),
              Row(children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 6 * s),
                  decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(13 * s)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 7 * s, height: 7 * s, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), SizedBox(width: 6 * s), Text(_statusLabel(status), style: TextStyle(color: color, fontSize: 9.5 * s, fontWeight: FontWeight.w800))]),
                ),
                const Spacer(),
                if (active) ...[
                  Icon(status == 'searching' ? Icons.search_rounded : Icons.my_location_rounded, color: orange, size: 18 * s),
                  SizedBox(width: 5 * s),
                  Text(status == 'searching' ? 'Kurye Aranıyor' : 'Canlı Takip', style: TextStyle(color: orange, fontSize: 10 * s, fontWeight: FontWeight.w900)),
                ] else
                  Text(_dateLabel(item['created_at']), style: TextStyle(color: muted, fontSize: 9 * s)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _emptyState(double s) => Container(
    height: 130 * s,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18 * s)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(tab == 0 ? Icons.local_shipping_outlined : Icons.history_rounded, size: 40 * s, color: const Color(0xFFBCBAC8)),
      SizedBox(height: 8 * s),
      Text(tab == 0 ? 'Aktif gönderin yok' : 'Geçmiş gönderin yok', style: TextStyle(color: navy, fontSize: 12 * s, fontWeight: FontWeight.w800)),
    ]),
  );

  Widget _newShipmentButton(BuildContext context, double s) => Material(
    color: orange,
    borderRadius: BorderRadius.circular(18 * s),
    elevation: 7,
    shadowColor: orange.withValues(alpha: .28),
    child: InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateShipmentPage())),
      borderRadius: BorderRadius.circular(18 * s),
      child: Container(
        height: 50 * s,
        padding: EdgeInsets.symmetric(horizontal: 17 * s),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_rounded, color: Colors.white, size: 25 * s), SizedBox(width: 7 * s), Text('Yeni Gönderi', style: TextStyle(color: Colors.white, fontSize: 12.5 * s, fontWeight: FontWeight.w800))]),
      ),
    ),
  );

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
          Text('${_typeLabel(item['package_type'])} • ${item['weight_label'] ?? 'Ağırlık belirtilmedi'} • ${item['payment_type'] == 'online' ? 'Online' : 'Nakit'} • ${_money(item['estimated_price'])}', style: const TextStyle(color: muted)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: orange), onPressed: () => Navigator.pop(context), child: const Text('Kapat'))),
        ]),
      ),
    );
  }
}
