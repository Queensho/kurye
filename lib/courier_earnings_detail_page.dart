import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class CourierEarningsDetailPage extends StatefulWidget {
  const CourierEarningsDetailPage({super.key});

  @override
  State<CourierEarningsDetailPage> createState() =>
      _CourierEarningsDetailPageState();
}

class _CourierEarningsDetailPageState extends State<CourierEarningsDetailPage> {
  static const Color purple = Color(0xFF5520D7);
  static const Color purple2 = Color(0xFF7B2CF2);
  static const Color navy = Color(0xFF171052);
  static const Color muted = Color(0xFF817E9B);
  static const Color bg = Color(0xFFF7F7FB);
  static const Color green = Color(0xFF20C978);
  static const Color orange = Color(0xFFFF7B36);

  final AppDataService data = AppDataService.instance;
  Map<String, dynamic> summary = {};
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final result = await data.getCourierEarningsSummary();
      if (!mounted) return;
      setState(() => summary = Map<String, dynamic>.from(result));
    } catch (_) {}
  }

  double _number(String key) => (summary[key] as num?)?.toDouble() ?? 0;

  String _money(num value) {
    final v = value.toDouble();
    return '₺${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  DateTime? _date(dynamic raw) =>
      DateTime.tryParse((raw ?? '').toString())?.toLocal();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inSelectedPeriod(Map<String, dynamic> row) {
    final d = _date(row['created_at']);
    if (d == null) return false;
    final now = DateTime.now();

    if (selectedTab == 0) return _sameDay(d, now);

    if (selectedTab == 1) {
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 7));
      return !d.isBefore(start) && d.isBefore(end);
    }

    return d.year == now.year && d.month == now.month;
  }

  List<Map<String, dynamic>> _periodRows(List<Map<String, dynamic>> rows) =>
      rows.where(_inSelectedPeriod).toList();

  double _total(List<Map<String, dynamic>> rows) => rows.fold<double>(
        0,
        (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
      );

  String _periodLabel() {
    if (selectedTab == 0) return 'Bugün';
    if (selectedTab == 1) return 'Bu Hafta';
    return 'Bu Ay';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = (constraints.maxWidth / 390).clamp(.90, 1.10).toDouble();
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: data.watchCourierEarnings(),
              builder: (context, snapshot) {
                final allRows = snapshot.data ?? const <Map<String, dynamic>>[];
                final rows = _periodRows(allRows);
                final total = _total(rows);
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadSummary,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _header(s),
                            Transform.translate(
                              offset: Offset(0, -4 * s),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12 * s),
                                child: Column(
                                  children: [
                                    _tabs(s),
                                    SizedBox(height: 12 * s),
                                    _summaryCard(s, rows, total),
                                    SizedBox(height: 18 * s),
                                    _hourlySection(s, rows),
                                    SizedBox(height: 18 * s),
                                    _distributionCard(s, rows, total),
                                    SizedBox(height: 14 * s),
                                    _goalCard(s, total),
                                    SizedBox(height: 14 * s),
                                    _moreCard(s),
                                    SizedBox(height: 22 * s),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
        height: 108 * s,
        padding: EdgeInsets.fromLTRB(10 * s, 12 * s, 12 * s, 14 * s),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF32117E), Color(0xFF4920A7), Color(0xFF2A0C6A)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 24 * s),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Kazanç Detayı',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19 * s,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 9 * s),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(19 * s),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      color: Colors.white, size: 17 * s),
                  SizedBox(width: 6 * s),
                  Text(
                    selectedTab == 2 ? 'Bu Ay' : 'Bu Hafta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10 * s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _tabs(double s) => Container(
        height: 52 * s,
        padding: EdgeInsets.all(4 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28 * s),
          border: Border.all(color: const Color(0xFFE9E7F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _tab('Günlük', 0, s),
            _tab('Haftalık', 1, s),
            _tab('Aylık', 2, s),
          ],
        ),
      );

  Widget _tab(String title, int index, double s) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => selectedTab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selectedTab == index
                  ? const LinearGradient(colors: [Color(0xFF6D2CFA), purple])
                  : null,
              borderRadius: BorderRadius.circular(23 * s),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: selectedTab == index ? Colors.white : muted,
                fontSize: 11 * s,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );

  Widget _summaryCard(
    double s,
    List<Map<String, dynamic>> rows,
    double total,
  ) {
    final activeHours = _number('active_hours');
    final average = rows.isEmpty ? 0 : total / rows.length;
    return _whiteCard(
      padding: EdgeInsets.fromLTRB(18 * s, 16 * s, 18 * s, 14 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                selectedTab == 0
                    ? 'Bugünkü Kazancın'
                    : selectedTab == 1
                        ? 'Bu Haftaki Kazancın'
                        : 'Bu Ayki Kazancın',
                style: TextStyle(
                  color: muted,
                  fontSize: 12 * s,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 6 * s),
              Icon(Icons.visibility_off_outlined, color: muted, size: 16 * s),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 7 * s),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7FAF0),
                  borderRadius: BorderRadius.circular(18 * s),
                ),
                child: Text(
                  '↑ %18',
                  style: TextStyle(
                    color: green,
                    fontSize: 10.5 * s,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3 * s),
          Text(
            _money(total),
            style: TextStyle(
              color: navy,
              fontSize: 31 * s,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Düne göre',
              style: TextStyle(color: muted, fontSize: 8 * s),
            ),
          ),
          SizedBox(height: 12 * s),
          const Divider(height: 1, color: Color(0xFFEFEDF4)),
          SizedBox(height: 12 * s),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  Icons.inventory_2_rounded,
                  purple,
                  'Teslimat',
                  '${rows.length}',
                  s,
                ),
              ),
              _divider(s),
              Expanded(
                child: _miniStat(
                  Icons.schedule_rounded,
                  purple,
                  'Aktif Süre',
                  activeHours <= 0 ? '0s' : '${activeHours.toStringAsFixed(0)}s',
                  s,
                ),
              ),
              _divider(s),
              Expanded(
                child: _miniStat(
                  Icons.monetization_on_rounded,
                  orange,
                  'Paket Başına',
                  _money(average),
                  s,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider(double s) => Container(
        width: 1,
        height: 43 * s,
        color: const Color(0xFFEFEDF4),
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
              fontSize: 8.5 * s,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5 * s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 25 * s,
                height: 25 * s,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 15 * s),
              ),
              SizedBox(width: 5 * s),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: navy,
                    fontSize: 11.5 * s,
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
        final amount = (row['amount'] as num?)?.toDouble() ?? 0;
        final idx = ((d.hour - 8) / 2).floor();
        if (idx >= 0 && idx < values.length) values[idx] += amount;
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

    var maxValue = values.fold<double>(0, (a, b) => a > b ? a : b);
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
                  fontSize: 14.5 * s,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 7 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18 * s),
                border: Border.all(color: const Color(0xFFE9E7F0)),
              ),
              child: Row(
                children: [
                  Text(
                    _periodLabel(),
                    style: TextStyle(
                      color: purple,
                      fontSize: 9.5 * s,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 3 * s),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: purple, size: 16 * s),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10 * s),
        Container(
          height: 130 * s,
          padding: EdgeInsets.fromLTRB(8 * s, 10 * s, 8 * s, 3 * s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < values.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (i == selected && values[i] > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 7 * s, vertical: 4 * s),
                          decoration: BoxDecoration(
                            color: navy,
                            borderRadius: BorderRadius.circular(10 * s),
                          ),
                          child: Text(
                            _money(values[i]),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.5 * s,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      SizedBox(height: 3 * s),
                      Container(
                        width: 21 * s,
                        height: (24 + (values[i] / maxValue) * 55) * s,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: i == selected
                                ? [purple, purple2]
                                : const [Color(0xFFA783F3), Color(0xFFD5C4F9)],
                          ),
                          borderRadius: BorderRadius.circular(4 * s),
                        ),
                      ),
                      SizedBox(height: 5 * s),
                      Text(
                        labels[i],
                        style: TextStyle(
                          color: i == selected ? purple : muted,
                          fontSize: 8 * s,
                          fontWeight: i == selected
                              ? FontWeight.w800
                              : FontWeight.w500,
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

  Widget _distributionCard(
    double s,
    List<Map<String, dynamic>> rows,
    double total,
  ) {
    double food = 0, market = 0, other = 0;
    for (final row in rows) {
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;
      final text = '${row['title'] ?? ''} ${row['description'] ?? ''}'.toLowerCase();
      if (text.contains('market') || text.contains('alışveriş')) {
        market += amount;
      } else if (text.contains('evrak') ||
          text.contains('belge') ||
          text.contains('diğer')) {
        other += amount;
      } else {
        food += amount;
      }
    }
    final safe = total <= 0 ? 1.0 : total;
    final foodPct = (food / safe * 100).round();
    final marketPct = (market / safe * 100).round();
    final otherPct = (other / safe * 100).round();

    return _whiteCard(
      padding: EdgeInsets.all(14 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kazanç Dağılımı',
            style: TextStyle(
              color: navy,
              fontSize: 14.5 * s,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12 * s),
          Row(
            children: [
              SizedBox(
                width: 132 * s,
                height: 132 * s,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 112 * s,
                      height: 112 * s,
                      child: CircularProgressIndicator(
                        value: total <= 0 ? .01 : (food / safe).clamp(.01, 1),
                        strokeWidth: 20 * s,
                        backgroundColor: const Color(0xFFFF8750),
                        color: purple2,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _money(total),
                          style: TextStyle(
                            color: navy,
                            fontSize: 15 * s,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text('Toplam',
                            style: TextStyle(color: muted, fontSize: 9 * s)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6 * s),
              Expanded(
                child: Column(
                  children: [
                    _legend('Yemek', purple, foodPct, food, s),
                    SizedBox(height: 9 * s),
                    _legend('Market', orange, marketPct, market, s),
                    SizedBox(height: 9 * s),
                    _legend('Evrak / Diğer', const Color(0xFFB99BF4), otherPct,
                        other, s),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(
    String label,
    Color color,
    int percent,
    double amount,
    double s,
  ) => Row(
        children: [
          Container(
            width: 10 * s,
            height: 10 * s,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6 * s),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: navy,
                fontSize: 9.5 * s,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '%$percent',
            style: TextStyle(
              color: navy,
              fontSize: 9 * s,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 8 * s),
          SizedBox(
            width: 55 * s,
            child: Text(
              _money(amount),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: navy,
                fontSize: 9 * s,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      );

  Widget _goalCard(double s, double total) {
    const target = 400.0;
    final progress = (total / target).clamp(0.0, 1.0);
    return _whiteCard(
      padding: EdgeInsets.all(14 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Günlük Hedef',
                  style: TextStyle(
                    color: navy,
                    fontSize: 14.5 * s,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.edit_outlined, color: muted, size: 18 * s),
            ],
          ),
          SizedBox(height: 13 * s),
          ClipRRect(
            borderRadius: BorderRadius.circular(8 * s),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10 * s,
              backgroundColor: const Color(0xFFEDECF2),
              color: const Color(0xFF0CCB64),
            ),
          ),
          SizedBox(height: 7 * s),
          Row(
            children: [
              Text(
                '${_money(total)} / ${_money(target)}',
                style: TextStyle(
                  color: muted,
                  fontSize: 11 * s,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '%${(progress * 100).round()}',
                style: TextStyle(
                  color: green,
                  fontSize: 11 * s,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 11 * s),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 11 * s),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3EDFF), Color(0xFFF8F3FF)],
              ),
              borderRadius: BorderRadius.circular(13 * s),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: purple, size: 28 * s),
                SizedBox(width: 10 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harika gidiyorsun!',
                        style: TextStyle(
                          color: purple,
                          fontSize: 11 * s,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        total >= target
                            ? 'Bugünkü hedefini tamamladın.'
                            : 'Hedefine çok az kaldı. 💪',
                        style: TextStyle(color: muted, fontSize: 9 * s),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreCard(double s) => Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF0E8), Color(0xFFFFF2F5)],
          ),
          borderRadius: BorderRadius.circular(17 * s),
        ),
        child: Row(
          children: [
            Container(
              width: 39 * s,
              height: 39 * s,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE2C9),
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Icon(Icons.workspace_premium_rounded,
                  color: const Color(0xFFFF9B24), size: 25 * s),
            ),
            SizedBox(width: 11 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daha fazla kazan',
                    style: TextStyle(
                      color: const Color(0xFF5A145E),
                      fontSize: 10.5 * s,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Yoğun saatlerde online kalarak\nkazancını artırabilirsin.',
                    style: TextStyle(color: muted, fontSize: 9 * s, height: 1.2),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: const Color(0xFF8B306F), size: 21 * s),
          ],
        ),
      );

  Widget _onlineButton(double s) => Container(
        color: bg,
        padding: EdgeInsets.fromLTRB(12 * s, 8 * s, 12 * s, 13 * s),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54 * s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B2AF2), Color(0xFF4A11C7)],
                ),
                borderRadius: BorderRadius.circular(27 * s),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x335120D5),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(27 * s),
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.white, size: 24 * s),
                      SizedBox(width: 8 * s),
                      Text(
                        'Online Ol, Siparişleri Kaçırma',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5 * s,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _whiteCard({required Widget child, required EdgeInsets padding}) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 16,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: child,
      );
}
