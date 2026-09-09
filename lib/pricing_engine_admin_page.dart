import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class PricingEngineAdminPage extends StatefulWidget {
  const PricingEngineAdminPage({super.key});

  @override
  State<PricingEngineAdminPage> createState() => _PricingEngineAdminPageState();
}

class _PricingEngineAdminPageState extends State<PricingEngineAdminPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF74839A);
  final data = AppDataService.instance;
  bool loading = true;
  List<Map<String, dynamic>> rules = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final rows = await data.client.from('pricing_rules').select().order('vehicle_type').order('created_at');
      if (!mounted) return;
      setState(() { rules = List<Map<String, dynamic>>.from(rows); loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fiyat kuralları yüklenemedi: $e')));
    }
  }

  double _n(dynamic v, [double fallback = 0]) => double.tryParse('${v ?? ''}') ?? fallback;
  int _i(dynamic v, [int fallback = 0]) => int.tryParse('${v ?? ''}') ?? fallback;

  Future<void> _edit(Map<String, dynamic> r) async {
    final base = TextEditingController(text: '${r['base_price'] ?? 0}');
    final km = TextEditingController(text: '${r['per_km_price'] ?? 0}');
    final min = TextEditingController(text: '${r['minimum_price'] ?? 0}');
    final share = TextEditingController(text: '${r['courier_share_percent'] ?? 80}');
    final commission = TextEditingController(text: '${r['platform_commission_percent'] ?? 20}');
    final peakStart = TextEditingController(text: '${r['peak_start_hour'] ?? 17}');
    final peakEnd = TextEditingController(text: '${r['peak_end_hour'] ?? 21}');
    final peakMult = TextEditingController(text: '${r['peak_multiplier'] ?? 1}');
    final nightStart = TextEditingController(text: '${r['night_start_hour'] ?? 23}');
    final nightEnd = TextEditingController(text: '${r['night_end_hour'] ?? 6}');
    final nightMult = TextEditingController(text: '${r['night_multiplier'] ?? 1}');
    final densityThreshold = TextEditingController(text: '${r['density_threshold'] ?? 3}');
    final densityMult = TextEditingController(text: '${r['density_multiplier'] ?? 1}');
    final bonus = TextEditingController(text: '${r['courier_bonus_percent'] ?? 0}');
    bool active = r['is_active'] == true;

    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setD) => Container(
          padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFD8E0E9), borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 16),
                Text((r['name'] ?? 'Fiyat Kuralı').toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: navy)),
                Text((r['vehicle_type'] ?? '').toString(), style: const TextStyle(color: muted)),
                const SizedBox(height: 18),
                _title('Temel fiyat'),
                Row(children: [Expanded(child: _field(base, 'Baz ₺')), const SizedBox(width: 8), Expanded(child: _field(km, 'Km ₺')), const SizedBox(width: 8), Expanded(child: _field(min, 'Minimum ₺'))]),
                const SizedBox(height: 14),
                _title('Hakediş ve komisyon'),
                Row(children: [Expanded(child: _field(share, 'Kurye %')), const SizedBox(width: 8), Expanded(child: _field(commission, 'Komisyon %')), const SizedBox(width: 8), Expanded(child: _field(bonus, 'Bonus %'))]),
                const SizedBox(height: 14),
                _title('Yoğun saat'),
                Row(children: [Expanded(child: _field(peakStart, 'Başlangıç')), const SizedBox(width: 8), Expanded(child: _field(peakEnd, 'Bitiş')), const SizedBox(width: 8), Expanded(child: _field(peakMult, 'Çarpan'))]),
                const SizedBox(height: 14),
                _title('Gece'),
                Row(children: [Expanded(child: _field(nightStart, 'Başlangıç')), const SizedBox(width: 8), Expanded(child: _field(nightEnd, 'Bitiş')), const SizedBox(width: 8), Expanded(child: _field(nightMult, 'Çarpan'))]),
                const SizedBox(height: 14),
                _title('Talep yoğunluğu'),
                Row(children: [Expanded(child: _field(densityThreshold, 'İş/Kurye eşiği')), const SizedBox(width: 8), Expanded(child: _field(densityMult, 'Yoğunluk çarpanı'))]),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: active, onChanged: (v) => setD(() => active = v), title: const Text('Kural aktif', style: TextStyle(fontWeight: FontWeight.w800))),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  onPressed: () => Navigator.pop(sheet, true),
                  child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );

    if (save == true) {
      final courierShare = _n(share.text, 80).clamp(0, 100);
      final commissionPct = _n(commission.text, 20).clamp(0, 100);
      if ((courierShare + commissionPct - 100).abs() > .01) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kurye payı + komisyon toplamı %100 olmalı.')));
      } else {
        await data.client.from('pricing_rules').update({
          'base_price': _n(base.text),
          'per_km_price': _n(km.text),
          'minimum_price': _n(min.text),
          'courier_share_percent': courierShare,
          'platform_commission_percent': commissionPct,
          'courier_bonus_percent': _n(bonus.text).clamp(0, 100),
          'peak_start_hour': _i(peakStart.text, 17).clamp(0, 23),
          'peak_end_hour': _i(peakEnd.text, 21).clamp(0, 23),
          'peak_multiplier': _n(peakMult.text, 1).clamp(1, 10),
          'night_start_hour': _i(nightStart.text, 23).clamp(0, 23),
          'night_end_hour': _i(nightEnd.text, 6).clamp(0, 23),
          'night_multiplier': _n(nightMult.text, 1).clamp(1, 10),
          'density_threshold': _n(densityThreshold.text, 3).clamp(0, 1000),
          'density_multiplier': _n(densityMult.text, 1).clamp(1, 10),
          'is_active': active,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', r['id']);
        await _load();
      }
    }

    for (final c in [base,km,min,share,commission,peakStart,peakEnd,peakMult,nightStart,nightEnd,nightMult,densityThreshold,densityMult,bonus]) { c.dispose(); }
  }

  Widget _title(String s) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(s, style: const TextStyle(fontWeight: FontWeight.w900, color: navy)));
  Widget _field(TextEditingController c, String label) => TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label, filled: true, fillColor: const Color(0xFFF5F8FC), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(14))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, title: const Text('Fiyatlandırma Motoru', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFEAF5FF), borderRadius: BorderRadius.circular(22)),
                    child: const Text('Merkezi motor: mesafe + araç + bölge + saat + yoğunluk. Kurye hakedişi, bonus ve platform komisyonu aynı hesapta üretilir. Sipariş fiyatı artık istemciden değil sunucudan belirlenir.', style: TextStyle(color: navy, height: 1.4, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 14),
                  ...rules.map((r) => Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: ListTile(
                      onTap: () => _edit(r),
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(backgroundColor: const Color(0xFFEAF4FF), child: Icon(r['vehicle_type'] == 'car' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded, color: blue)),
                      title: Text((r['name'] ?? 'Kural').toString(), style: const TextStyle(fontWeight: FontWeight.w900, color: navy)),
                      subtitle: Text('Baz ₺${r['base_price']} • Km ₺${r['per_km_price']} • Min ₺${r['minimum_price']}\nPik ×${r['peak_multiplier']} • Gece ×${r['night_multiplier']} • Yoğunluk ×${r['density_multiplier']} • Bonus %${r['courier_bonus_percent']}', style: const TextStyle(height: 1.35, color: muted)),
                      trailing: Icon(Icons.chevron_right_rounded, color: r['is_active'] == true ? blue : muted),
                    ),
                  )),
                ],
              ),
            ),
    );
  }
}
