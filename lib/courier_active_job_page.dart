import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/app_data_service.dart';

class CourierActiveJobPage extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String pickupKm;
  final String totalKm;
  final String duration;
  final int earning;

  const CourierActiveJobPage({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.pickupKm,
    required this.totalKm,
    required this.duration,
    required this.earning,
  });

  @override
  State<CourierActiveJobPage> createState() => _CourierActiveJobPageState();
}

class _CourierActiveJobPageState extends State<CourierActiveJobPage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF1B1255);
  static const purple = Color(0xFF2D1775);
  static const muted = Color(0xFF7D7A91);
  static const bg = Color(0xFFF7F7FA);
  static const green = Color(0xFF12A861);
  static const softPurple = Color(0xFFF0EDFF);

  String? shipmentId;
  bool loading = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _loadActiveShipment();
  }

  Future<void> _loadActiveShipment() async {
    try {
      final row = await AppDataService.instance.client
          .from('couriers')
          .select('active_shipment_id')
          .eq('user_id', AppDataService.instance.userId)
          .single();
      if (!mounted) return;
      setState(() {
        shipmentId = row['active_shipment_id']?.toString();
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

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
        _ => 'Devam Et',
      };

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
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arama başlatılamadı.')),
      );
    }
  }

  Future<bool> _confirm(String title, String action) async {
    return await showDialog<bool>(
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
  }

  Future<void> _change(String status) async {
    final id = shipmentId;
    if (id == null) return;
    setState(() => busy = true);
    try {
      await AppDataService.instance.updateShipmentStatus(id, status);
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
    if (busy || status == 'delivered') return;
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
            actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Tamam'))],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(backgroundColor: bg, body: Center(child: CircularProgressIndicator(color: orange)));
    }
    final id = shipmentId;
    if (id == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(title: const Text('Aktif İş')),
        body: const Center(child: Text('Aktif gönderi bulunamadı.')),
      );
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: AppDataService.instance.watchShipment(id),
      builder: (context, snapshot) {
        final row = snapshot.data ?? const <String, dynamic>{};
        final status = (row['status'] ?? 'accepted').toString();
        final step = _step(status);
        final pickup = (row['pickup_address'] ?? widget.pickup).toString();
        final dropoff = (row['dropoff_address'] ?? widget.dropoff).toString();
        final code = (row['public_code'] ?? 'Aktif İş').toString();
        final earningRaw = row['courier_earning'] ?? row['estimated_price'];
        final earning = earningRaw is num ? earningRaw.round() : widget.earning;
        final phone = (row['customer_phone'] ?? row['receiver_phone'])?.toString();

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
                      _header(context, code),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        child: Column(
                          children: [
                            _progress(step),
                            const SizedBox(height: 18),
                            _addressCard(
                              'Alım Noktası',
                              pickup,
                              orange,
                              status == 'accepted' || status == 'at_pickup',
                            ),
                            const SizedBox(height: 10),
                            _addressCard(
                              'Teslimat Adresi',
                              dropoff,
                              const Color(0xFF4025C7),
                              status == 'picked_up' || status == 'at_dropoff',
                            ),
                            const SizedBox(height: 12),
                            _distanceCard(),
                            const SizedBox(height: 10),
                            _earningCard(earning),
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

  Widget _header(BuildContext context, String code) {
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
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 26),
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
                  const Positioned.fill(
                    child: CustomPaint(painter: _OrangeWavePainter()),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -12,
                    width: 142,
                    height: 142,
                    child: Image.asset(
                      'assets/images/Koli.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 0,
                    child: _ActiveBadge(),
                  ),
                  const Positioned(
                    left: 0,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(text: 'İşin ', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'Aktif!', style: TextStyle(color: orange)),
                          ]),
                          style: TextStyle(fontSize: 26, height: 1, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Her adım müşterinin ekranına\nanında yansır.',
                          style: TextStyle(color: Color(0xFFD8D2E9), fontSize: 12, height: 1.35, fontWeight: FontWeight.w500),
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
                  overflow: TextOverflow.visible,
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: navy, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 11.5, height: 1.3, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openNavigation(address),
            icon: Icon(Icons.navigation_rounded, color: color, size: 27),
          ),
        ],
      ),
    );
  }

  Widget _distanceCard() {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x0B19113E), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: Color(0xFF4025C7), size: 29),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mesafe', style: TextStyle(color: muted, fontSize: 11.5)),
                const SizedBox(height: 3),
                Text(widget.totalKm, style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Container(width: 1, height: 42, color: const Color(0xFFE7E6ED)),
          const SizedBox(width: 16),
          const Icon(Icons.schedule_rounded, color: orange, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tahmini Süre', style: TextStyle(color: muted, fontSize: 11.5)),
                const SizedBox(height: 3),
                Text(widget.duration, style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningCard(int earning) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x0B19113E), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_rounded, color: green, size: 29),
          const SizedBox(width: 12),
          const Expanded(child: Text('Kurye Kazancı', style: TextStyle(color: muted, fontSize: 12.5, fontWeight: FontWeight.w600))),
          Text('₺$earning', style: const TextStyle(color: green, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _bottomAction(String status, String pickup, String dropoff, String? phone) {
    return SafeArea(
      top: false,
      child: Container(
        color: bg,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: status == 'delivered' || busy ? null : () => _advance(status, pickup, dropoff),
                icon: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(status == 'at_pickup' || status == 'at_dropoff' ? Icons.check_circle_rounded : Icons.navigation_rounded),
                label: Text(_action(status)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: orange,
                  disabledBackgroundColor: const Color(0xFFCAC8D2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: softPurple,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => _call(phone),
                borderRadius: BorderRadius.circular(20),
                child: const SizedBox(width: 58, height: 56, child: Icon(Icons.phone_rounded, color: Color(0xFF4025C7), size: 25)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrangeWavePainter extends CustomPainter {
  const _OrangeWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0x33FF5A1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 58
      ..strokeCap = StrokeCap.round;

    final wave = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF8A45), Color(0xFFFF5A1F)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * .62, -18)
      ..cubicTo(
        size.width * .56,
        size.height * .20,
        size.width * .72,
        size.height * .32,
        size.width * .86,
        size.height * .44,
      )
      ..cubicTo(
        size.width * 1.02,
        size.height * .57,
        size.width * 1.03,
        size.height * .78,
        size.width * .90,
        size.height * 1.08,
      );

    canvas.drawPath(path, shadow);
    canvas.drawPath(path, wave);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 7, height: 7, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF1ED47A), shape: BoxShape.circle))),
          SizedBox(width: 6),
          Text('İşin Aktif!', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
