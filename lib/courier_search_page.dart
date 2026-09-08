import 'package:flutter/material.dart';

class CourierSearchPage extends StatelessWidget {
  const CourierSearchPage({super.key});

  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF758198);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final s = c.maxWidth / 390;
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 20*s),
            child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16*s, 14*s, 16*s, 0),
                child: Column(children: [
                  Row(children: [
                    _round(s, Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
                    const Spacer(),
                  ]),
                  SizedBox(height: 8*s),
                  SizedBox(
                    height: 165*s,
                    child: Stack(children: [
                      Positioned(left: 0, top: 18*s, right: 125*s, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Gönderin oluşturuldu!', style: TextStyle(fontSize: 27*s, height: 1.05, fontWeight: FontWeight.w900, color: navy)),
                        SizedBox(height: 5*s),
                        Text('Sana en uygun kurye aranıyor...', style: TextStyle(fontSize: 18*s, fontWeight: FontWeight.w800, color: blue)),
                        SizedBox(height: 8*s),
                        Text('Yakındaki kuryelere bildirildi.\nEn kısa sürede bir kurye kabul edecek.', style: TextStyle(fontSize: 12*s, height: 1.45, color: muted, fontWeight: FontWeight.w500)),
                      ])),
                      Positioned(right: -4*s, bottom: -5*s, width: 145*s, height: 160*s, child: Image.asset('assets/images/kurye_header_hd.png', fit: BoxFit.contain, alignment: Alignment.bottomRight)),
                    ]),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12*s),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19*s), boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 15, offset: Offset(0, 5))]),
                    child: Row(children: [
                      Expanded(child: _feature(s, Icons.bolt_rounded, 'Hızlı\nEşleşme')),
                      _vline(s),
                      Expanded(child: _feature(s, Icons.shield_outlined, 'Güvenli\nTeslimat')),
                      _vline(s),
                      Expanded(child: _feature(s, Icons.location_on_rounded, 'Canlı\nTakip')),
                    ]),
                  ),
                ]),
              ),
              SizedBox(height: 14*s),
              _map(s),
              SizedBox(height: 14*s),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16*s), child: _details(s)),
              SizedBox(height: 12*s),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16*s),
                child: Row(children: [
                  Expanded(child: _action(s, Icons.close_rounded, 'Gönderiyi İptal Et', const Color(0xFFFFEEF0), const Color(0xFFFF3450))),
                  SizedBox(width: 10*s),
                  Expanded(child: _action(s, Icons.list_alt_rounded, 'Detayları Gör', const Color(0xFFEAF4FF), blue)),
                ]),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _round(double s, IconData i, VoidCallback f) => InkWell(onTap: f, borderRadius: BorderRadius.circular(18*s), child: Container(width: 44*s, height: 44*s, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17*s), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 15, offset: Offset(0, 5))]), child: Icon(i, color: const Color(0xFF173C84), size: 25*s)));

  Widget _feature(double s, IconData i, String t) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 34*s, height: 34*s, decoration: const BoxDecoration(color: Color(0xFFEAF4FF), shape: BoxShape.circle), child: Icon(i, color: blue, size: 20*s)), SizedBox(width: 7*s), Text(t, style: TextStyle(fontSize: 10.5*s, height: 1.2, color: const Color(0xFF40506A), fontWeight: FontWeight.w700))]);
  Widget _vline(double s) => Container(width: 1, height: 32*s, color: const Color(0xFFE6ECF4));

  Widget _map(double s) => Container(
    height: 330*s,
    width: double.infinity,
    decoration: const BoxDecoration(color: Color(0xFFEAF3FA)),
    child: Stack(children: [
      ...List.generate(8, (i) => Positioned(left: ((i*57)%360)*s-20*s, top: (25+i*37)*s, child: Transform.rotate(angle: i.isEven ? .25 : -.35, child: Container(width: 160*s, height: 2*s, color: const Color(0xFFFFFFFF))))),
      Positioned(left: 95*s, top: 112*s, child: _radar(s)),
      Positioned(left: 20*s, top: 34*s, child: Text('Şişli', style: TextStyle(fontSize: 14*s, fontWeight: FontWeight.w700, color: const Color(0xFF53627A)))),
      Positioned(left: 145*s, top: 78*s, child: Text('Mecidiyeköy', style: TextStyle(fontSize: 13*s, fontWeight: FontWeight.w700, color: const Color(0xFF53627A)))),
      Positioned(right: 18*s, bottom: 30*s, child: Text('Beşiktaş', style: TextStyle(fontSize: 13*s, fontWeight: FontWeight.w700, color: const Color(0xFF53627A)))),
      Positioned(left: 18*s, top: 85*s, child: _courier(s)),
      Positioned(right: 34*s, top: 38*s, child: _courier(s)),
      Positioned(right: 45*s, bottom: 72*s, child: _courier(s)),
      Positioned(left: 112*s, top: 35*s, child: Container(padding: EdgeInsets.symmetric(horizontal: 13*s, vertical: 9*s), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15*s), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 12)]), child: Row(children:[Icon(Icons.radar_rounded,color:blue,size:20*s),SizedBox(width:7*s),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Kuryeler bölgede',style:TextStyle(fontSize:10.5*s,fontWeight:FontWeight.w800,color:navy)),Text('3 kurye yakınında',style:TextStyle(fontSize:9.5*s,color:muted))])]))),
    ]),
  );

  Widget _radar(double s) => Stack(alignment: Alignment.center, children: [Container(width: 190*s, height: 190*s, decoration: BoxDecoration(shape: BoxShape.circle, color: blue.withValues(alpha: .08))), Container(width: 135*s, height: 135*s, decoration: BoxDecoration(shape: BoxShape.circle, color: blue.withValues(alpha: .12))), Container(width: 80*s, height: 80*s, decoration: BoxDecoration(shape: BoxShape.circle, color: blue.withValues(alpha: .18))), Container(width: 52*s, height: 52*s, decoration: const BoxDecoration(shape: BoxShape.circle, color: blue), child: Icon(Icons.location_on_rounded, color: Colors.white, size: 30*s))]);

  Widget _courier(double s) => Container(width: 58*s, height: 58*s, padding: EdgeInsets.all(5*s), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB9DAFF), width: 2)), child: Image.asset('assets/images/motosiklet_hd.png', fit: BoxFit.contain));

  Widget _details(double s) => Container(
    padding: EdgeInsets.all(14*s),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24*s), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 5))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children:[Expanded(child:Text('Gönderi Detayları',style:TextStyle(fontSize:20*s,fontWeight:FontWeight.w900,color:navy))),Text('#12458',style:TextStyle(fontSize:12*s,color:muted,fontWeight:FontWeight.w700))]),
      SizedBox(height:12*s),
      Container(padding:EdgeInsets.all(12*s),decoration:BoxDecoration(color:const Color(0xFFF7FAFD),borderRadius:BorderRadius.circular(16*s)),child:Row(children:[Container(width:42*s,height:42*s,decoration:const BoxDecoration(color:Color(0xFFEAF4FF),shape:BoxShape.circle),child:Icon(Icons.inventory_2_rounded,color:blue,size:22*s)),SizedBox(width:10*s),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Paket',style:TextStyle(fontSize:14*s,fontWeight:FontWeight.w800,color:navy)),Text('Tahmini 0–5 kg',style:TextStyle(fontSize:11*s,color:muted))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text('Tahmini Ücret',style:TextStyle(fontSize:9.5*s,color:muted)),Text('₺120 – 150',style:TextStyle(fontSize:16*s,fontWeight:FontWeight.w900,color:blue))])])),
      SizedBox(height:14*s),
      _addressRow(s, blue, 'Alım Adresi', 'Şişli, Mecidiyeköy', '2.3 km'),
      SizedBox(height:12*s),
      _addressRow(s, const Color(0xFF12CC8A), 'Teslimat Adresi', 'Kadıköy, İstanbul', '12.8 km'),
    ]),
  );

  Widget _addressRow(double s, Color color, String title, String sub, String km) => Row(children:[Container(width:32*s,height:32*s,decoration:BoxDecoration(color:color.withValues(alpha:.12),shape:BoxShape.circle),child:Icon(Icons.location_on_rounded,color:color,size:19*s)),SizedBox(width:10*s),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(fontSize:11*s,color:muted,fontWeight:FontWeight.w600)),Text(sub,style:TextStyle(fontSize:13*s,color:navy,fontWeight:FontWeight.w800))])),Text(km,style:TextStyle(fontSize:11*s,color:navy,fontWeight:FontWeight.w700))]);

  Widget _action(double s, IconData i, String t, Color bg, Color fg) => Container(height:52*s,decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(18*s)),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(i,color:fg,size:21*s),SizedBox(width:7*s),Flexible(child:Text(t,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:12*s,color:fg,fontWeight:FontWeight.w800)))]));
}
