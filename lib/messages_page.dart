import 'package:flutter/material.dart';
import 'courier_found_page_v2.dart' show CourierChatPage;

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF758198);

  final searchController = TextEditingController();
  String query = '';

  final conversations = const [
    {
      'name': 'Emre K.',
      'vehicle': 'Honda PCX • 34 KYA 728',
      'message': 'Yoldayım, 3 dakika içinde oradayım.',
      'time': '00:36',
      'shipment': '#12458',
      'route': 'Şişli → Kadıköy',
      'unread': '2',
      'online': 'true',
    },
    {
      'name': 'Mert A.',
      'vehicle': 'Yamaha NMAX • 34 MTA 214',
      'message': 'Gönderiniz teslim edildi. İyi günler.',
      'time': 'Dün',
      'shipment': '#12397',
      'route': 'Beşiktaş → Ataşehir',
      'unread': '0',
      'online': 'false',
    },
    {
      'name': 'Can B.',
      'vehicle': 'Honda PCX • 34 CBN 552',
      'message': 'Alım noktasına ulaştım.',
      'time': 'Pzt',
      'shipment': '#12341',
      'route': 'Bakırköy → Üsküdar',
      'unread': '0',
      'online': 'false',
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = conversations.where((c) {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return c.values.any((v) => v.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: navy),
        ),
        title: const Text('Mesajlar', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: TextField(
              controller: searchController,
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: 'Kurye veya gönderi ara',
                prefixIcon: const Icon(Icons.search_rounded, color: blue),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() => query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: const Color(0xFFF2F7FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Mesaj bulunamadı', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 26),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _conversationCard(context, filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _conversationCard(BuildContext context, Map<String, String> item) {
    final unread = int.tryParse(item['unread'] ?? '0') ?? 0;
    final online = item['online'] == 'true';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CourierChatPage()),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: Color(0xFFEAF4FF), shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: blue, size: 31),
                ),
                if (online)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF19C983),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name']!,
                          style: const TextStyle(fontSize: 16, color: navy, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(item['time']!, style: const TextStyle(fontSize: 10, color: muted)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(item['vehicle']!, style: const TextStyle(fontSize: 10.5, color: muted)),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['message']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: unread > 0 ? navy : const Color(0xFF65748A),
                            fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
                          child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFF2F7FD), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: blue, size: 15),
                        const SizedBox(width: 5),
                        Text('${item['shipment']} • ${item['route']}', style: const TextStyle(fontSize: 9.5, color: navy, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
