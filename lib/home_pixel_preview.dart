import 'package:flutter/material.dart';

class HomePixelPreview extends StatelessWidget {
  const HomePixelPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final s = w / 390;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _hero(s),
                    Transform.translate(
                      offset: Offset(0, -10 * s),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12 * s),
                        child: Column(
                          children: [
                            _vehicles(s),
                            SizedBox(height: 10 * s),
                            _promo(s),
                            SizedBox(height: 20 * s),
                            _recent(s),
                            SizedBox(height: 88 * s),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 20, offset: Offset(0, 6))],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(Icons.home_rounded, 'Ana Sayfa', true),
              _NavItem(Icons.receipt_long_rounded, 'Gönderilerim', false),
              _NavItem(Icons.chat_bubble_outline_rounded, 'Mesajlar', false),
              _NavItem(Icons.person_outline_rounded, 'Profilim', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(double s) {
    return Container(
      height: 610 * s,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF58C5F5), Color(0xFF7DD8F8), Color(0xFFD9F7FF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(left: 18*s, top: 35*s, child: Row(children:[
            Icon(Icons.location_on_rounded, color: Colors.white, size: 28*s),
            SizedBox(width: 8*s),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Row(children:[Text('İstanbul', style: TextStyle(fontSize: 20*s,fontWeight:FontWeight.w800,color:const Color(0xFF0F438E))), SizedBox(width:4*s), Icon(Icons.keyboard_arrow_down_rounded,size:20*s,color:const Color(0xFF2A91DA))]),
              Text('Şişli, Mecidiyeköy', style: TextStyle(fontSize: 13*s,color:const Color(0xFF245891))),
            ])
          ])),
          Positioned(right: 18*s, top: 34*s, child: Stack(children:[
            Container(width:48*s,height:48*s,decoration:BoxDecoration(color:Colors.white.withOpacity(.72),shape:BoxShape.circle),child:Icon(Icons.person_rounded,size:26*s,color:const Color(0xFF178EF4))),
            Positioned(right:-2*s,top:-2*s,child:Container(width:17*s,height:17*s,decoration:const BoxDecoration(color:Color(0xFFFF5147),shape:BoxShape.circle),alignment:Alignment.center,child:Text('1',style:TextStyle(fontSize:10*s,color:Colors.white,fontWeight:FontWeight.w800))))
          ])),
          Positioned(right: 48*s, top: 64*s, child: Opacity(opacity:.72,child:Icon(Icons.location_on_rounded,size:150*s,color:Colors.white))),
          Positioned(left: 20*s, top: 122*s, child: Text('Hızlı\nGüvenli\nTeslimat', style: TextStyle(height:.88,fontSize:42*s,fontWeight:FontWeight.w900,letterSpacing:-2*s,color:Colors.white,shadows:const [Shadow(color:Color(0x550A58C7),blurRadius:4,offset:Offset(0,4))]))),
          Positioned(left:20*s,top:295*s,child:Text('İhtiyacın ne olursa olsun\nyanındayız.',style:TextStyle(fontSize:16*s,height:1.45,color:Colors.white,fontWeight:FontWeight.w500))),
          Positioned(right:4*s,top:115*s,child:Container(width:190*s,height:270*s,alignment:Alignment.center,child:Icon(Icons.delivery_dining_rounded,size:145*s,color:const Color(0xFF126BEA)))),
          Positioned(left:18*s,right:18*s,bottom:32*s,child:Container(height:70*s,padding:EdgeInsets.symmetric(horizontal:16*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(35*s),boxShadow:const [BoxShadow(color:Color(0x19000000),blurRadius:20,offset:Offset(0,7))]),child:Row(children:[Container(width:50*s,height:50*s,decoration:const BoxDecoration(color:Color(0xFF178EF4),shape:BoxShape.circle),child:Icon(Icons.add_rounded,size:31*s,color:Colors.white)),SizedBox(width:14*s),Expanded(child:Text('Gönderi Oluştur',style:TextStyle(fontSize:20*s,fontWeight:FontWeight.w800,color:const Color(0xFF0E3E8E)))),Icon(Icons.chevron_right_rounded,size:30*s,color:const Color(0xFF178EF4))]))),
        ],
      ),
    );
  }

  Widget _vehicles(double s) => Container(
    padding: EdgeInsets.all(9*s),
    decoration: BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(27*s),boxShadow:const [BoxShadow(color:Color(0x13000000),blurRadius:15,offset:Offset(0,6))]),
    child: Row(children:[Expanded(child:_vehicle(s,'Araç','Daha büyük gönderiler\niçin ideal',Icons.directions_car_filled_rounded)),SizedBox(width:8*s),Expanded(child:_vehicle(s,'Motosiklet','Hızlı ve pratik\nteslimat',Icons.two_wheeler_rounded))]),
  );

  Widget _vehicle(double s,String t,String sub,IconData icon)=>Container(
    height:230*s,padding:EdgeInsets.all(12*s),
    decoration:BoxDecoration(gradient:const LinearGradient(colors:[Colors.white,Color(0xFFF0F9FF)],begin:Alignment.topLeft,end:Alignment.bottomRight),borderRadius:BorderRadius.circular(24*s)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Center(child:Icon(icon,size:95*s,color:const Color(0xFF238EF2)))),Text(t,style:TextStyle(fontSize:20*s,fontWeight:FontWeight.w900,color:const Color(0xFF11182A))),SizedBox(height:3*s),Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:Text(sub,style:TextStyle(fontSize:13*s,height:1.3,color:const Color(0xFF7A8390)))),Container(width:38*s,height:38*s,decoration:const BoxDecoration(color:Color(0xFFDDF3FF),shape:BoxShape.circle),child:Icon(Icons.chevron_right_rounded,color:const Color(0xFF178EF4),size:27*s))])]),
  );

  Widget _promo(double s)=>Container(height:150*s,padding:EdgeInsets.fromLTRB(20*s,16*s,16*s,14*s),decoration:BoxDecoration(borderRadius:BorderRadius.circular(24*s),gradient:const LinearGradient(colors:[Color(0xFF49B8F2),Color(0xFF58C8F8)])),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('İlk gönderinde',style:TextStyle(fontSize:20*s,color:Colors.white,fontWeight:FontWeight.w500)),Text('%20 indirim!',style:TextStyle(fontSize:29*s,color:Colors.white,fontWeight:FontWeight.w900)),const Spacer(),Container(padding:EdgeInsets.symmetric(horizontal:13*s,vertical:8*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20*s)),child:Text('KOD: MERHABA20',style:TextStyle(fontSize:12*s,fontWeight:FontWeight.w900,color:const Color(0xFF0E3E8E))))])),SizedBox(width:10*s),Icon(Icons.card_giftcard_rounded,size:105*s,color:Colors.white)]));

  Widget _recent(double s)=>Column(children:[Row(children:[Expanded(child:Text('Son Gönderilerim',style:TextStyle(fontSize:22*s,fontWeight:FontWeight.w900))),Text('Tümünü Gör',style:TextStyle(fontSize:14*s,color:const Color(0xFF178EF4),fontWeight:FontWeight.w700)),Icon(Icons.chevron_right_rounded,size:20*s,color:const Color(0xFF8C939B))]),SizedBox(height:10*s),Container(padding:EdgeInsets.all(14*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(26*s)),child:Row(children:[Container(width:58*s,height:58*s,decoration:const BoxDecoration(color:Color(0xFFF7F4EF),shape:BoxShape.circle),child:Icon(Icons.inventory_2_rounded,size:34*s,color:const Color(0xFFD69A50))),SizedBox(width:12*s),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('#12458',style:TextStyle(fontSize:15*s,fontWeight:FontWeight.w700,color:const Color(0xFF404756))),Text('Şişli → Kadıköy',style:TextStyle(fontSize:16*s,fontWeight:FontWeight.w800)),Text('Teslim edildi',style:TextStyle(fontSize:13*s,color:const Color(0xFF7A8390)))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text('Dün 14:32',style:TextStyle(fontSize:12*s,color:const Color(0xFF7A8390))),SizedBox(height:12*s),Container(padding:EdgeInsets.symmetric(horizontal:10*s,vertical:7*s),decoration:BoxDecoration(color:const Color(0xFFDDF8E4),borderRadius:BorderRadius.circular(18*s)),child:Row(children:[Icon(Icons.check_circle_rounded,size:18*s,color:const Color(0xFF12A64A)),SizedBox(width:5*s),Text('Tamamlandı',style:TextStyle(fontSize:12*s,color:const Color(0xFF11843A),fontWeight:FontWeight.w700))]))])]))]);
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool active;
  const _NavItem(this.icon,this.label,this.active);
  @override Widget build(BuildContext context)=>Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:28,color:active?const Color(0xFF178EF4):const Color(0xFF7A8390)),const SizedBox(height:3),Text(label,style:TextStyle(fontSize:12,fontWeight:active?FontWeight.w700:FontWeight.w500,color:active?const Color(0xFF178EF4):const Color(0xFF7A8390)))]);
}
