import 'package:flutter/material.dart';

import 'courier_assigned_jobs_page.dart';
import 'courier_bottom_nav.dart';
import 'courier_home_page.dart';
import 'courier_profile_page.dart';
import 'data/app_data_service.dart';

class CourierEarningsPage extends StatefulWidget {
  const CourierEarningsPage({super.key});
  @override
  State<CourierEarningsPage> createState() => _CourierEarningsPageState();
}

class _CourierEarningsPageState extends State<CourierEarningsPage> {
  static const purple = Color(0xFF5120D5),
      deep = Color(0xFF25106E),
      navy = Color(0xFF171052),
      green = Color(0xFF16C873),
      orange = Color(0xFFFF7A36),
      muted = Color(0xFF7B7890),
      bg = Color(0xFFF7F7FA);
  final data = AppDataService.instance;
  Map<String, dynamic> summary = {};
  Map<String, dynamic>? bank;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final x = await Future.wait([
        data.getCourierEarningsSummary(),
        data.getCourierBankAccount(),
      ]);
      if (mounted)
        setState(() {
          summary = Map<String, dynamic>.from(x[0] as Map);
          bank = x[1] as Map<String, dynamic>?;
          loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  double n(String k) => (summary[k] as num?)?.toDouble() ?? 0;
  String money(dynamic x) {
    final v = x is num ? x.toDouble() : 0;
    return v == v.roundToDouble()
        ? '₺${v.toInt()}'
        : '₺${v.toStringAsFixed(2)}';
  }

  String time(dynamic raw) {
    final d = DateTime.tryParse((raw ?? '').toString())?.toLocal();
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  bool _isToday(dynamic raw) {
    final d = DateTime.tryParse((raw ?? '').toString())?.toLocal();
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  void msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _bankDialog() async {
    final holder = TextEditingController(
          text: (bank?['account_holder'] ?? '').toString(),
        ),
        bn = TextEditingController(text: (bank?['bank_name'] ?? '').toString()),
        iban = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          MediaQuery.of(c).viewInsets.bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Banka Hesabı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: navy,
              ),
            ),
            const SizedBox(height: 14),
            TextField(controller: holder, decoration: _input('Hesap sahibi')),
            const SizedBox(height: 9),
            TextField(controller: bn, decoration: _input('Banka adı')),
            const SizedBox(height: 9),
            TextField(
              controller: iban,
              decoration: _input('Yeni IBAN (TR...)'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(c, true),
                style: FilledButton.styleFrom(backgroundColor: purple),
                child: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok == true && iban.text.trim().isNotEmpty) {
      try {
        bank = await data.saveCourierBankAccount(
          accountHolder: holder.text.trim(),
          bankName: bn.text.trim(),
          iban: iban.text.trim(),
        );
        if (mounted) setState(() {});
      } catch (e) {
        msg('$e');
      }
    }
    holder.dispose();
    bn.dispose();
    iban.dispose();
  }

  InputDecoration _input(String l) => InputDecoration(
    labelText: l,
    filled: true,
    fillColor: const Color(0xFFF4F2FA),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, c) {
          final s = (c.maxWidth / 390).clamp(.92, 1.08).toDouble();
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _hero(s),
                      Transform.translate(
                        offset: Offset(0, -22 * s),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14 * s),
                          child: Column(
                            children: [
                              _totalCard(s),
                              SizedBox(height: 10 * s),
                              _dailyEarnings(s),
                              SizedBox(height: 10 * s),
                              _stats(s),
                              SizedBox(height: 19 * s),
                              _chart(s),
                              SizedBox(height: 20 * s),
                              _details(s),
                              SizedBox(height: 18 * s),
                              _bank(s),
                              SizedBox(height: 24 * s),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _bottom(s),
            ],
          );
        },
      ),
    ),
  );

  Widget _hero(double s) => Container(
    height: 315 * s,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [deep, Color(0xFF4D17C8), Color(0xFF7A20E8)],
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(38),
        bottomRight: Radius.circular(38),
      ),
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 20 * s,
          top: 20 * s,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kazançlarım',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28 * s,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3 * s),
              Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white70,
                    size: 16 * s,
                  ),
                  SizedBox(width: 4 * s),
                  Text(
                    'Emeğin Yolunu Açıyor',
                    style: TextStyle(color: Colors.white70, fontSize: 11 * s),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(right: 17 * s, top: 18 * s, child: _period(s)),
        Positioned(
          left: 22 * s,
          top: 142 * s,
          child: Transform.rotate(
            angle: -.07,
            child: Text(
              'Daha\nFazla Yol\nDaha Fazla\nKazan!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18 * s,
                height: 1.08,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Positioned(
          right: -6 * s,
          bottom: -2 * s,
          width: 265 * s,
          height: 235 * s,
          child: Image.asset(
            'assets/images/Profil3d.png',
            fit: BoxFit.contain,
            alignment: Alignment.bottomRight,
          ),
        ),
      ],
    ),
  );
  Widget _period(double s) => Container(
    padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 9 * s),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(22 * s),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      children: [
        Icon(Icons.calendar_month_outlined, color: Colors.white, size: 16 * s),
        SizedBox(width: 7 * s),
        Text(
          'Bu Hafta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.5 * s,
            fontWeight: FontWeight.w700,
          ),
        ),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.white,
          size: 18 * s,
        ),
      ],
    ),
  );
  Widget _card({required Widget child, double radius = 19}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
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
  Widget _totalCard(double s) => _card(
    child: Padding(
      padding: EdgeInsets.all(16 * s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Toplam Kazanç',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11 * s,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6 * s),
                    Icon(
                      Icons.visibility_off_outlined,
                      color: muted,
                      size: 15 * s,
                    ),
                  ],
                ),
                SizedBox(height: 4 * s),
                Text(
                  money(n('total_earned')),
                  style: TextStyle(
                    color: navy,
                    fontSize: 28 * s,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * s,
                  vertical: 7 * s,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2FAED),
                  borderRadius: BorderRadius.circular(20 * s),
                ),
                child: Text(
                  '↑ %12',
                  style: TextStyle(
                    color: green,
                    fontSize: 11 * s,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: 4 * s),
              Text(
                'Geçen haftaya göre',
                style: TextStyle(color: muted, fontSize: 7.5 * s),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _dailyEarnings(double s) => StreamBuilder<List<Map<String, dynamic>>>(
    stream: data.watchCourierEarnings(),
    builder: (context, snap) {
      final rows = (snap.data ?? const <Map<String, dynamic>>[])
          .where((r) => _isToday(r['created_at']))
          .toList();
      final total = rows.fold<double>(
        0,
        (sum, r) => sum + ((r['amount'] as num?)?.toDouble() ?? 0),
      );
      return _card(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15 * s, vertical: 12 * s),
          child: Row(
            children: [
              Container(
                width: 38 * s,
                height: 38 * s,
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.today_rounded, color: purple, size: 20 * s),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günlük Kazanç',
                      style: TextStyle(
                        color: muted,
                        fontSize: 9 * s,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2 * s),
                    Text(
                      money(total),
                      style: TextStyle(
                        color: navy,
                        fontSize: 19 * s,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${rows.length} işlem',
                    style: TextStyle(
                      color: navy,
                      fontSize: 9 * s,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  Text(
                    'Bugün',
                    style: TextStyle(color: muted, fontSize: 8 * s),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _stats(double s) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.9,
    mainAxisSpacing: 8 * s,
    crossAxisSpacing: 8 * s,
    children: [
      _stat(
        Icons.inventory_2_rounded,
        purple,
        '${n('delivery_count').toInt()}',
        'Teslimat',
        '↑ %20',
        s,
      ),
      _stat(
        Icons.schedule_rounded,
        purple,
        '${n('active_hours').toInt()}s',
        'Aktif Süre',
        '↑ %8',
        s,
      ),
      _stat(
        Icons.route_rounded,
        const Color(0xFFFF4C55),
        '${n('distance_km').toInt()} km',
        'Toplam Mesafe',
        '↑ %14',
        s,
      ),
      _stat(
        Icons.monetization_on_rounded,
        orange,
        money(n('average_per_delivery')),
        'Paket Başına Ort.',
        '↑ %6',
        s,
      ),
    ],
  );
  Widget _stat(
    IconData i,
    Color color,
    String value,
    String label,
    String rise,
    double s,
  ) => _card(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      child: Row(
        children: [
          Container(
            width: 34 * s,
            height: 34 * s,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(i, color: color, size: 18 * s),
          ),
          SizedBox(width: 9 * s),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: navy,
                    fontSize: 14 * s,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: 8 * s),
                ),
              ],
            ),
          ),
          Text(
            rise,
            style: TextStyle(
              color: green,
              fontSize: 7.5 * s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _chart(double s) {
    final vals = [.32, .49, .68, .47, .90, .35, .52, .70];
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz', ''];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Kazanç Grafiği',
                style: TextStyle(
                  color: navy,
                  fontSize: 15 * s,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _periodLight(s),
          ],
        ),
        SizedBox(height: 13 * s),
        SizedBox(
          height: 148 * s,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < vals.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (i == 4)
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
                            money(n('today') == 0 ? 320 : n('today')),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8 * s,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      SizedBox(height: 3 * s),
                      Container(
                        width: 22 * s,
                        height: 98 * s * vals[i],
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: i == 4
                                ? [purple, const Color(0xFF7135E7)]
                                : [
                                    const Color(0xFFB598F2),
                                    const Color(0xFFD8C9F8),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(4 * s),
                        ),
                      ),
                      SizedBox(height: 5 * s),
                      Text(
                        days[i],
                        style: TextStyle(color: muted, fontSize: 8 * s),
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

  Widget _periodLight(double s) => Container(
    padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 7 * s),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18 * s),
      border: Border.all(color: const Color(0xFFEAE8F0)),
    ),
    child: Row(
      children: [
        Text(
          'Bu Hafta',
          style: TextStyle(
            color: navy,
            fontSize: 9 * s,
            fontWeight: FontWeight.w700,
          ),
        ),
        Icon(Icons.keyboard_arrow_down_rounded, color: navy, size: 16 * s),
      ],
    ),
  );
  Widget _details(double s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Kazanç Detayları',
              style: TextStyle(
                color: navy,
                fontSize: 15 * s,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            'Tümü',
            style: TextStyle(
              color: purple,
              fontSize: 10 * s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      SizedBox(height: 9 * s),
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: data.watchCourierEarnings(),
        builder: (context, snap) {
          final rows = snap.data ?? const [];
          if (rows.isEmpty) return _empty(s);
          return _card(
            child: Column(
              children: [
                for (int i = 0; i < rows.take(4).length; i++)
                  _detailRow(rows[i], i, s),
              ],
            ),
          );
        },
      ),
    ],
  );
  Widget _detailRow(Map<String, dynamic> r, int index, double s) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
    decoration: BoxDecoration(
      border: index == 0
          ? null
          : const Border(top: BorderSide(color: Color(0xFFF0EEF4))),
    ),
    child: Row(
      children: [
        Container(
          width: 34 * s,
          height: 34 * s,
          decoration: BoxDecoration(
            color: (index % 3 == 2 ? green : orange).withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            index % 3 == 2
                ? Icons.shopping_basket_rounded
                : Icons.restaurant_rounded,
            color: index % 3 == 2 ? green : orange,
            size: 17 * s,
          ),
        ),
        SizedBox(width: 9 * s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (r['title'] ?? r['description'] ?? 'Teslimat').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: navy,
                  fontSize: 10 * s,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                time(r['created_at']),
                style: TextStyle(color: muted, fontSize: 8 * s),
              ),
            ],
          ),
        ),
        Text(
          money(r['amount']),
          style: TextStyle(
            color: navy,
            fontSize: 11 * s,
            fontWeight: FontWeight.w900,
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: muted, size: 18 * s),
      ],
    ),
  );
  Widget _empty(double s) => _card(
    child: Padding(
      padding: EdgeInsets.all(15 * s),
      child: Center(
        child: Text(
          'Henüz kazanç kaydı yok',
          style: TextStyle(color: muted, fontSize: 10 * s),
        ),
      ),
    ),
  );
  Widget _bank(double s) => InkWell(
    onTap: _bankDialog,
    child: _card(
      child: Padding(
        padding: EdgeInsets.all(13 * s),
        child: Row(
          children: [
            Container(
              width: 35 * s,
              height: 35 * s,
              decoration: BoxDecoration(
                color: purple.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: purple,
                size: 18 * s,
              ),
            ),
            SizedBox(width: 10 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ödeme Hesabı',
                    style: TextStyle(
                      color: navy,
                      fontSize: 10.5 * s,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    bank == null
                        ? 'IBAN ekle'
                        : '${bank?['bank_name'] ?? ''} • ${bank?['iban_masked'] ?? ''}',
                    style: TextStyle(color: muted, fontSize: 8 * s),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: muted, size: 19 * s),
          ],
        ),
      ),
    ),
  );
  void _navigateBottom(int index) {
    if (index == 2) return;
    final page = switch (index) {
      0 => const CourierHomePage(),
      1 => const CourierAssignedJobsPage(),
      3 => const CourierProfilePage(),
      _ => const CourierEarningsPage(),
    };
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  Widget _bottom(double s) =>
      CourierBottomNav(currentIndex: 2, onTap: _navigateBottom);
}
