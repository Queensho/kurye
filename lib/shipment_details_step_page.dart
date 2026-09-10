import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'address_picker_page.dart';
import 'courier_search_page.dart';
import 'data/app_data_service.dart';

class ShipmentDetailsStepPage extends StatefulWidget {
  const ShipmentDetailsStepPage({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.packageIndex,
    required this.paymentIndex,
    required this.selectedCardId,
    required this.distanceKm,
    required this.durationMin,
    required this.quotedPrice,
    required this.initialWeight,
    required this.initialSize,
  });

  final AddressSelection pickup;
  final AddressSelection dropoff;
  final int packageIndex;
  final int paymentIndex;
  final String? selectedCardId;
  final double distanceKm;
  final int durationMin;
  final int quotedPrice;
  final String initialWeight;
  final String initialSize;

  @override
  State<ShipmentDetailsStepPage> createState() => _ShipmentDetailsStepPageState();
}

class _ShipmentDetailsStepPageState extends State<ShipmentDetailsStepPage> {
  static const orange = Color(0xFFFF5A1F);
  static const navy = Color(0xFF171052);
  static const muted = Color(0xFF77758A);
  static const bg = Color(0xFFF7F7FA);
  static const soft = Color(0xFFF4F3F9);

  final _contentController = TextEditingController();
  final _noteController = TextEditingController();
  final _picker = ImagePicker();

  late String weight;
  late String size;
  bool fragile = false;
  bool insured = false;
  bool creating = false;
  bool confirmation = false;
  final List<Uint8List> photos = [];

  @override
  void initState() {
    super.initState();
    weight = widget.initialWeight;
    size = widget.initialSize;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _choose(String title, List<String> values, ValueChanged<String> onPick) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(title, style: const TextStyle(color: navy, fontWeight: FontWeight.w900, fontSize: 18))),
            for (final value in values)
              ListTile(
                title: Text(value),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, value),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (selected != null) onPick(selected);
  }

  Future<void> _addPhoto() async {
    if (photos.length >= 3) return;
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => photos.add(bytes));
  }

  String _combinedNote() {
    final parts = <String>[];
    final content = _contentController.text.trim();
    final note = _noteController.text.trim();
    if (content.isNotEmpty) parts.add('Paket içeriği: $content');
    if (note.isNotEmpty) parts.add(note);
    if (fragile) parts.add('Hassas / Kırılabilir');
    if (insured) parts.add('Sigortalı gönderi talebi');
    return parts.join(' • ');
  }

  Future<void> _createShipment() async {
    if (creating) return;
    setState(() => creating = true);
    try {
      const packageTypes = ['package', 'document', 'market', 'gift'];
      final created = await AppDataService.instance.createShipment(
        vehicleType: 'motorcycle',
        packageType: packageTypes[widget.packageIndex.clamp(0, 3)],
        pickupAddress: widget.pickup.displayName,
        dropoffAddress: widget.dropoff.displayName,
        pickupLat: widget.pickup.lat,
        pickupLng: widget.pickup.lng,
        dropoffLat: widget.dropoff.lat,
        dropoffLng: widget.dropoff.lng,
        weightLabel: weight,
        sizeLabel: size,
        note: _combinedNote().isEmpty ? null : _combinedNote(),
        distanceKm: widget.distanceKm,
        durationMin: widget.durationMin,
        estimatedPrice: widget.quotedPrice,
        paymentType: widget.paymentIndex == 0 ? 'cash' : 'online',
        paymentMethodId: widget.paymentIndex == 1 ? widget.selectedCardId : null,
      );
      final id = created['id']?.toString();
      if (id == null || id.isEmpty) throw StateError('Gönderi kimliği alınamadı.');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => CourierSearchPage(shipmentId: id)),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gönderi oluşturulamadı: $e')));
      }
    } finally {
      if (mounted) setState(() => creating = false);
    }
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
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _header(s),
                _steps(s),
                if (!confirmation) _details(s) else _confirmation(s),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(double s) {
    return SizedBox(
      height: 142 * s,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(child: Container(color: const Color(0xFFF9F8FC))),
          Positioned(
            right: -40 * s,
            top: -54 * s,
            width: 248 * s,
            height: 205 * s,
            child: Image.asset('assets/images/3d_kurye.png', fit: BoxFit.contain, alignment: Alignment.bottomRight),
          ),
          Positioned(
            left: 17 * s,
            top: 14 * s,
            child: InkWell(
              onTap: () {
                if (confirmation) {
                  setState(() => confirmation = false);
                } else {
                  Navigator.pop(context);
                }
              },
              borderRadius: BorderRadius.circular(14 * s),
              child: Container(
                width: 40 * s,
                height: 40 * s,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13 * s), boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 10)]),
                child: Icon(Icons.arrow_back_rounded, color: navy, size: 24 * s),
              ),
            ),
          ),
          Positioned(
            left: 17 * s,
            bottom: 16 * s,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gönderi Oluştur', style: TextStyle(color: navy, fontSize: 23 * s, fontWeight: FontWeight.w900, letterSpacing: -.8)),
                SizedBox(height: 2 * s),
                Text('Hızlı, güvenli, kapınıza teslim.', style: TextStyle(color: muted, fontSize: 12 * s, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _steps(double s) {
    final activeStep = confirmation ? 3 : 2;
    return Container(
      height: 56 * s,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 18 * s),
      child: Row(
        children: [
          _step(1, 'Bilgiler', activeStep, s),
          _line(activeStep > 1, s),
          _step(2, 'Detaylar', activeStep, s),
          _line(activeStep > 2, s),
          _step(3, 'Onay', activeStep, s),
        ],
      ),
    );
  }

  Widget _step(int number, String label, int active, double s) {
    final done = number < active;
    final selected = number == active;
    final circleColor = selected ? orange : done ? const Color(0xFF8F90B8) : const Color(0xFFE7E7ED);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28 * s,
          height: 28 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          child: done
              ? Icon(Icons.check_rounded, color: Colors.white, size: 15 * s)
              : Text('$number', style: TextStyle(color: selected ? Colors.white : const Color(0xFFB3B2BE), fontSize: 12 * s, fontWeight: FontWeight.w800)),
        ),
        SizedBox(width: 7 * s),
        Text(label, style: TextStyle(color: selected ? navy : muted, fontSize: 12.5 * s, fontWeight: selected ? FontWeight.w900 : FontWeight.w600)),
      ],
    );
  }

  Widget _line(bool active, double s) => Expanded(
        child: Container(height: 2 * s, margin: EdgeInsets.symmetric(horizontal: 7 * s), color: active ? orange : const Color(0xFFE9E8EE)),
      );

  Widget _details(double s) {
    return Padding(
      padding: EdgeInsets.fromLTRB(17 * s, 15 * s, 17 * s, 24 * s),
      child: Column(
        children: [
          _packageDetailsCard(s),
          SizedBox(height: 10 * s),
          _photosCard(s),
          SizedBox(height: 10 * s),
          _notesCard(s),
          SizedBox(height: 10 * s),
          _toggleCard(Icons.wine_bar_rounded, 'Hassas / Kırılabilir', 'Daha dikkatli taşıma için işaretleyin.', fragile, (v) => setState(() => fragile = v), s, warm: true),
          SizedBox(height: 8 * s),
          _toggleCard(Icons.verified_user_outlined, 'Sigortalı Gönderi', 'Ek güvence ile gönderinizi güvence altına alın.', insured, (v) => setState(() => insured = v), s),
          SizedBox(height: 12 * s),
          _priceCard(s),
          SizedBox(height: 12 * s),
          _continueButton('Devam Et', () => setState(() => confirmation = true), s),
        ],
      ),
    );
  }

  Widget _packageDetailsCard(double s) {
    return Container(
      padding: EdgeInsets.all(14 * s),
      decoration: _cardDecoration(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBubble(Icons.inventory_2_outlined, s),
              SizedBox(width: 10 * s),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Paket Detayları', style: TextStyle(color: navy, fontSize: 14 * s, fontWeight: FontWeight.w900)),
                  SizedBox(height: 2 * s),
                  Text('Gönderi hakkında bazı detayları belirtin.', style: TextStyle(color: muted, fontSize: 10.5 * s)),
                ]),
              ),
            ],
          ),
          SizedBox(height: 12 * s),
          Row(
            children: [
              Expanded(child: _selectBox('Ağırlık (kg)', weight, Icons.inventory_2_outlined, () => _choose('Ağırlık', ['1 kg', '2 kg', '3 kg', '5 kg', '10 kg', '20 kg+'], (v) => setState(() => weight = v)), s)),
              SizedBox(width: 9 * s),
              Expanded(child: _selectBox('Boyut', size, Icons.inventory_2_outlined, () => _choose('Boyut', ['Çok Küçük', 'Küçük', 'Orta', 'Büyük', 'Çok Büyük'], (v) => setState(() => size = v)), s)),
            ],
          ),
          SizedBox(height: 12 * s),
          Row(children: [Icon(Icons.description_outlined, color: navy, size: 19 * s), SizedBox(width: 7 * s), Text('Paket İçeriği', style: TextStyle(color: navy, fontSize: 12 * s, fontWeight: FontWeight.w800))]),
          SizedBox(height: 7 * s),
          _textArea(_contentController, 'Paket içeriği nedir?', s),
        ],
      ),
    );
  }

  Widget _photosCard(double s) {
    return Container(
      padding: EdgeInsets.all(14 * s),
      decoration: _cardDecoration(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _iconBubble(Icons.photo_camera_outlined, s),
            SizedBox(width: 10 * s),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [TextSpan(text: 'Paket Fotoğrafı ', style: TextStyle(color: navy, fontSize: 14 * s, fontWeight: FontWeight.w900)), TextSpan(text: '(Opsiyonel)', style: TextStyle(color: const Color(0xFF8581A7), fontSize: 12 * s, fontWeight: FontWeight.w700))])),
              SizedBox(height: 2 * s),
              Text('Daha hızlı eşleşme için paket fotoğrafı ekleyin.', style: TextStyle(color: muted, fontSize: 10.5 * s)),
            ])),
          ]),
          SizedBox(height: 12 * s),
          SizedBox(
            height: 78 * s,
            child: Row(
              children: [
                InkWell(
                  onTap: _addPhoto,
                  borderRadius: BorderRadius.circular(12 * s),
                  child: Container(
                    width: 82 * s,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12 * s), border: Border.all(color: const Color(0xFFAAA6CA), style: BorderStyle.solid)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_circle_outline_rounded, color: navy, size: 25 * s),
                      SizedBox(height: 5 * s),
                      Text('Fotoğraf Ekle', style: TextStyle(color: navy, fontSize: 9.5 * s, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                SizedBox(width: 9 * s),
                for (int i = 0; i < photos.length; i++) ...[
                  _photoTile(i, s),
                  if (i != photos.length - 1) SizedBox(width: 8 * s),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoTile(int index, double s) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10 * s),
          child: Image.memory(photos[index], width: 73 * s, height: 78 * s, fit: BoxFit.cover),
        ),
        Positioned(
          right: -4 * s,
          top: -4 * s,
          child: InkWell(
            onTap: () => setState(() => photos.removeAt(index)),
            child: Container(width: 20 * s, height: 20 * s, decoration: const BoxDecoration(color: Color(0xCC222222), shape: BoxShape.circle), child: Icon(Icons.close_rounded, color: Colors.white, size: 14 * s)),
          ),
        ),
      ],
    );
  }

  Widget _notesCard(double s) {
    return Container(
      padding: EdgeInsets.all(14 * s),
      decoration: _cardDecoration(s),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.chat_bubble_outline_rounded, color: navy, size: 19 * s),
          SizedBox(width: 7 * s),
          Text.rich(TextSpan(children: [TextSpan(text: 'Özel Talimatlar ', style: TextStyle(color: navy, fontSize: 12.5 * s, fontWeight: FontWeight.w800)), TextSpan(text: '(Opsiyonel)', style: TextStyle(color: const Color(0xFF8581A7), fontSize: 11 * s, fontWeight: FontWeight.w700))])),
        ]),
        SizedBox(height: 8 * s),
        _textArea(_noteController, 'Kurye için özel bir not ekleyin...', s),
      ]),
    );
  }

  Widget _toggleCard(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged, double s, {bool warm = false}) {
    return Container(
      height: 64 * s,
      padding: EdgeInsets.symmetric(horizontal: 13 * s),
      decoration: _cardDecoration(s),
      child: Row(children: [
        Container(width: 38 * s, height: 38 * s, decoration: BoxDecoration(color: warm ? const Color(0xFFFFF0E9) : soft, shape: BoxShape.circle), child: Icon(icon, color: warm ? orange : navy, size: 20 * s)),
        SizedBox(width: 10 * s),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: navy, fontSize: 12.5 * s, fontWeight: FontWeight.w800)), Text(subtitle, style: TextStyle(color: muted, fontSize: 9.3 * s))])),
        Switch(value: value, onChanged: onChanged, activeThumbColor: Colors.white, activeTrackColor: orange, inactiveThumbColor: Colors.white, inactiveTrackColor: const Color(0xFFDDDDEA)),
      ]),
    );
  }

  Widget _confirmation(double s) {
    return Padding(
      padding: EdgeInsets.fromLTRB(17 * s, 18 * s, 17 * s, 24 * s),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16 * s),
          decoration: _cardDecoration(s),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Gönderiyi Onayla', style: TextStyle(color: navy, fontSize: 18 * s, fontWeight: FontWeight.w900)),
            SizedBox(height: 14 * s),
            _summaryRow('Alım', widget.pickup.displayName, s),
            _summaryRow('Teslimat', widget.dropoff.displayName, s),
            _summaryRow('Paket', '$weight • $size', s),
            _summaryRow('Ödeme', widget.paymentIndex == 0 ? 'Nakit' : 'Kart', s),
          ]),
        ),
        SizedBox(height: 12 * s),
        _priceCard(s),
        SizedBox(height: 12 * s),
        _continueButton(creating ? 'Oluşturuluyor...' : 'Gönderiyi Oluştur', creating ? null : _createShipment, s),
      ]),
    );
  }

  Widget _summaryRow(String label, String value, double s) => Padding(
        padding: EdgeInsets.only(bottom: 10 * s),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 70 * s, child: Text(label, style: TextStyle(color: muted, fontSize: 10.5 * s))), Expanded(child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: navy, fontSize: 11 * s, fontWeight: FontWeight.w700)))]),
      );

  Widget _selectBox(String label, String value, IconData icon, VoidCallback onTap, double s) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13 * s),
      child: Container(
        height: 58 * s,
        padding: EdgeInsets.symmetric(horizontal: 11 * s),
        decoration: BoxDecoration(color: const Color(0xFFF5F5F9), borderRadius: BorderRadius.circular(13 * s)),
        child: Row(children: [
          Icon(icon, color: const Color(0xFF686684), size: 21 * s),
          SizedBox(width: 9 * s),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: muted, fontSize: 9.5 * s)), SizedBox(height: 2 * s), Text(value, style: TextStyle(color: navy, fontSize: 12 * s, fontWeight: FontWeight.w800))])),
          Icon(Icons.keyboard_arrow_down_rounded, color: navy, size: 18 * s),
        ]),
      ),
    );
  }

  Widget _textArea(TextEditingController controller, String hint, double s) {
    return TextField(
      controller: controller,
      maxLength: 200,
      maxLines: 3,
      style: TextStyle(color: navy, fontSize: 11 * s),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFFA5A3B2), fontSize: 10.5 * s),
        counterStyle: TextStyle(color: muted, fontSize: 9 * s),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.all(11 * s),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFE3E1EA))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: orange, width: 1.2)),
      ),
    );
  }

  Widget _priceCard(double s) {
    return Container(
      height: 64 * s,
      padding: EdgeInsets.symmetric(horizontal: 14 * s),
      decoration: _cardDecoration(s),
      child: Row(children: [
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('Tahmini Tutar', style: TextStyle(color: navy, fontSize: 10.5 * s, fontWeight: FontWeight.w600)), SizedBox(width: 5 * s), Icon(Icons.info_outline_rounded, color: navy, size: 14 * s)]),
          SizedBox(height: 2 * s),
          Text('₺${widget.quotedPrice}', style: TextStyle(color: orange, fontSize: 20 * s, fontWeight: FontWeight.w900)),
        ])),
        Text('${widget.distanceKm.toStringAsFixed(1)} km • ${widget.durationMin} dk', style: TextStyle(color: muted, fontSize: 9.5 * s)),
      ]),
    );
  }

  Widget _continueButton(String label, VoidCallback? onTap, double s) {
    return SizedBox(
      width: double.infinity,
      height: 52 * s,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(backgroundColor: orange, disabledBackgroundColor: orange.withValues(alpha: .55), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * s))),
        child: creating && confirmation
            ? SizedBox(width: 20 * s, height: 20 * s, child: const CircularProgressIndicator(strokeWidth: 2.3, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Text(label, style: TextStyle(color: Colors.white, fontSize: 15 * s, fontWeight: FontWeight.w800)), SizedBox(width: 10 * s), Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 21 * s)]),
      ),
    );
  }

  Widget _iconBubble(IconData icon, double s) => Container(width: 38 * s, height: 38 * s, decoration: const BoxDecoration(color: soft, shape: BoxShape.circle), child: Icon(icon, color: navy, size: 21 * s));

  BoxDecoration _cardDecoration(double s) => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17 * s), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))]);
}
