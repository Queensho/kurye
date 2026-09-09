import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF758198);

  final data = AppDataService.instance;
  final searchController = TextEditingController();
  String query = '';
  late Future<List<Map<String, dynamic>>> futureConversations;

  @override
  void initState() {
    super.initState();
    futureConversations = data.getConversations();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => futureConversations = data.getConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded, color: navy)),
        title: const Text('Mesajlar', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded, color: blue))],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: TextField(
            controller: searchController,
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              hintText: 'Kurye veya gönderi ara',
              prefixIcon: const Icon(Icons.search_rounded, color: blue),
              suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { searchController.clear(); setState(() => query = ''); }, icon: const Icon(Icons.close_rounded)),
              filled: true,
              fillColor: const Color(0xFFF2F7FD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: futureConversations,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Mesajlar alınamadı: ${snapshot.error}', textAlign: TextAlign.center)));
              final q = query.trim().toLowerCase();
              final all = snapshot.data ?? const <Map<String, dynamic>>[];
              final filtered = all.where((c) {
                if (q.isEmpty) return true;
                final shipment = c['shipments'] is Map ? Map<String, dynamic>.from(c['shipments']) : <String, dynamic>{};
                return [c['courier_name'], c['courier_vehicle'], shipment['public_code'], shipment['pickup_address'], shipment['dropoff_address']]
                    .whereType<Object>()
                    .any((v) => v.toString().toLowerCase().contains(q));
              }).toList();
              if (filtered.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 52, color: Color(0xFFB9C4D3)),
                  SizedBox(height: 10),
                  Text('Henüz mesaj yok', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text('Bir kurye ile eşleştiğinde konuşman burada görünecek.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: muted)),
                ])));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 26),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _conversationCard(filtered[index]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _conversationCard(Map<String, dynamic> item) {
    final shipment = item['shipments'] is Map ? Map<String, dynamic>.from(item['shipments']) : <String, dynamic>{};
    final name = (item['courier_name'] ?? 'Kurye').toString();
    final vehicle = (item['courier_vehicle'] ?? '').toString();
    final route = '${shipment['pickup_address'] ?? ''} → ${shipment['dropoff_address'] ?? ''}';
    final shipmentCode = (shipment['public_code'] ?? '').toString();
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConversationPage(
          conversationId: item['id'].toString(),
          courierName: name,
          courierVehicle: vehicle,
        )));
        _refresh();
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 5))]),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 56, height: 56, decoration: const BoxDecoration(color: Color(0xFFEAF4FF), shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: blue, size: 31)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 16, color: navy, fontWeight: FontWeight.w900)),
            if (vehicle.isNotEmpty) ...[const SizedBox(height: 2), Text(vehicle, style: const TextStyle(fontSize: 10.5, color: muted))],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF2F7FD), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.inventory_2_outlined, color: blue, size: 15),
                const SizedBox(width: 5),
                Flexible(child: Text('$shipmentCode • $route', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: navy, fontWeight: FontWeight.w700))),
              ]),
            ),
          ])),
          const Icon(Icons.chevron_right_rounded, color: muted),
        ]),
      ),
    );
  }
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key, required this.conversationId, required this.courierName, required this.courierVehicle});

  final String conversationId;
  final String courierName;
  final String courierVehicle;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  static const blue = Color(0xFF168CF5);
  final data = AppDataService.instance;
  final controller = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await data.sendMessage(widget.conversationId, text);
      controller.clear();
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.courierName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          if (widget.courierVehicle.isNotEmpty) Text(widget.courierVehicle, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: data.watchMessages(widget.conversationId),
            builder: (context, snapshot) {
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final messages = snapshot.data ?? const <Map<String, dynamic>>[];
              if (messages.isEmpty) return const Center(child: Text('Henüz mesaj yok.'));
              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final mine = m['sender_role'] == 'customer';
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 290),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                      decoration: BoxDecoration(color: mine ? blue : Colors.white, borderRadius: BorderRadius.circular(17)),
                      child: Text((m['body'] ?? '').toString(), style: TextStyle(color: mine ? Colors.white : const Color(0xFF10182D))),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(children: [
              Expanded(child: TextField(controller: controller, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(), decoration: InputDecoration(hintText: 'Mesaj yaz...', filled: true, fillColor: const Color(0xFFF2F7FD), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: sending ? null : _send, icon: const Icon(Icons.send_rounded)),
            ]),
          ),
        ),
      ]),
    );
  }
}
