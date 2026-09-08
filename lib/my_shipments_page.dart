import 'package:flutter/material.dart';

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

  int tab = 0;

  final activeShipments = const [
    _Shipment(
      id: '#12504',
      route: 'Şişli → Kadıköy',
      date: 'Bugün 00:38',
      status: 'Teslimatta',
      price: '₺145',
      type: 'Paket • 0–5 kg',
      icon: Icons.local_shipping_rounded,
      statusColor: blue,
    ),
    _Shipment(
      id: '#12503',
      route: 'Beşiktaş → Sarıyer',
      date: 'Bugün 00:12',
      status: 'Kurye alımda',
      price: '₺120',
      type: 'Belge • Küçük',
      icon: Icons.inventory_2_rounded,
      statusColor: Color(0xFFFFA726),
    ),
  ];

  final pastShipments = const [
    _Shipment(
      id: '#12458',
      route: 'Şişli → Kadıköy',
      date: 'Dün 14:32',
      status: 'Teslim edildi',
      price: '₺135',
      type: 'Paket • 0–5 kg',
      icon: Icons.check_circle_rounded,
      statusColor: green,
    ),
    _Shipment(
      id: '#12441',
      route: 'Bakırköy → Ataşehir',
      date: '7 Eyl 18:06',
      status: 'Teslim edildi',
      price: '₺210',
      type: 'Araç • Orta boy',
      icon: Icons.check_circle_rounded,
      statusColor: green,
    ),
    _Shipment(
      id: '#12397',
      route: 'Beyoğlu → Üsküdar',
      date: '5 Eyl 12:24',
      status: 'İptal edildi',
      price: '₺0',
      type: 'Belge • Küçük',
      icon: Icons.cancel_rounded,
      statusColor: Color(0xFFE65252),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final list = tab == 0 ? activeShipments : pastShipments;
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Gönderilerim', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFF0F5FA), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Expanded(child: _tabButton('Aktif', 0, activeShipments.length)),
                Expanded(child: _tabButton('Geçmiş', 1, pastShipments.length)),
              ]),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: [
                if (tab == 0) _summaryCard(),
                if (tab == 0) const SizedBox(height: 12),
                ...list.map(_shipmentCard),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
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

  Widget _summaryCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF168CF5), Color(0xFF49B4FF)]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x24168CF5), blurRadius: 16, offset: Offset(0, 7))],
        ),
        child: const Row(children: [
          CircleAvatar(backgroundColor: Color(0x33FFFFFF), child: Icon(Icons.local_shipping_rounded, color: Colors.white)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('2 aktif gönderin var', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            SizedBox(height: 3),
            Text('Canlı durumlarını buradan takip edebilirsin.', style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 11)),
          ])),
        ]),
      );

  Widget _shipmentCard(_Shipment item) => InkWell(
        onTap: () => _showShipment(item),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, 5))],
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: item.statusColor.withValues(alpha: .12), shape: BoxShape.circle),
                child: Icon(item.icon, color: item.statusColor, size: 25),
              ),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.route, style: const TextStyle(color: navy, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${item.id} • ${item.type}', style: const TextStyle(color: muted, fontSize: 10.5)),
              ])),
              Text(item.price, style: const TextStyle(color: blue, fontSize: 16, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(color: item.statusColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(11)),
                child: Row(children: [
                  Icon(Icons.circle, size: 7, color: item.statusColor),
                  const SizedBox(width: 5),
                  Text(item.status, style: TextStyle(color: item.statusColor, fontSize: 10.5, fontWeight: FontWeight.w800)),
                ]),
              ),
              const Spacer(),
              Text(item.date, style: const TextStyle(color: muted, fontSize: 10.5)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: muted, size: 19),
            ]),
          ]),
        ),
      );

  void _showShipment(_Shipment item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${item.id} • ${item.status}', style: const TextStyle(fontSize: 20, color: navy, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(item.route, style: const TextStyle(fontSize: 16, color: navy, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('${item.type} • ${item.date} • ${item.price}', style: const TextStyle(color: muted)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))),
        ]),
      ),
    );
  }
}

class _Shipment {
  const _Shipment({
    required this.id,
    required this.route,
    required this.date,
    required this.status,
    required this.price,
    required this.type,
    required this.icon,
    required this.statusColor,
  });

  final String id;
  final String route;
  final String date;
  final String status;
  final String price;
  final String type;
  final IconData icon;
  final Color statusColor;
}
