import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class CourierEarningsDetailPage extends StatefulWidget {
  const CourierEarningsDetailPage({super.key});

  @override
  State<CourierEarningsDetailPage> createState() =>
      _CourierEarningsDetailPageState();
}

class _CourierEarningsDetailPageState extends State<CourierEarningsDetailPage> {
  static const purple = Color(0xFF5620D9);
  static const purple2 = Color(0xFF7C2CF2);
  static const navy = Color(0xFF171052);
  static const muted = Color(0xFF817E9B);
  static const bg = Color(0xFFF7F7FB);
  static const green = Color(0xFF20C978);
  static const orange = Color(0xFFFF7B36);

  final data = AppDataService.instance;
  int selectedTab = 0;
  Map<String, dynamic> summary = {};
  bool earningsHidden = false;
  bool onlineBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await data.getCourierEarningsSummary();
      if (!mounted) return;
      setState(() => summary = Map<String, dynamic>.from(result));
    } catch (_) {}
  }

  Future<void> _pickPeriod() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Dönem seç', style: TextStyle(fontWeight: FontWeight.w900))),
            ListTile(title: const Text('Günlük'), trailing: selectedTab == 0 ? const Icon(Icons.check_rounded, color: purple) : null, onTap: () => Navigator.pop(context, 0)),
            ListTile(title: const Text('Haftalık'), trailing: selectedTab == 1 ? const Icon(Icons.check_rounded, color: purple) : null, onTap: () => Navigator.pop(context, 1)),
            ListTile(title: const Text('Aylık'), trailing: selectedTab == 2 ? const Icon(Icons.check_rounded, color: purple) : null, onTap: () => Navigator.pop(context, 2)),
          ],
        ),
      ),
    );
    if (result != null && mounted) setState(() => selectedTab = result);
  }

  Future<void> _goOnline() async {
    if (onlineBusy) return;
    setState(() => onlineBusy = true);
    try {
      await data.setCourierOnline(online: true, vehicleType: 'motorcycle');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Online oldun.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Online olunamadı: $e')));
    } finally {
      if (mounted) setState(() => onlineBusy = false);
    }
  }

  void _showEarningTips() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daha fazla kazan', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              SizedBox(height: 12),
              Text('Yoğun saatlerde online kal, yakın işleri hızlı kabul et ve teslimatları zamanında tamamla.'),
            ],
          ),
        ),
      ),
    );
  }

  double n(String key) => (summary[key] as num?)?.toDouble() ?? 0;

  DateTime? _date(dynamic raw) =>
      DateTime.tryParse((raw ?? '').toString())?.toLocal();

  String money(num value) {
    final v = value.toDouble();
    final whole = v == v.roundToDouble();
    return '₺${whole ? v.toInt() : v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  bool _inSelectedPeriod(Map<String, dynamic> row) {
    final d = _date(row['created_at']);
    if (d == null) return false;
    final now = DateTime.now();
    if (selectedTab == 0) {
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }
    if (selectedTab == 1) {
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 7));
      return !d.isBefore(start) && d.isBefore(end);
    }
    return d.year == now.year && d.month == now.month;
  }

  double _total(List<Map<String, dynamic>> rows) => rows.fold<double>(
        0,
        (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, c) {
            final s = (c.maxWidth / 390).clamp(.90, 1.12).toDouble();
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: data.watchCourierEarnings(),
              builder: (context, snap) {
                final all = snap.data ?? const <Map<String, dynamic>>[];
                final rows = all.where(_inSelectedPeriod).toList();
                final total = _total(rows);
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _header(s),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              12 * s,
                              14 * s,
                              12 * s,
                              18 * s,
                            ),
                            child: Column(
                              children: [
                                _tabs(s),
                                SizedBox(height: 16 * s),
                                _summaryCard(s, rows, total),
                                SizedBox(height: 21 * s),
                                _hourlySection(s, rows),
                                SizedBox(height: 22 * s),
                                _distribution(s, total),
                                SizedBox(height: 16 * s),
                                _moreCard(s),
                                SizedBox(height: 18 * s),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _onlineButton(s),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _header(double s) => Container(
        height: 84 * s,
        padding: EdgeInsets.symmetric(horizontal: 14 * s),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF32137D), Color(0xFF4B1DA2)],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 24 * s),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Kazanç Detayı',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20 * s,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * s,
                vertical: 9 * s,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(22 * s),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      color: Colors.white, size: 17 * s),
                  SizedBox(width: 6 * s),
                  Text(
                    selectedTab == 0
                        ? 'Bugün'
                        : selectedTab == 1
                            ? 'Bu Hafta'
                            : 'Bu Ay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13 * s,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _tabs(double s) => Container(
        height: 50 * s,
        padding: EdgeInsets.all(3 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(27 * s),
          border: Border.all(color: const Color(0xFFE9E7EF)),
        ),
        child: Row(
          children: [
            _tab('Günlük', 0, s),
            _tab('Haftalık', 1, s),
            _tab('Aylık', 2, s),
          ],
        ),
      );

  Widget _tab(String text, int index, double s) {
    final active = selectedTab == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(23 * s),
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [purple2, purple])
                : null,
            borderRadius: BorderRadius.circular(23 * s),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : muted,
              fontSize: 14 * s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child, double s) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19 * s),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: child,
      );

  Widget _summaryCard(
      double s, List<Map<String, dynamic>> rows, double total) {
    final deliveryCount = rows.isNotEmpty
        ? rows.length
        : (selectedTab == 0 ? n('delivery_count').toInt() : 0);
    final activeHours = selectedTab == 0 ? n('active_hours') : 0;
    final perDelivery = deliveryCount == 0 ? 0.0 : total / deliveryCount;

    return _card(
      Padding(
        padding: EdgeInsets.fromLTRB(20 * s, 18 * s, 20 * s, 16 * s),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            selectedTab == 0
                                ? 'Bugünkü Kazancın'
                                : selectedTab == 1
                                    ? 'Haftalık Kazancın'
                                    : 'Aylık Kazancın',
                            style: TextStyle(
                              color: muted,
                              fontSize: 15 * s,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 7 * s),
                          InkWell(onTap: () => setState(() => earningsHidden = !earningsHidden), child: Icon(earningsHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: muted, size: 17 * s)),
                        ],
                      ),
                      SizedBox(height: 7 * s),
                      Text(
                        earningsHidden ? '••••' : money(total),
                        style: TextStyle(
                          color: navy,
                          fontSize: 34 * s,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 11 * s,
                        vertical: 7 * s,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1FAED),
                        borderRadius: BorderRadius.circular(20 * s),
                      ),
                      child: Text(
                        '↑ %18',
                        style: TextStyle(
                          color: green,
                          fontSize: 12.5 * s,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(height: 5 * s),
                    Text(
                      'Düne göre',
                      style: TextStyle(color: muted, fontSize: 10 * s),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 18 * s),
            Divider(height: 1, color: const Color(0xFFEDEBF1)),
            SizedBox(height: 14 * s),
            Row(
              children: [
                Expanded(
                  child: _miniStat(Icons.inventory_2_rounded, purple,
                      'Teslimat', '$deliveryCount', s),
                ),
                _divider(s),
                Expanded(
                  child: _miniStat(
                    Icons.schedule_rounded,
                    purple,
                    'Aktif Süre',
                    '${activeHours.toInt()}s ${(activeHours * 60 % 60).toInt()}dk',
                    s,
                  ),
                ),
                _divider(s),
                Expanded(
                  child: _miniStat(Icons.monetization_on_rounded, orange,
                      'Paket Başına', money(perDelivery), s),
                ),
              ],
            ),
          ],
        ),
      ),
      s,
    );
  }

  Widget _divider(double s) => Container(
        width: 1,
        height: 48 * s,
        color: const Color(0xFFEDEBF1),
      );

  Widget _miniStat(
    IconData icon,
    Color color,
    String label,
    String value,
    double s,
  ) => Column(
        children: [
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: muted,
              fontSize: 10.5 * s,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6 * s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 27 * s,
                height: 27 * s,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16 * s),
              ),
              SizedBox(width: 5 * s),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: navy,
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _hourlySection(double s, List<Map<String, dynamic>> rows) {
    final labels = selectedTab == 0
        ? ['08', '10', '12', '14', '16', '18', '20', '22']
        : selectedTab == 1
            ? ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
            : ['1', '5', '10', '15', '20', '25', '30'];

    final values = List<double>.filled(labels.length, 0);
    if (selectedTab == 0) {
      for (final row in rows) {
        final d = _date(row['created_at']);
        if (d == null) continue;
        final idx = ((d.hour - 8) / 2).floor();
        if (idx >= 0 && idx < values.length) {
          values[idx] += (row['amount'] as num?)?.toDouble() ?? 0;
        }
      }
    } else if (selectedTab == 1) {
      for (final row in rows) {
        final d = _date(row['created_at']);
        if (d == null) continue;
        final idx = d.weekday - 1;
        if (idx >= 0 && idx < values.length) {
          values[idx] += (row['amount'] as num?)?.toDouble() ?? 0;
        }
      }
    } else {
      for (final row in rows) {
        final d = _date(row['created_at']);
        if (d == null) continue;
        final idx = ((d.day - 1) / 5).floor().clamp(0, values.length - 1);
        values[idx] += (row['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    var maxValue = values.fold<double>(0, math.max);
    if (maxValue <= 0) maxValue = 1;
    var selected = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[selected]) selected = i;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                selectedTab == 0 ? 'Saatlik Kazanç' : 'Kazanç Grafiği',
                style: TextStyle(
                  color: navy,
                  fontSize: 16 * s,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(22 * s),
              onTap: _pickPeriod,
              child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 13 * s,
                vertical: 8 * s,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22 * s),
                border: Border.all(color: const Color(0xFFE8E6EE)),
              ),
              child: Row(
                children: [
                  Text(
                    selectedTab == 0
                        ? 'Bugün'
                        : selectedTab == 1
                            ? 'Bu Hafta'
                            : 'Bu Ay',
                    style: TextStyle(
                      color: purple,
                      fontSize: 11 * s,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 3 * s),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: purple, size: 17 * s),
                ],
              ),
            ),
            ),
          ],
        ),
        SizedBox(height: 12 * s),
        SizedBox(
          height: 150 * s,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (i == selected && values[i] > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * s,
                            vertical: 4 * s,
                          ),
                          decoration: BoxDecoration(
                            color: navy,
                            borderRadius: BorderRadius.circular(10 * s),
                          ),
                          child: Text(
                            money(values[i]),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5 * s,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      SizedBox(height: 3 * s),
                      Container(
                        width: 22 * s,
                        height: math.max(20 * s, 92 * s * (values[i] / maxValue)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: i == selected
                                ? const [purple, purple2]
                                : const [
                                    Color(0xFFAE8CF2),
                                    Color(0xFFD6C6F8),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(4 * s),
                        ),
                      ),
                      SizedBox(height: 7 * s),
                      Text(
                        labels[i],
                        style: TextStyle(
                          color: i == selected ? purple : muted,
                          fontSize: 9.5 * s,
                          fontWeight:
                              i == selected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _distribution(double s, double total) => _card(
        Padding(
          padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 18 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kazanç Dağılımı',
                style: TextStyle(
                  color: navy,
                  fontSize: 16 * s,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 16 * s),
              Row(
                children: [
                  SizedBox(
                    width: 135 * s,
                    height: 135 * s,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size.square(135 * s),
                          painter: _RingPainter(),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              earningsHidden ? '••••' : money(total),
                              style: TextStyle(
                                color: navy,
                                fontSize: 19 * s,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Toplam',
                              style: TextStyle(color: muted, fontSize: 11 * s),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20 * s),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * s,
                        vertical: 13 * s,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F6FD),
                        borderRadius: BorderRadius.circular(14 * s),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toplam Kazanç',
                            style: TextStyle(
                              color: muted,
                              fontSize: 11 * s,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4 * s),
                          Text(
                            earningsHidden ? '••••' : money(total),
                            style: TextStyle(
                              color: navy,
                              fontSize: 18 * s,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        s,
      );

  Widget _moreCard(double s) => InkWell(
        borderRadius: BorderRadius.circular(18 * s),
        onTap: _showEarningTips,
        child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15 * s, vertical: 13 * s),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF2EA), Color(0xFFFFEEF0)],
          ),
          borderRadius: BorderRadius.circular(18 * s),
        ),
        child: Row(
          children: [
            Container(
              width: 45 * s,
              height: 45 * s,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE3C4),
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Icon(Icons.workspace_premium_rounded,
                  color: Colors.orange, size: 26 * s),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daha fazla kazan',
                    style: TextStyle(
                      color: const Color(0xFF5D1552),
                      fontSize: 14 * s,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Yoğun saatlerde online kalarak\nkazancını artırabilirsin.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11 * s,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: const Color(0xFF8A245E), size: 25 * s),
          ],
        ),
      ),
      );

  Widget _onlineButton(double s) => Container(
        color: bg,
        padding: EdgeInsets.fromLTRB(12 * s, 8 * s, 12 * s, 12 * s),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58 * s,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onlineBusy ? null : _goOnline,
              style: FilledButton.styleFrom(backgroundColor: purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28 * s))),
              icon: onlineBusy ? SizedBox(width: 18 * s, height: 18 * s, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.bolt_rounded, size: 28 * s),
              label: Text(onlineBusy ? 'Online yapılıyor...' : 'Online Ol, Siparişleri Kaçırma', style: TextStyle(fontSize: 16 * s, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      );

}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 13;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt
      ..shader = const LinearGradient(
        colors: [Color(0xFF5620D9), Color(0xFF7C2CF2)],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
