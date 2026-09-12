import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/app_data_service.dart';

class CourierShipmentChatPage extends StatefulWidget {
  const CourierShipmentChatPage({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<CourierShipmentChatPage> createState() => _CourierShipmentChatPageState();
}

class _CourierShipmentChatPageState extends State<CourierShipmentChatPage> {
  static const purple = Color(0xFF5426D9);
  static const purple2 = Color(0xFF6B37EA);
  static const navy = Color(0xFF171333);
  static const muted = Color(0xFF8B879A);
  static const soft = Color(0xFFF4F3F7);

  final data = AppDataService.instance;
  final controller = TextEditingController();
  final scrollController = ScrollController();
  StreamSubscription<List<Map<String, dynamic>>>? subscription;

  String? conversationId;
  Map<String, dynamic>? shipment;
  Map<String, dynamic>? customerProfile;
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
      final results = await Future.wait([
        data.client.rpc('ensure_shipment_conversation', params: {'p_shipment_id': widget.shipmentId}),
        data.client.from('shipments').select().eq('id', widget.shipmentId).single(),
      ]);
      final conversation = Map<String, dynamic>.from(results[0] as Map);
      shipment = Map<String, dynamic>.from(results[1] as Map);
      final id = conversation['id']?.toString();
      if (id == null || id.isEmpty) throw StateError('Mesajlaşma oluşturulamadı.');

      final customerId = conversation['user_id']?.toString();
      if (customerId != null && customerId.isNotEmpty) {
        try {
          final profile = await data.client
              .from('profiles')
              .select('full_name, phone, avatar_url')
              .eq('id', customerId)
              .maybeSingle();
          if (profile != null) customerProfile = Map<String, dynamic>.from(profile);
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

  Future<void> _callCustomer() async {
    final raw = (customerProfile?['phone'] ?? shipment?['recipient_phone'] ?? '').toString();
    final phone = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müşteri telefon numarası bulunamadı.')),
        );
      }
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
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
              Text(_code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: navy)),
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
          Icon(icon, color: purple, size: 19),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: Text(label, style: const TextStyle(color: muted, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: const TextStyle(color: navy, fontWeight: FontWeight.w700))),
        ],
      );

  String get _customerName {
    final name = (customerProfile?['full_name'] ?? shipment?['recipient_name'] ?? 'Müşteri').toString().trim();
    return name.isEmpty ? 'Müşteri' : name;
  }

  String get _code {
    final raw = (shipment?['public_code'] ?? 'Gönderi').toString();
    return raw.startsWith('#') ? raw : '#$raw';
  }

  String _compactAddress(dynamic raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return '—';
    final parts = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts.take(2).join(', ');
  }

  String _time(dynamic raw) {
    final dt = DateTime.tryParse('${raw ?? ''}')?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
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
            ? const Center(child: CircularProgressIndicator(color: purple))
            : error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center)))
                : Column(
                    children: [
                      _header(),
                      _shipmentCard(),
                      const SizedBox(height: 4),
                      Expanded(child: _messageList()),
                      _quickReplies(),
                      _composer(),
                    ],
                  ),
      ),
    );
  }

  Widget _header() {
    final avatar = (customerProfile?['avatar_url'] ?? '').toString();
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0EEF3))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: purple, size: 20),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEDE8FF),
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty ? const Icon(Icons.person_rounded, color: purple, size: 27) : null,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: navy, fontSize: 16.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                const Text('Müşteri • Paket sohbeti', style: TextStyle(color: muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _circleAction(Icons.phone_rounded, _callCustomer),
          const SizedBox(width: 7),
          _circleAction(Icons.more_vert_rounded, _showShipmentDetail),
        ],
      ),
    );
  }

  Widget _circleAction(IconData icon, VoidCallback onTap) => Material(
        color: const Color(0xFFEFEAFF),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, color: purple, size: 23)),
        ),
      );

  Widget _shipmentCard() {
    final s = shipment ?? const <String, dynamic>{};
    return InkWell(
      onTap: _showShipmentDetail,
      child: Container(
        margin: const EdgeInsets.fromLTRB(13, 9, 13, 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFF0EEF3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFECE8FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.inventory_2_rounded, color: purple, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_code, style: const TextStyle(color: navy, fontSize: 14, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(
                    '${_compactAddress(s['pickup_address'])} → ${_compactAddress(s['dropoff_address'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFFFFEEE6), borderRadius: BorderRadius.circular(14)),
              child: const Text('Detay', style: TextStyle(color: Color(0xFFFF5A1F), fontSize: 12, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF646075), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _messageList() {
    if (messages.isEmpty) {
      return const Center(child: Text('Henüz mesaj yok', style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w800)));
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 7),
      itemCount: messages.length,
      itemBuilder: (_, index) {
        final m = messages[index];
        final mine = m['sender_user_id']?.toString() == data.userId;
        final read = m['is_read'] == true;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .70),
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.fromLTRB(11, 8, 9, 5),
            decoration: BoxDecoration(
              gradient: mine ? const LinearGradient(colors: [purple2, purple]) : null,
              color: mine ? null : const Color(0xFFF3F2F6),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 5),
                bottomRight: Radius.circular(mine ? 5 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${m['body'] ?? ''}', style: TextStyle(color: mine ? Colors.white : navy, fontSize: 13.5, height: 1.25, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_time(m['created_at']), style: TextStyle(fontSize: 9, color: mine ? Colors.white70 : muted)),
                    if (mine) ...[
                      const SizedBox(width: 3),
                      Icon(read ? Icons.done_all_rounded : Icons.done_rounded, size: 12.5, color: Colors.white70),
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
      height: 41,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) => ActionChip(
          onPressed: sending ? null : () => _send(items[i]),
          label: Text(items[i], style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: navy)),
          backgroundColor: soft,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 5),
        ),
      ),
    );
  }

  Widget _composer() => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 9),
          color: Colors.white,
          child: Row(
            children: [
              _composerCircle(Icons.add_rounded, () {}),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(color: const Color(0xFFF6F5F9), borderRadius: BorderRadius.circular(23), border: Border.all(color: const Color(0xFFE5E2EC))),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 2,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(fontSize: 13.5, color: navy),
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(color: muted, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(15, 12, 6, 9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _composerCircle(sending ? Icons.hourglass_top_rounded : Icons.send_rounded, sending ? null : _send, filled: true),
            ],
          ),
        ),
      );

  Widget _composerCircle(IconData icon, VoidCallback? onTap, {bool filled = false}) => Material(
        color: filled ? purple : const Color(0xFFF0ECFF),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, color: filled ? Colors.white : purple, size: 24)),
        ),
      );
}
