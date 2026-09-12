import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/app_data_service.dart';
import 'shipment_chat_page.dart';
import 'courier_shipment_chat_page.dart';
import 'courier_shipment_chat_page.dart';
import 'courier_shipment_chat_page.dart';

class CourierActiveJobRealtimePage extends StatefulWidget {
  final String shipmentId;
  final String pickup;
  final String dropoff;
  final int earning;

  const CourierActiveJobRealtimePage({
    super.key,
    required this.shipmentId,
    required this.pickup,
    required this.dropoff,
    required this.earning,
  });

  @override
  State<CourierActiveJobRealtimePage> createState() => _CourierActiveJobRealtimePageState();
}

class _CourierActiveJobRealtimePageState extends State<CourierActiveJobRealtimePage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF1B1255);
  static const purple = Color(0xFF4025C7);
  static const muted = Color(0xFF7D7A91);
  static const bg = Color(0xFFF7F7FA);
  static const green = Color(0xFF12A861);
  static const red = Color(0xFFE65252);

  bool busy = false;

  int _step(String status) => switch (status) {
        'accepted' => 0,
        'at_pickup' => 1,
        'picked_up' => 2,
        'at_dropoff' => 3,
        'delivered' => 4,
        _ => 0,
      };

  String _action(String status) => switch (status) {
        'accepted' => 'Alım Noktasına Git',
        'at_pickup' => 'Teslim Aldım',
        'picked_up' => 'Teslimat Adresine Git',
        'at_dropoff' => 'Teslim Ettim',
        'delivered' => 'Teslim Edildi',
        'cancelled' => 'Ana Sayfaya Dön',
        _ => 'Devam Et',
      };

  String _distance(dynamic raw) {
    if (raw is num) {
      final value = raw.toDouble();
      return '${value.toStringAsFixed(value >= 100 ? 2 : 1)} km';
    }
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return '—';
    return text.contains('km') ? text : '$text km';
  }

  String _duration(dynamic raw) {
    if (raw is num) return '${raw.round()} dk';
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return '—';
    return text.contains('dk') ? text : '$text dk';
  }

  Future<void> _openNavigation(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigasyon açılamadı.')),
      );
    }
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müşteri telefon numarası bulunamadı.')),
        );
      }
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone.trim()));
  }

  void _openShipmentChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourierShipmentChatPage(
          shipmentId: widget.shipmentId,
        ),
      ),
    );
  }

  Future<bool> _confirm(String title, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(title),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: orange),
              onPressed: () => Navigator.pop(d, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _change(String status) async {
    setState(() => busy = true);
    try {
      await AppDataService.instance.updateShipmentStatus(widget.shipmentId, status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _advance(String status, String pickup, String dropoff) async {
    if (busy || status == 'delivered' || status == 'cancelled') return;
    if (status == 'accepted') {
      await _openNavigation(pickup);
      if (!mounted) return;
      if (await _confirm('Alım noktasına vardın mı?', 'Vardım')) {
        await _change('at_pickup');
      }
      return;
    }
    if (status == 'at_pickup') {
      await _change('picked_up');
      return;
    }
    if (status == 'picked_up') {
      await _openNavigation(dropoff);
      if (!mounted) return;
      if (await _confirm('Teslimat noktasına vardın mı?', 'Vardım')) {
        await _change('at_dropoff');
      }
      return;
    }
    if (status == 'at_dropoff') {
      if (await _confirm('Gönderiyi müşteriye teslim ettin mi?', 'Teslim Ettim')) {
        await _change('delivered');
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (d) => AlertDialog(
            icon: const Icon(Icons.check_circle_rounded, color: green, size: 52),
            title: const Text('Teslimat tamamlandı'),
            content: Text('₺${widget.earning} kazanç olarak işlendi.', textAlign: TextAlign.center),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Tamam')),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AppDataService.instance.watchShipment(widget.shipmentId),
      builder: (context, snapshot) {
        final row = snapshot.data ?? const <String, dynamic>{};
        final status = (row['status'] ?? 'accepted').toString();
        final cancelled = status == 'cancelled';
        final step = _step(status);
        final pickup = (row['pickup_address'] ?? widget.pickup).toString();
        final dropoff = (row['dropoff_address'] ?? widget.dropoff).toString();
        final code = (row['public_code'] ?? 'Aktif İş').toString();
        final earningRaw = row['courier_earning'] ?? row['estimated_price'];
        final earning = earningRaw is num ? earningRaw.round() : widget.earning;
        final phone = (row['recipient_phone'] ?? '').toString();
        final distance = _distance(row['distance_km']);
        final duration = _duration(row['duration_min']);
        final cancelReason = (row['cancel_reason'] ?? '').toString();

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _header(code, cancelled),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        child: Column(
                          children: [
                            if (cancelled) ...[
                              _cancelledCard(cancelReason),
                              const SizedBox(height: 14),
                            ] else ...[
                              _progress(step),
                              const SizedBox(height: 18),
                            ],
                            _addressCard('Alım Noktası', pickup, orange, !cancelled && (status == 'accepted' || status == 'at_pickup')),
                            const SizedBox(height: 10),
                            _addressCard('Teslimat Adresi', dropoff, purple, !cancelled && (status == 'picked_up' || status == 'at_dropoff')),
                            const SizedBox(height: 12),
                            _distanceCard(distance, duration),
                            const SizedBox(height: 10),
                            _earningCard(earning, cancelled),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _bottomAction(status, pickup, dropoff, phone),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(String code, bool cancelled) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF21105F), Color(0xFF11073C)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          children: [
            Row(
              children: [
                _squareButton(Icons.arrow_back_rounded, () => Navigator.maybePop(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    code.startsWith('#') ? code : '#$code',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Mesaj',
                  onPressed: cancelled ? null : _openShipmentChat,
                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 148,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF39217E), Color(0xFF201052)],
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  const Positioned.fill(child: CustomPaint(painter: _OrangeWavePainter())),
                  Positioned(
                    right: 2,
                    bottom: 4,
                    width: 136,
                    height: 136,
                    child: Image.asset(
                      'assets/images/Koli.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Positioned(left: 0, top: 0, child: _ActiveBadge(cancelled: cancelled)),
                  Positioned(
                    left: 0,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: cancelled ? 'İş ' : 'İşin ', style: const TextStyle(color: Colors.white)),
                              TextSpan(text: cancelled ? 'İptal!' : 'Aktif!', style: TextStyle(color: cancelled ? red : orange)),
                            ],
                          ),
                          style: const TextStyle(fontSize: 26, height: 1, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cancelled ? 'Gönderi artık aktif değil.' : 'Her adım müşterinin ekranına\nanında yansır.',
                          style: const TextStyle(color: Color(0xFFD8D2E9), fontSize: 12, height: 1.35, fontWeight: FontWeight.w500),
                        ),
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

  Widget _squareButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 46, height: 46, child: Icon(icon, color: Colors.white, size: 27)),
      ),
    );
  }

  Widget _progress(int step) {
    const labels = ['İşi Aldı', 'Alımda', 'Teslim Aldı', 'Teslimatta', 'Teslim Edildi'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: i <= step ? orange : const Color(0xFFE9EBF3),
                    shape: BoxShape.circle,
                    boxShadow: i == step ? const [BoxShadow(color: Color(0x33FF5A1F), blurRadius: 12)] : null,
                  ),
                  child: i <= step ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                ),
                const SizedBox(height: 7),
                Text(
                  labels[i],
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8.7,
                    color: i <= step ? orange : muted,
                    fontWeight: i <= step ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length - 1)
            Container(
              width: 17,
              height: 3,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: i < step ? orange : const Color(0xFFE0E2EA),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
        ],
      ],
    );
  }

  Widget _addressCard(String title, String address, Color color, bool active) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: active ? Border.all(color: color.withValues(alpha: .15)) : null,
        boxShadow: const [BoxShadow(color: Color(0x0B19113E), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: .11), shape: BoxShape.circle),
            child: Icon(Icons.location_on_rounded, color: color, size: 27),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: navy, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11.5, height: 1.3, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(onPressed: () => _openNavigation(address), icon: Icon(Icons.navigation_rounded, color: color, size: 28)),
        ],
      ),
    );
  }

  Widget _distanceCard(String distance, String duration) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x0919113E), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: purple, size: 31),
          const SizedBox(width: 14),
          Expanded(child: _metric('Mesafe', distance)),
          Container(width: 1, height: 52, color: const Color(0xFFE5E2EC)),
          const SizedBox(width: 18),
          const Icon(Icons.schedule_rounded, color: orange, size: 31),
          const SizedBox(width: 12),
          Expanded(child: _metric('Tahmini Süre', duration)),
        ],
      ),
    );
  }

  Widget _metric(String title, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      );

  Widget _earningCard(int earning, bool cancelled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Icon(cancelled ? Icons.info_outline_rounded : Icons.payments_rounded, color: cancelled ? red : green, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(cancelled ? 'Bu iş artık aktif değil' : 'Kurye Kazancı', style: const TextStyle(color: muted, fontSize: 14))),
          if (!cancelled) Text('₺$earning', style: const TextStyle(color: green, fontSize: 23, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _cancelledCard(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFFFEEEE), borderRadius: BorderRadius.circular(18)),
      child: Text(
        reason.isEmpty ? 'Müşteri gönderiyi iptal etti.' : 'Müşteri gönderiyi iptal etti.\nNeden: $reason',
        style: const TextStyle(color: red, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _bottomAction(String status, String pickup, String dropoff, String? phone) {
    final cancelled = status == 'cancelled';
    final finished = status == 'delivered';
    final target = status == 'accepted' || status == 'at_pickup' ? pickup : dropoff;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 20, offset: Offset(0, -4))]),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: cancelled
                    ? () => Navigator.maybePop(context)
                    : finished || busy
                        ? null
                        : () => _advance(status, pickup, dropoff),
                icon: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(status == 'at_pickup' || status == 'at_dropoff' ? Icons.check_circle_rounded : Icons.navigation_rounded),
                label: Text(_action(status)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: cancelled ? red : orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            if (!cancelled && !finished) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 58,
                height: 58,
                child: FilledButton(
                  onPressed: () => _call(phone),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: const Color(0xFFF0EDFF),
                    foregroundColor: purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Icon(Icons.call_rounded, size: 25),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final bool cancelled;
  const _ActiveBadge({required this.cancelled});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: cancelled ? _CourierActiveJobRealtimePageState.red : const Color(0xFF19CE78), shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text(cancelled ? 'İptal Edildi' : 'İşin Aktif!', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _OrangeWavePainter extends CustomPainter {
  const _OrangeWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFF5A1F);
    final path = Path()
      ..moveTo(size.width * .72, -8)
      ..cubicTo(size.width * .62, size.height * .23, size.width * .99, size.height * .27, size.width * .83, size.height * .48)
      ..cubicTo(size.width * .72, size.height * .64, size.width * 1.05, size.height * .78, size.width * .88, size.height * 1.04)
      ..lineTo(size.width * 1.08, size.height * 1.08)
      ..lineTo(size.width * 1.08, -8)
      ..close();
    canvas.drawPath(path, paint);

    final soft = Paint()..color = const Color(0x44FF5A1F);
    final softPath = Path()
      ..moveTo(size.width * .68, -10)
      ..cubicTo(size.width * .53, size.height * .28, size.width * .93, size.height * .36, size.width * .74, size.height * .58)
      ..cubicTo(size.width * .62, size.height * .73, size.width * .98, size.height * .87, size.width * .80, size.height * 1.08);
    canvas.drawPath(softPath, soft..style = PaintingStyle.stroke..strokeWidth = 20);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
