import 'package:flutter/material.dart';

class HomePixelPreview extends StatelessWidget {
  const HomePixelPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth.clamp(320.0, 460.0);
        final h = c.maxHeight;
        final sx = w / 390;
        final sy = h / 844;
        final s = sx < sy ? sx : sy;
        return Center(
          child: SizedBox(
            width: 390 * s,
            height: 844 * s,
            child: Column(children: [
              _hero(s),
              Transform.translate(offset: Offset(0,-8*s), child: Padding(padding: EdgeInsets.symmetric(horizontal:10*s), child:_vehicles(s))),
              Transform.translate(offset: Offset(0,-3*s), child: Padding(padding: EdgeInsets.symmetric(horizontal:10*s), child:_promo(s))),
              SizedBox(height:8*s),
              Padding(padding:EdgeInsets.symmetric(horizontal:12*s),child:_recent(s)),
              const Spacer(),
              Padding(padding:EdgeInsets.fromLTRB(10*s,0,10*s,8*s),child:_nav(s)),
            ]),
          ),
        );
      }),
    );
  }

  Widget _hero(double s)=>SizedBox(height:315*s,child:DecoratedBox(decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF58C5F5),Color(0xFF7DD8F8),Color(0xFFD9F7FF)])),child:Stack(children:[
    Positioned(left:18*s,top:22*s,child:Row(children:[Icon(Icons.location_on_rounded,color:Colors.white,size:26*s),SizedBox(width:7*s),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Text('İstanbul',style:TextStyle(fontSize:17*s,fontWeight:FontWeight.w800,color:const Color(0xFF0F438E))),Icon(Icons.keyboard_arrow_down_rounded,size:18*s,color:const Color(0xFF2A91DA))]),Text('Şişli, Mecidiyeköy',style:TextStyle(fontSize:11*s,color:const Color(0xFF245891)))])])),
    Positioned(right:17*s,top:20*s,child:CircleAvatar(radius:22*s,backgroundColor:Colors.white.withOpacity(.65),child:Image.asset('assets/images/3d_kurye.png',fit:BoxFit.contain))),
    Positioned(right:92*s,top:45*s,child:Opacity(opacity:.7,child:Icon(Icons.location_on_rounded,size:105*s,color:Colors.white))),
    Positioned(left:20*s,top:83*s,child:Text('Hızlı\nGüvenli\nTeslimat',style:TextStyle(height:.88,fontSize:29*s,fontWeight:FontWeight.w900,letterSpacing:-1.4*s,color:Colors.white,shadows:const [Shadow(color:Color(0x660A58C7),blurRadius:4,offset:Offset(0,3))]))),
    Positioned(left:20*s,top:190*s,child:Text('İhtiyacın ne olursa olsun\nyanındayız.',style:TextStyle(fontSize:12*s,height:1.4,color:Colors.white,fontWeight:FontWeight.w500))),
    Positioned(right:-2*s,top:68*s,width:205*s,height:190*s,child:Image.asset('assets/images/3d_kurye.png',fit:BoxFit.contain)),
    Positioned(left:18*s,right:18*s,bottom:18*s,child:Container(height:48*s,padding:EdgeInsets.symmetric(horizontal:10*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(26*s),boxShadow:const [BoxShadow(color:Color(0x18000000),blurRadius:15,offset:Offset(0,5))]),child:Row(children:[Container(width:36*s,height:36*s,decoration:const BoxDecoration(color:Color(0xFF178EF4),shape:BoxShape.circle),child:Icon(Icons.add_rounded,size:25*s,color:Colors.white)),SizedBox(width:10*s),Expanded(child:Text('Gönderi Oluştur',style:TextStyle(fontSize:16*s,fontWeight:FontWeight.w800,color:const Color(0xFF0E3E8E)))),Icon(Icons.chevron_right_rounded,size:25*s,color:const Color(0xFF178EF4))]))),
  ])));

  Widget _vehicles(double s)=>Container(height:160*s,padding:EdgeInsets.all(7*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(23*s),boxShadow:const [BoxShadow(color:Color(0x12000000),blurRadius:12,offset:Offset(0,4))]),child:Row(children:[Expanded(child:_vehicle(s,'Araç','Daha büyük gönderiler\niçin ideal','assets/images/arac.png')),SizedBox(width:7*s),Expanded(child:_vehicle(s,'Motosiklet','Hızlı ve pratik\nteslimat','assets/images/motosiklet.png'))]));

  Widget _vehicle(double s,String t,String sub,String asset)=>Container(padding:EdgeInsets.fromLTRB(9*s,5*s,8*s,8*s),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Colors.white,Color(0xFFF0F9FF)]),borderRadius:BorderRadius.circular(19*s)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Center(child:Image.asset(asset,fit:BoxFit.contain))),Text(t,style:TextStyle(fontSize:15*s,fontWeight:FontWeight.w900,color:const Color(0xFF11182A))),Row(children:[Expanded(child:Text(sub,style:TextStyle(fontSize:9.5*s,height:1.25,color:const Color(0xFF7A8390)))),Container(width:28*s,height:28*s,decoration:const BoxDecoration(color:Color(0xFFDDF3FF),shape:BoxShape.circle),child:Icon(Icons.chevron_right_rounded,color:const Color(0xFF178EF4),size:21*s))]) ]));

  Widget _promo(double s)=>Container(height:98*s,padding:EdgeInsets.fromLTRB(14*s,10*s,12*s,9*s),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18*s),gradient:const LinearGradient(colors:[Color(0xFF49B8F2),Color(0xFF58C8F8)])),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('İlk gönderinde',style:TextStyle(fontSize:13*s,color:Colors.white)),Text('%20 indirim!',style:TextStyle(fontSize:20*s,color:Colors.white,fontWeight:FontWeight.w900)),const Spacer(),Container(padding:EdgeInsets.symmetric(horizontal:9*s,vertical:5*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14*s)),child:Text('KOD: MERHABA20',style:TextStyle(fontSize:8.5*s,fontWeight:FontWeight.w900,color:const Color(0xFF0E3E8E))))])),Image.asset('assets/images/3d_kurye.png',width:90*s,height:90*s,fit:BoxFit.contain)]));

  Widget _recent(double s)=>Column(children:[Row(children:[Expanded(child:Text('Son Gönderilerim',style:TextStyle(fontSize:16*s,fontWeight:FontWeight.w900))),Text('Tümünü Gör',style:TextStyle(fontSize:10*s,color:const Color(0xFF178EF4),fontWeight:FontWeight.w700)),Icon(Icons.chevron_right_rounded,size:15*s,color:const Color(0xFF8C939B))]),SizedBox(height:6*s),Container(height:67*s,padding:EdgeInsets.all(8*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18*s)),child:Row(children:[CircleAvatar(radius:24*s,backgroundColor:const Color(0xFFF7F4EF),child:Icon(Icons.inventory_2_rounded,size:27*s,color:const Color(0xFFD69A50))),SizedBox(width:8*s),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('#12458',style:TextStyle(fontSize:10*s,fontWeight:FontWeight.w700)),Text('Şişli → Kadıköy',style:TextStyle(fontSize:12*s,fontWeight:FontWeight.w800)),Text('Teslim edildi',style:TextStyle(fontSize:9*s,color:const Color(0xFF7A8390)))])),Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text('Dün 14:32',style:TextStyle(fontSize:8*s,color:const Color(0xFF7A8390))),SizedBox(height:6*s),Container(padding:EdgeInsets.symmetric(horizontal:7*s,vertical:4*s),decoration:BoxDecoration(color:const Color(0xFFDDF8E4),borderRadius:BorderRadius.circular(12*s)),child:Text('✓ Tamamlandı',style:TextStyle(fontSize:8*s,color:const Color(0xFF11843A),fontWeight:FontWeight.w700)))])]))]);

  Widget _nav(double s)=>Container(height:61*s,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(25*s),boxShadow:const [BoxShadow(color:Color(0x19000000),blurRadius:16,offset:Offset(0,5))]),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[_n(s,Icons.home_rounded,'Ana Sayfa',true),_n(s,Icons.receipt_long_rounded,'Gönderilerim',false),_n(s,Icons.chat_bubble_outline_rounded,'Mesajlar',false),_n(s,Icons.person_outline_rounded,'Profilim',false)]));
  Widget _n(double s,IconData i,String t,bool a)=>Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(i,size:21*s,color:a?const Color(0xFF178EF4):const Color(0xFF7A8390)),Text(t,style:TextStyle(fontSize:8.5*s,fontWeight:a?FontWeight.w700:FontWeight.w500,color:a?const Color(0xFF178EF4):const Color(0xFF7A8390)))]);
}
