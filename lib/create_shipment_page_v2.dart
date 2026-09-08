import 'package:flutter/material.dart';
import 'courier_search_page.dart';

class CreateShipmentPage extends StatefulWidget {
  const CreateShipmentPage({super.key});
  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF7C879C);

  int vehicle = 0;
  int detail = 0;
  final pickupController = TextEditingController();
  final dropoffController = TextEditingController();

  bool get hasAddresses =>
      pickupController.text.trim().isNotEmpty &&
      dropoffController.text.trim().isNotEmpty;

  double get estimatedDistanceKm => vehicle == 0 ? 8.6 : 8.6;

  int get estimatedPrice {
    final base = vehicle == 0 ? 65.0 : 95.0;
    final perKm = vehicle == 0 ? 10.0 : 14.0;
    return (base + (estimatedDistanceKm * perKm)).round();
  }

  @override
  void dispose() {
    pickupController.dispose();
    dropoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final s = c.maxWidth / 390;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16*s,14*s,16*s,24*s),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _round(s, Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
                SizedBox(width:14*s),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Text('Gönderi Oluştur',style:TextStyle(fontSize:25*s,fontWeight:FontWeight.w900,color:navy)),
                  Text('Hızlı, güvenli ve kolay',style:TextStyle(fontSize:14*s,color:muted)),
                ])),
                _round(s, Icons.help_outline_rounded, (){}),
              ]),
              SizedBox(height:16*s),
              Container(height:70*s,decoration:BoxDecoration(color:const Color(0xFFE9F4FF),borderRadius:BorderRadius.circular(18*s)),child:Stack(children:[
                Positioned(left:12*s,top:15*s,child:Container(width:40*s,height:40*s,decoration:BoxDecoration(color:blue,borderRadius:BorderRadius.circular(13*s)),child:Icon(Icons.bolt_rounded,color:Colors.white,size:27*s))),
                Positioned(left:63*s,top:14*s,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Dakikalar içinde kurye yola çıksın!',style:TextStyle(fontSize:12*s,fontWeight:FontWeight.w800,color:const Color(0xFF163C80))),SizedBox(height:4*s),Text('İhtiyacın ne olursa olsun yanındayız.',style:TextStyle(fontSize:10.5*s,color:const Color(0xFF31578D)))])),
                Positioned(right:-3*s,bottom:-5*s,width:135*s,height:88*s,child:Image.asset('assets/images/kurye_header_hd.png',fit:BoxFit.contain,alignment:Alignment.bottomRight,filterQuality:FilterQuality.high)),
              ])),
              SizedBox(height:20*s),
              Row(children:[Expanded(child:Text('Taşıma Türü',style:TextStyle(fontSize:19*s,fontWeight:FontWeight.w900,color:navy))),Text('Hangisini seçmeliyim?',style:TextStyle(fontSize:11*s,color:blue)),Icon(Icons.chevron_right_rounded,color:blue,size:18*s)]),
              SizedBox(height:10*s),
              Row(children:[
                Expanded(child:_vehicle(s,0,'Motosiklet','Hızlı ve pratik','Genellikle 10–30 dk','assets/images/motosiklet_hd.png')),
                SizedBox(width:10*s),
                Expanded(child:_vehicle(s,1,'Araç','Daha büyük gönderiler','Genellikle 20–60 dk','assets/images/arac_hd.png')),
              ]),
              SizedBox(height:16*s),
              _card(s, Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[Expanded(child:Text('Adres Bilgileri',style:TextStyle(fontSize:18*s,fontWeight:FontWeight.w900,color:navy))),Icon(Icons.map_outlined,color:blue,size:19*s),SizedBox(width:5*s),Text('Haritadan Seç',style:TextStyle(fontSize:11.5*s,color:blue,fontWeight:FontWeight.w700))]),
                SizedBox(height:14*s),
                _addressField(s,'Alım Adresi','Alım adresini gir',pickupController,Icons.trip_origin_rounded),
                SizedBox(height:10*s),
                _addressField(s,'Teslimat Adresi','Teslimat adresini gir',dropoffController,Icons.location_on_rounded),
                SizedBox(height:10*s),
                Container(height:43*s,padding:EdgeInsets.symmetric(horizontal:12*s),decoration:BoxDecoration(color:const Color(0xFFF1F5FA),borderRadius:BorderRadius.circular(14*s)),child:Row(children:[Container(width:26*s,height:26*s,decoration:const BoxDecoration(color:Color(0xFF6EB5FF),shape:BoxShape.circle),child:Icon(Icons.add_rounded,color:Colors.white,size:19*s)),SizedBox(width:10*s),Text('Ara durak ekle (isteğe bağlı)',style:TextStyle(fontSize:11.5*s,color:const Color(0xFF64748B),fontWeight:FontWeight.w600))]))
              ])),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: hasAddresses ? Padding(
                  key: const ValueKey('price'),
                  padding: EdgeInsets.only(top:16*s),
                  child: _priceCard(s),
                ) : const SizedBox.shrink(key: ValueKey('empty')),
              ),
              SizedBox(height:16*s),
              _card(s, Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('Gönderi Detayları',style:TextStyle(fontSize:18*s,fontWeight:FontWeight.w900,color:navy)),SizedBox(height:12*s),
                Row(children:[Expanded(child:_chip(s,0,Icons.inventory_2_outlined,'Paket')),SizedBox(width:7*s),Expanded(child:_chip(s,1,Icons.restaurant_rounded,'Yiyecek')),SizedBox(width:7*s),Expanded(child:_chip(s,2,Icons.description_outlined,'Belge')),SizedBox(width:7*s),Expanded(child:_chip(s,3,Icons.grid_view_rounded,'Diğer'))]),
                SizedBox(height:10*s),
                Row(children:[Expanded(child:_select(s,Icons.scale_outlined,'Tahmini Ağırlık')),SizedBox(width:10*s),Expanded(child:_select(s,Icons.inventory_2_outlined,'Tahmini Boyut'))]),
                SizedBox(height:10*s),
                Container(height:64*s,padding:EdgeInsets.symmetric(horizontal:12*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15*s),border:Border.all(color:const Color(0xFFE7ECF3))),child:Row(children:[Icon(Icons.chat_bubble_outline_rounded,color:const Color(0xFF65748A),size:20*s),SizedBox(width:10*s),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Ek Not (isteğe bağlı)',style:TextStyle(fontSize:11*s,color:const Color(0xFF64748B),fontWeight:FontWeight.w600)),Text('Örn: Dikkatli taşınsın, kapıya bırakın, arayın...',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:9.5*s,color:const Color(0xFFA0A9B9))) ]))]))
              ])),
              SizedBox(height:16*s),
              SizedBox(width:double.infinity,height:58*s,child:ElevatedButton.icon(
                onPressed: hasAddresses ? (){Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourierSearchPage()));} : null,
                icon:Icon(Icons.send_rounded,color:Colors.white,size:22*s),
                label:Text(hasAddresses ? 'Gönderi Oluştur • ₺$estimatedPrice' : 'Adresleri Gir',style:TextStyle(fontSize:17*s,fontWeight:FontWeight.w800)),
                style:ElevatedButton.styleFrom(backgroundColor:blue,disabledBackgroundColor:const Color(0xFFB7C7D8),foregroundColor:Colors.white,disabledForegroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20*s)),elevation:0)
              )),
            ]),
          );
        }),
      ),
    );
  }

  Widget _priceCard(double s) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(15*s),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors:[Color(0xFF168CF5),Color(0xFF3AA7FF)]),
      borderRadius: BorderRadius.circular(22*s),
      boxShadow: const [BoxShadow(color:Color(0x25168CF5),blurRadius:18,offset:Offset(0,7))],
    ),
    child: Row(children:[
      Container(width:46*s,height:46*s,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.18),shape:BoxShape.circle),child:Icon(Icons.payments_rounded,color:Colors.white,size:24*s)),
      SizedBox(width:12*s),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Tahmini Ücret',style:TextStyle(fontSize:12*s,color:Colors.white.withValues(alpha:.86),fontWeight:FontWeight.w700)),
        Text('₺$estimatedPrice',style:TextStyle(fontSize:27*s,color:Colors.white,fontWeight:FontWeight.w900)),
        Text('${estimatedDistanceKm.toStringAsFixed(1)} km • yaklaşık ${vehicle == 0 ? 22 : 28} dk',style:TextStyle(fontSize:10.5*s,color:Colors.white.withValues(alpha:.82),fontWeight:FontWeight.w600)),
      ])),
      Container(padding:EdgeInsets.symmetric(horizontal:10*s,vertical:7*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14*s)),child:Text(vehicle==0?'Motosiklet':'Araç',style:TextStyle(fontSize:10*s,color:blue,fontWeight:FontWeight.w900))),
    ]),
  );

  Widget _addressField(double s,String title,String hint,TextEditingController controller,IconData icon)=>Container(
    padding: EdgeInsets.symmetric(horizontal:11*s),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15*s),border:Border.all(color:const Color(0xFFE7ECF3))),
    child:Row(children:[
      Container(width:32*s,height:32*s,decoration:const BoxDecoration(color:Color(0xFFF2F6FA),shape:BoxShape.circle),child:Icon(icon,color:const Color(0xFF64748B),size:20*s)),
      SizedBox(width:10*s),
      Expanded(child:TextField(
        controller:controller,
        onChanged:(_)=>setState((){}),
        decoration:InputDecoration(border:InputBorder.none,labelText:title,hintText:hint,labelStyle:TextStyle(fontSize:11*s,color:muted,fontWeight:FontWeight.w700),hintStyle:TextStyle(fontSize:10.5*s,color:const Color(0xFFA0A9B9))),
        style:TextStyle(fontSize:12*s,color:navy,fontWeight:FontWeight.w700),
      )),
      Icon(Icons.chevron_right_rounded,color:const Color(0xFF69778B),size:21*s)
    ])
  );

  Widget _round(double s,IconData i,VoidCallback f)=>InkWell(onTap:f,borderRadius:BorderRadius.circular(18*s),child:Container(width:44*s,height:44*s,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(17*s),boxShadow:const [BoxShadow(color:Color(0x12000000),blurRadius:15,offset:Offset(0,5))]),child:Icon(i,color:const Color(0xFF173C84),size:25*s)));
  Widget _vehicle(double s,int idx,String t,String sub,String time,String asset){final sel=vehicle==idx;return GestureDetector(onTap:()=>setState(()=>vehicle=idx),child:Container(height:168*s,padding:EdgeInsets.all(10*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20*s),border:Border.all(color:sel?blue:const Color(0xFFE7EDF5),width:sel?1.5:1)),child:Stack(children:[Positioned(right:0,top:0,child:Container(width:24*s,height:24*s,decoration:BoxDecoration(color:sel?blue:Colors.white,shape:BoxShape.circle,border:Border.all(color:sel?blue:const Color(0xFFD2DAE6))),child:sel?Icon(Icons.check_rounded,color:Colors.white,size:17*s):null)),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Center(child:Image.asset(asset,fit:BoxFit.contain))),Text(t,style:TextStyle(fontSize:16*s,fontWeight:FontWeight.w900,color:navy)),Text(sub,style:TextStyle(fontSize:11*s,color:muted)),SizedBox(height:6*s),Container(padding:EdgeInsets.symmetric(horizontal:9*s,vertical:5*s),decoration:BoxDecoration(color:const Color(0xFFEAF4FF),borderRadius:BorderRadius.circular(14*s)),child:Text(time,style:TextStyle(fontSize:9.5*s,color:blue,fontWeight:FontWeight.w700)))])])));}
  Widget _card(double s,Widget child)=>Container(width:double.infinity,padding:EdgeInsets.all(12*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22*s),boxShadow:const [BoxShadow(color:Color(0x0D000000),blurRadius:18,offset:Offset(0,5))]),child:child);
  Widget _chip(double s,int idx,IconData i,String label){final sel=detail==idx;return GestureDetector(onTap:()=>setState(()=>detail=idx),child:Container(height:48*s,decoration:BoxDecoration(color:sel?const Color(0xFFF3F9FF):Colors.white,borderRadius:BorderRadius.circular(14*s),border:Border.all(color:sel?blue:const Color(0xFFE5EAF2))),child:Center(child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(i,color:sel?blue:const Color(0xFF607089),size:18*s),SizedBox(width:5*s),Text(label,style:TextStyle(fontSize:10*s,color:sel?blue:const Color(0xFF607089),fontWeight:FontWeight.w700))]))));}
  Widget _select(double s,IconData i,String title)=>Container(height:58*s,padding:EdgeInsets.symmetric(horizontal:10*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15*s),border:Border.all(color:const Color(0xFFE7ECF3))),child:Row(children:[Icon(i,color:const Color(0xFF65748A),size:18*s),SizedBox(width:8*s),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(fontSize:9.4*s,color:const Color(0xFF64748B))),Text('Seçiniz',style:TextStyle(fontSize:10.5*s,color:const Color(0xFF9AA4B5)))])),Icon(Icons.keyboard_arrow_down_rounded,color:const Color(0xFF56657B),size:20*s)]));
}
