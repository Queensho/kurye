import 'dart:async';

import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class ShipmentChatPage extends StatefulWidget {
  const ShipmentChatPage({super.key, required this.shipmentId, this.title});

  final String shipmentId;
  final String? title;

  @override
  State<ShipmentChatPage> createState() => _ShipmentChatPageState();
}

class _ShipmentChatPageState extends State<ShipmentChatPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF758198);

  final data = AppDataService.instance;
  final controller = TextEditingController();
  final scrollController = ScrollController();
  StreamSubscription<List<Map<String, dynamic>>>? subscription;

  String? conversationId;
  String? peerName;
  String? myRole;
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final raw = await data.client.rpc(
        'ensure_shipment_conversation',
        params: {'p_shipment_id': widget.shipmentId},
      );
      final conversation = Map<String, dynamic>.from(raw as Map);
      final id = conversation['id']?.toString();
      if (id == null || id.isEmpty) throw StateError('Mesajlaşma oluşturulamadı.');
      myRole = conversation['user_id']?.toString() == data.userId ? 'customer' : 'courier';
      peerName = myRole == 'customer' ? (conversation['courier_name']?.toString() ?? 'Kurye') : 'Müşteri';
      if (!mounted) return;
      setState(() {
        conversationId = id;
        loading = false;
      });
      subscription = data.client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', id)
          .order('created_at')
          .listen((rows) {
        if (!mounted) return;
        setState(() => messages = List<Map<String, dynamic>>.from(rows));
        _markRead();
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      });
      await _markRead();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<void> _markRead() async {
    final id = conversationId;
    if (id == null) return;
    try {
      await data.client.rpc('mark_conversation_read', params: {'p_conversation_id': id});
    } catch (_) {}
  }

  Future<void> _send() async {
    final id = conversationId;
    final text = controller.text.trim();
    if (id == null || text.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await data.client.rpc('send_chat_message', params: {
        'p_conversation_id': id,
        'p_body': text,
      });
      controller.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: ${e.toString().replaceFirst('Bad state: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  String _time(dynamic raw) {
    final dt = DateTime.tryParse('${raw ?? ''}')?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    subscription?.cancel();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title ?? peerName ?? 'Mesajlaşma', style: const TextStyle(fontWeight: FontWeight.w900, color: navy)),
            if (!loading) const Text('Canlı mesajlaşma', style: TextStyle(fontSize: 10, color: muted)),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center)))
              : Column(
                  children: [
                    Expanded(
                      child: messages.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 52, color: Color(0xFFB9C4D3)),
                                  SizedBox(height: 10),
                                  Text('Henüz mesaj yok', style: TextStyle(fontWeight: FontWeight.w800, color: muted)),
                                  SizedBox(height: 4),
                                  Text('İlk mesajı göndererek konuşmayı başlat.', style: TextStyle(fontSize: 12, color: muted)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                              itemCount: messages.length,
                              itemBuilder: (_, index) {
                                final m = messages[index];
                                final mine = m['sender_user_id']?.toString() == data.userId;
                                final read = m['is_read'] == true;
                                return Align(
                                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 300),
                                    margin: const EdgeInsets.only(bottom: 9),
                                    padding: const EdgeInsets.fromLTRB(13, 10, 10, 7),
                                    decoration: BoxDecoration(
                                      color: mine ? blue : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(mine ? 18 : 5),
                                        bottomRight: Radius.circular(mine ? 5 : 18),
                                      ),
                                      boxShadow: mine ? null : const [BoxShadow(color: Color(0x0D000000), blurRadius: 10)],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('${m['body'] ?? ''}', style: TextStyle(color: mine ? Colors.white : navy, fontSize: 15)),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(_time(m['created_at']), style: TextStyle(fontSize: 9, color: mine ? Colors.white70 : muted)),
                                            if (mine) ...[
                                              const SizedBox(width: 4),
                                              Icon(read ? Icons.done_all_rounded : Icons.done_rounded, size: 14, color: read ? Colors.white : Colors.white70),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                                decoration: InputDecoration(
                                  hintText: 'Mesaj yaz...',
                                  filled: true,
                                  fillColor: const Color(0xFFF2F7FD),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: sending ? null : _send,
                              style: IconButton.styleFrom(backgroundColor: blue, foregroundColor: Colors.white),
                              icon: sending
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
