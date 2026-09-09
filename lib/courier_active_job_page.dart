import 'package:flutter/material.dart';

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
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF718198);
  static const green = Color(0xFF10B866);
  int step = 0;

  String get actionLabel => switch (step) {
        0 => 'Alım Noktasına Git',
        1 => 'Teslim Aldım',
        2 => 'Teslimat Adresine Git',
        _ => 'Teslim Ettim',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _topBar(),
                  const SizedBox(height: 18),
                  _hero(),
                  const SizedBox(height: 20),
                  _progress(),
                  const SizedBox(height: 22),
                  _mapCard(),
                  const SizedBox(height: 18),
                  _shipmentCard(),
                  const SizedBox(height: 16),
                  _customerCard(),
                ]),
              ),
            ),
            _bottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() => Row(children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 5))]),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF19518A)),
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _cancelDialog,
          icon: const Icon(Icons.warning_amber_rounded),
          label: const Text('İşi İptal Et'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF4C4C), side: const BorderSide(color: Color(0xFFFFC7C7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
        ),
      ]);

  Widget _hero() => SizedBox(
        height: 180,
        child: Stack(children: [
          const Positioned(
            left: 0,
            top: 18,
            width: 245,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('İşin Aktif!', style: TextStyle(color: navy, fontSize: 34, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text('Evrakı alım noktasından teslim al\nve teslimat adresine ulaştır.', style: TextStyle(color: muted, fontSize: 17, height: 1.35, fontWeight: FontWeight.w500)),
            ]),
          ),
          Positioned(
            right: -12,
            bottom: -5,
            width: 185,
            height: 185,
            child: Image.asset('assets/images/kurye_header_hd.png', fit: BoxFit.contain),
          ),
        ]),
      );

  Widget _progress() {
    const labels = ['Alım Noktasına Git', 'Teslim Aldım', 'Teslimat Adresine Git', 'Teslim Ettim'];
    return Row(children: [
      for (int i = 0; i < 4; i++) ...[
        Expanded(
          child: Column(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: i <= step ? blue : const Color(0xFFF2F7FC), shape: BoxShape.circle, border: Border.all(color: i <= step ? blue : const Color(0xFFC8D9EA), width: 2)),
              child: i <= step ? const Icon(Icons.check_rounded, color: Colors.white, size: 19) : null,
            ),
            const SizedBox(height: 7),
            Text(labels[i], textAlign: TextAlign.center, style: TextStyle(color: i <= step ? blue : muted, fontSize: 9.5, fontWeight: i <= step ? FontWeight.w900 : FontWeight.w600)),
          ]),
        ),
        if (i < 3) Container(width: 20, height: 2, color: i < step ? blue : const Color(0xFFD4E1EE)),
      ],
    ]);
  }

  Widget _mapCard() => Container(
        height: 310,
        decoration: BoxDecoration(color: const Color(0xFFEAF4F9), borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 6))]),
        child: Stack(children: [
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(28), child: CustomPaint(painter: _MapPainter()))),
          const Positioned(left: 26, top: 84, child: Text('Şişli', style: TextStyle(color: Color(0xFF60728B), fontSize: 21, fontWeight: FontWeight.w900))),
          const Positioned(left: 185, top: 160, child: Text('Mecidiyeköy', style: TextStyle(color: Color(0xFF60728B), fontSize: 22, fontWeight: FontWeight.w900))),
          Positioned(
            right: 24,
            top: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12)]),
              child: Row(children: [const Icon(Icons.location_on_rounded, color: blue), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Alım Noktası', style: TextStyle(color: navy, fontWeight: FontWeight.w900)), Text('${widget.pickupKm} • yaklaşık 4 dk', style: const TextStyle(color: muted, fontSize: 11))])]),
            ),
          ),
          const Positioned(left: 150, top: 118, child: CircleAvatar(radius: 24, backgroundColor: blue, child: Icon(Icons.navigation_rounded, color: Colors.white, size: 28))),
          Positioned(right: 18, bottom: 18, child: CircleAvatar(radius: 26, backgroundColor: Colors.white, child: const Icon(Icons.navigation_rounded, color: blue))),
        ]),
      );

  Widget _shipmentCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 5))]),
        child: Column(children: [
          Row(children: [
            const Text('Gönderi Detayları', style: TextStyle(color: navy, fontSize: 23, fontWeight: FontWeight.w900)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEAF5FF), borderRadius: BorderRadius.circular(12)), child: const Text('#12458', style: TextStyle(color: blue, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF1F8FF), borderRadius: BorderRadius.circular(19)),
            child: Row(children: [
              const CircleAvatar(radius: 24, backgroundColor: Color(0xFFE3F2FF), child: Icon(Icons.description_outlined, color: blue)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Evrak Teslimatı', style: TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('1 adet evrak', style: TextStyle(color: muted, fontSize: 11))])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text('Tahmini Ücret', style: TextStyle(color: muted, fontSize: 11)), Text('₺${widget.earning}', style: const TextStyle(color: green, fontSize: 27, fontWeight: FontWeight.w900))]),
            ]),
          ),
          const SizedBox(height: 14),
          _address(Icons.location_on_rounded, blue, 'Alım Adresi', widget.pickup),
          const Divider(height: 24, color: Color(0xFFE7EEF5)),
          _address(Icons.location_on_rounded, const Color(0xFFFF4757), 'Teslimat Adresi', widget.dropoff),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _metric(Icons.route_rounded, widget.pickupKm, 'Alımına Uzaklık')),
            const SizedBox(width: 8),
            Expanded(child: _metric(Icons.inventory_2_outlined, '1 adet', 'Evrak')),
            const SizedBox(width: 8),
            Expanded(child: _metric(Icons.schedule_rounded, widget.duration, 'Tahmini Süre')),
          ]),
        ]),
      );

  Widget _address(IconData icon, Color color, String title, String value) => Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: navy, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(value, style: const TextStyle(color: muted, fontSize: 12))])),
        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.navigation_rounded, size: 17), label: const Text('Haritada Aç')),
      ]);

  Widget _metric(IconData icon, String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(color: const Color(0xFFF1F8FF), borderRadius: BorderRadius.circular(17)),
        child: Column(children: [Icon(icon, color: const Color(0xFF155BAC), size: 23), const SizedBox(height: 5), Text(value, style: const TextStyle(color: navy, fontWeight: FontWeight.w900)), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 9))]),
      );

  Widget _customerCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
        child: Row(children: [
          const CircleAvatar(radius: 27, backgroundColor: Color(0xFFEAF5FF), child: Icon(Icons.person_outline_rounded, color: blue, size: 29)),
          const SizedBox(width: 13),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Müşteri Bilgileri', style: TextStyle(color: muted, fontSize: 11)), Text('Ahmet Yılmaz', style: TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.w900)), Text('+90 555 123 45 67', style: TextStyle(color: muted, fontSize: 12))])),
          _circleAction(Icons.phone_rounded),
          const SizedBox(width: 9),
          _circleAction(Icons.chat_bubble_rounded),
        ]),
      );

  Widget _circleAction(IconData icon) => InkWell(onTap: () {}, child: CircleAvatar(radius: 25, backgroundColor: const Color(0xFFEAF5FF), child: Icon(icon, color: blue)));

  Widget _bottomAction() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: FilledButton.icon(
            onPressed: _advance,
            icon: Icon(step == 3 ? Icons.check_rounded : Icons.navigation_rounded),
            label: Text(actionLabel),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(62), backgroundColor: step == 1 || step == 3 ? green : blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ),
        ),
      );

  void _advance() {
    if (step < 3) {
      setState(() => step++);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        icon: const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE8FBF2), child: Icon(Icons.check_rounded, color: green, size: 34)),
        title: const Text('Tebrikler!'),
        content: Text('₺${widget.earning} kazanç hesabına işlendi.', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [FilledButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Tamam'))],
      ),
    );
  }

  void _cancelDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('İşi iptal etmek istiyor musun?'),
        content: const Text('İptal edilen iş tekrar iş havuzuna dönecek.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')), FilledButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF4C4C)), child: const Text('İptal Et'))],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = Colors.white..strokeWidth = 3;
    for (double y = 25; y < size.height; y += 55) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 28), road);
    }
    for (double x = 10; x < size.width; x += 85) {
      canvas.drawLine(Offset(x, 0), Offset(x + 55, size.height), road);
    }
    final route = Path()..moveTo(size.width * .42, size.height * .56)..cubicTo(size.width * .55, size.height * .40, size.width * .63, size.height * .70, size.width * .78, size.height * .28);
    canvas.drawPath(route, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round);
    canvas.drawPath(route, Paint()..color = const Color(0xFF168CF5)..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
