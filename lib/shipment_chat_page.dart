import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/app_data_service.dart';

class ShipmentChatPage extends StatefulWidget {
  const ShipmentChatPage({super.key, required this.shipmentId, this.title});

  final String shipmentId;
  final String? title;

  @override
  State<ShipmentChatPage> createState() => _ShipmentChatPageState();
}

class _ShipmentChatPageState extends State<ShipmentChatPage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF15113F);
  static const muted = Color(0xFF8A8798);
  static const soft = Color(0xFFF5F4F8);

  final data = AppDataService.instance;
  final controller = TextEditingController();
  final scrollController = ScrollController();
  StreamSubscription<List<Map<String, dynamic>>>? subscription;

  String? conversationId;
  String? peerName;
  String? myRole;
  String? courierPhone;
  String? courierAvatar;
  Map<String, dynamic>? shipment;
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
      final conversationRaw = await data.client.rpc(
        'ensure_shipment_conversation',
        params: {'p_shipment_id': widget.shipmentId},
      );
      final shipmentRaw = await data.client
          .from('shipments')
          .select()
          .eq('id', widget.shipmentId)
          .single();
      final conversation = Map<String, dynamic>.from(conversationRaw as Map);
      shipment = Map<String, dynamic>.from(shipmentRaw);
      final id = conversation['id']?.toString();
      if (id == null || id.isEmpty) throw StateError('Mesajlaşma oluşturulamadı.');

      myRole = conversation['user_id']?.toString() == data.userId ? 'customer' : 'courier';
      peerName = myRole == 'customer'
          ? (conversation['courier_name']?.toString() ?? 'Kurye')
          : 'Müşteri';

      if (myRole == 'customer') {
        try {
          final infoRaw = await data.client.rpc(
            'get_assigned_courier_for_shipment',
            params: {'p_shipment_id': widget.shipmentId},
          );
          if (infoRaw != null) {
            final info = Map<String, dynamic>.from(infoRaw as Map);
            courierPhone = (info['phone'] ?? '').toString();
            courierAvatar = (info['avatar_url'] ?? '').toString();
            final n = (info['full_name'] ?? info['name'] ?? '').toString().trim();
            if (n.isNotEmpty) peerName = n;
          }
        } catch (_) {}
      }

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

  Future<void> _send([String? preset]) async {
    final id = conversationId;
    final text = (preset ?? controller.text).trim();
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

  Future<void> _callCourier() async {
    final phone = courierPhone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kurye telefon numarası bulunamadı.')),
        );
      }
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefon uygulaması açılamadı.')),
      );
    }
  }

  void _showShipmentDetail() {
    final s = shipment;
    if (s == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('#${s['public_code'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: navy)),
              const SizedBox(height: 14),
              _detailLine(Icons.location_on_rounded, 'Alım', (s['pickup_address'] ?? '').toString()),
              const SizedBox(height: 10),
              _detailLine(Icons.flag_rounded, 'Teslimat', (s['dropoff_address'] ?? '').toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailLine(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: orange, size: 20),
          const SizedBox(width: 9),
          SizedBox(width: 70, child: Text(label, style: const TextStyle(color: muted, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: const TextStyle(color: navy, fontWeight: FontWeight.w700))),
        ],
      );

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

  String _compactAddress(dynamic raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return '—';
    final parts = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts.take(2).join(', ');
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: orange))
            : error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center)))
                : Column(
                    children: [
                      _header(),
                      _shipmentCard(),
                      const SizedBox(height: 5),
                      Expanded(child: _messageList()),
                      _quickReplies(),
                      _composer(),
                    ],
                  ),
      ),
    );
  }

  Widget _header() {
    final title = widget.title ?? peerName ?? (myRole == 'customer' ? 'Kurye' : 'Müşteri');
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0EEF3))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: orange, size: 21),
          ),
          CircleAvatar(
            radius: 23,
            backgroundColor: const Color(0xFFFFE8DB),
            backgroundImage: courierAvatar != null && courierAvatar!.isNotEmpty ? NetworkImage(courierAvatar!) : null,
            child: courierAvatar == null || courierAvatar!.isEmpty
                ? const Icon(Icons.person_rounded, color: orange, size: 28)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(myRole == 'customer' ? '🏍️ Kurye' : 'Gönderi müşterisi', style: const TextStyle(color: muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (myRole == 'customer')
            _circleAction(Icons.phone_rounded, _callCourier),
          const SizedBox(width: 7),
          _circleAction(Icons.more_vert_rounded, _showShipmentDetail),
        ],
      ),
    );
  }

  Widget _circleAction(IconData icon, VoidCallback onTap) => Material(
        color: const Color(0xFFFFEEE6),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 46, height: 46, child: Icon(icon, color: orange, size: 24)),
        ),
      );

  Widget _shipmentCard() {
    final s = shipment ?? const <String, dynamic>{};
    final code = (s['public_code'] ?? 'Gönderi').toString();
    return InkWell(
      onTap: _showShipmentDetail,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0EEF3)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: const Color(0xFFFFE9DE), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.inventory_2_rounded, color: orange, size: 25),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code.startsWith('#') ? code : '#$code', style: const TextStyle(color: navy, fontSize: 14.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(
                    '${_compactAddress(s['pickup_address'])} → ${_compactAddress(s['dropoff_address'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: navy, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFFEEE6), borderRadius: BorderRadius.circular(15)),
              child: const Text('Detay', style: TextStyle(color: orange, fontSize: 12.5, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF646075), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _messageList() {
    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 42, color: Color(0xFFD2CFDA)),
            SizedBox(height: 8),
            Text('Henüz mesaj yok', style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
      itemCount: messages.length,
      itemBuilder: (_, index) {
        final m = messages[index];
        final mine = m['sender_user_id']?.toString() == data.userId;
        final read = m['is_read'] == true;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .72),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 9, 10, 6),
            decoration: BoxDecoration(
              color: mine ? orange : const Color(0xFFF3F2F6),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(17),
                topRight: const Radius.circular(17),
                bottomLeft: Radius.circular(mine ? 17 : 5),
                bottomRight: Radius.circular(mine ? 5 : 17),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${m['body'] ?? ''}',
                    style: TextStyle(color: mine ? Colors.white : navy, fontSize: 14, height: 1.28, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_time(m['created_at']), style: TextStyle(fontSize: 9.5, color: mine ? Colors.white70 : muted)),
                    if (mine) ...[
                      const SizedBox(width: 4),
                      Icon(read ? Icons.done_all_rounded : Icons.done_rounded, size: 13, color: Colors.white70),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickReplies() {
    const items = ['Yoldayım 🚀', 'Vardım 📍', 'Teslim aldım ✅', 'Teslim edildi ✓'];
    return SizedBox(
      height: 43,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) => InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: sending ? null : () => _send(items[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFFFFF1EA), borderRadius: BorderRadius.circular(18)),
            child: Text(items[i], style: const TextStyle(color: navy, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _composer() => SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 9),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 27),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(22)),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(fontSize: 14, color: navy),
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(color: muted, fontSize: 13.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: orange,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: sending ? null : () => _send(),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
