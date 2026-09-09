import 'package:flutter/material.dart';

Future<void> showCourierJobDetails({
  required BuildContext context,
  required String company,
  required String pickup,
  required String dropoff,
  required String pickupKm,
  required String totalKm,
  required String duration,
  required String package,
  required String packageType,
  required int earning,
  required String age,
  required String category,
  required IconData icon,
  required Color accent,
  required bool online,
  required VoidCallback onTake,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xA910213E),
    builder: (sheetContext) => _CourierJobDetailSheet(
      company: company,
      pickup: pickup,
      dropoff: dropoff,
      pickupKm: pickupKm,
      totalKm: totalKm,
      duration: duration,
      package: package,
      packageType: packageType,
      earning: earning,
      age: age,
      category: category,
      icon: icon,
      accent: accent,
      online: online,
      onTake: () {
        Navigator.pop(sheetContext);
        onTake();
      },
    ),
  );
}

class _CourierJobDetailSheet extends StatelessWidget {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const green = Color(0xFF0AAE60);
  static const muted = Color(0xFF6E7F93);

  final String company;
  final String pickup;
  final String dropoff;
  final String pickupKm;
  final String totalKm;
  final String duration;
  final String package;
  final String packageType;
  final int earning;
  final String age;
  final String category;
  final IconData icon;
  final Color accent;
  final bool online;
  final VoidCallback onTake;

  const _CourierJobDetailSheet({
    required this.company,
    required this.pickup,
    required this.dropoff,
    required this.pickupKm,
    required this.totalKm,
    required this.duration,
    required this.package,
    required this.packageType,
    required this.earning,
    required this.age,
    required this.category,
    required this.icon,
    required this.accent,
    required this.online,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: size.height * .88),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 72, height: 6, decoration: BoxDecoration(color: const Color(0xFFC8D0DA), borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Expanded(child: Text('İş Detayları', style: TextStyle(color: navy, fontSize: 28, fontWeight: FontWeight.w900))),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFF0F5FB), foregroundColor: navy),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Container(width: 68, height: 68, decoration: BoxDecoration(color: accent, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 34)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(company, style: const TextStyle(color: navy, fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Row(children: [
                        Text('$category · $packageType', style: const TextStyle(color: muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(14)), child: Text(age, style: const TextStyle(color: blue, fontSize: 10, fontWeight: FontWeight.w800))),
                      ]),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('₺$earning', style: const TextStyle(color: green, fontSize: 31, fontWeight: FontWeight.w900)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE7F9EF), borderRadius: BorderRadius.circular(16)), child: const Text('Önerilen İş', style: TextStyle(color: green, fontSize: 10.5, fontWeight: FontWeight.w800))),
                    ]),
                  ]),
                  const SizedBox(height: 18),
                  _routeMap(),
                  const SizedBox(height: 18),
                  _addressTile(Icons.location_on_rounded, blue, 'Alım Adresi', pickup),
                  const Divider(height: 22, color: Color(0xFFE6EDF5)),
                  _addressTile(Icons.location_on_rounded, const Color(0xFFFF334D), 'Teslim Adresi', dropoff),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: _infoCard(Icons.location_on_rounded, blue, 'Alımına Uzaklık', pickupKm, 'Yaklaşık 3 dk')),
                    const SizedBox(width: 9),
                    Expanded(child: _infoCard(Icons.route_rounded, blue, 'Toplam Mesafe', totalKm, '')),
                    const SizedBox(width: 9),
                    Expanded(child: _infoCard(Icons.schedule_rounded, const Color(0xFF334A68), 'Tahmini Süre', duration, '')),
                    const SizedBox(width: 9),
                    Expanded(child: _infoCard(Icons.inventory_2_outlined, const Color(0xFF334A68), 'Paket Sayısı', package, '')),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _infoCard(Icons.restaurant_rounded, accent, 'Paket Türü', packageType, '')),
                    const SizedBox(width: 9),
                    Expanded(child: _infoCard(Icons.credit_card_rounded, green, 'Ödeme Şekli', 'Online Ödeme', '')),
                    const SizedBox(width: 9),
                    Expanded(child: _infoCard(Icons.two_wheeler_rounded, const Color(0xFF7657F6), 'Araç Türü', 'Motosiklet', '')),
                    const SizedBox(width: 9),
                    Expanded(child: _infoCard(Icons.storefront_rounded, green, 'Restoran Bilgisi', company, '★ 4.6 (320)')),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFFFF6DB), borderRadius: BorderRadius.circular(20)),
                    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFA16A08), size: 22),
                      SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Not', style: TextStyle(color: Color(0xFF7D5311), fontWeight: FontWeight.w900, fontSize: 13)),
                        SizedBox(height: 4),
                        Text('Siparişi alım noktasından teslim aldıktan sonra doğrudan adrese teslim ediniz.', style: TextStyle(color: navy, fontSize: 11.5, height: 1.35)),
                      ])),
                    ]),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
              child: Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arama özelliği gerçek telefon bağlantısında açılacak.'))),
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('Restoranı Ara'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58), backgroundColor: const Color(0xFFF0F6FC), foregroundColor: navy, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: online ? onTake : null,
                    icon: const Icon(Icons.bolt_rounded),
                    label: Text(online ? 'İşi Al' : 'Offline'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58), backgroundColor: blue, disabledBackgroundColor: const Color(0xFFB3C3D4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeMap() => Container(
        height: 176,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [Color(0xFFEAF4EC), Color(0xFFE6F2FF)]),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _RoutePainter())),
          const Positioned(left: 22, top: 30, child: _MapPin(color: blue, icon: Icons.location_on_rounded, label: 'Alım\nMecidiyeköy')),
          const Positioned(right: 22, top: 60, child: _MapPin(color: Color(0xFFFF334D), icon: Icons.location_on_rounded, label: 'Teslim\nOsmanbey')),
          Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)]), child: Text('$totalKm\n$duration', textAlign: TextAlign.center, style: const TextStyle(color: navy, fontSize: 11, fontWeight: FontWeight.w900)))),
          Positioned(right: 14, bottom: 14, child: CircleAvatar(radius: 23, backgroundColor: Colors.white, child: Icon(Icons.navigation_rounded, color: blue, size: 24))),
        ]),
      );

  Widget _addressTile(IconData icon, Color color, String title, String address) => Row(children: [
        CircleAvatar(radius: 21, backgroundColor: color.withValues(alpha: .10), child: Icon(icon, color: color, size: 21)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: navy, fontSize: 12.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(address, style: const TextStyle(color: Color(0xFF566B83), fontSize: 12.5, height: 1.25)),
        ])),
        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.navigation_outlined, size: 17), label: const Text('Haritada Aç')),
      ]);

  Widget _infoCard(IconData icon, Color color, String title, String value, String sub) => Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF3F8FE), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 7),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 9.5)),
          const SizedBox(height: 2),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: navy, fontSize: 11.5, fontWeight: FontWeight.w900)),
          if (sub.isNotEmpty) ...[const SizedBox(height: 2), Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 8.5))],
        ]),
      );
}

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  const _MapPin({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        CircleAvatar(radius: 18, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 20)),
        const SizedBox(width: 5),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(12)), child: Text(label, style: const TextStyle(color: Color(0xFF10213E), fontSize: 9.5, fontWeight: FontWeight.w800))),
      ]);
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0x55FFFFFF)..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, 0), Offset(x + 30, size.height), grid);
    }
    for (double y = 20; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 12), grid);
    }

    final route = Path()
      ..moveTo(size.width * .13, size.height * .43)
      ..cubicTo(size.width * .30, size.height * .70, size.width * .42, size.height * .38, size.width * .53, size.height * .55)
      ..cubicTo(size.width * .68, size.height * .78, size.width * .78, size.height * .34, size.width * .87, size.height * .52);
    final halo = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 9..strokeCap = StrokeCap.round;
    final line = Paint()..color = const Color(0xFF168CF5)..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
    canvas.drawPath(route, halo);
    canvas.drawPath(route, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
