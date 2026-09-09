import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/app_data_service.dart';

class CourierActiveJobRealtimePage extends StatefulWidget {
  final String shipmentId;
  final String pickup;
  final String dropoff;
  final int earning;
  const CourierActiveJobRealtimePage({super.key,required this.shipmentId,required this.pickup,required this.dropoff,required this.earning});
  @override State<CourierActiveJobRealtimePage> createState()=>_CourierActiveJobRealtimePageState();
}

class _CourierActiveJobRealtimePageState extends State<CourierActiveJobRealtimePage>{
  static const blue=Color(0xFF168CF5), navy=Color(0xFF10213E), muted=Color(0xFF718198), green=Color(0xFF10B866);
  bool busy=false;

  int stepFor(String status)=>switch(status){'accepted'=>0,'at_pickup'=>1,'picked_up'=>2,'at_dropoff'=>3,'delivered'=>4,_=>0};
  String labelFor(String status)=>switch(status){'accepted'=>'Alım Noktasına Git','at_pickup'=>'Teslim Aldım','picked_up'=>'Teslimat Adresine Git','at_dropoff'=>'Teslim Ettim','delivered'=>'Teslim Edildi',_=>'Devam Et'};

  Future<void> openNavigation(String address) async {
    final uri=Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}&travelmode=driving');
    await launchUrl(uri,mode:LaunchMode.externalApplication);
  }

  Future<void> advance(String status) async {
    if(busy||status=='delivered')return;
    if(status=='accepted'){
      await openNavigation(widget.pickup);
      if(!mounted)return;
      final ok=await confirm('Alım noktasına vardın mı?','Vardım');
      if(ok) await change('at_pickup');
      return;
    }
    if(status=='at_pickup'){ await change('picked_up'); return; }
    if(status=='picked_up'){
      await openNavigation(widget.dropoff);
      if(!mounted)return;
      final ok=await confirm('Teslimat noktasına vardın mı?','Vardım');
      if(ok) await change('at_dropoff');
      return;
    }
    if(status=='at_dropoff'){
      final ok=await confirm('Gönderiyi müşteriye teslim ettin mi?','Teslim Ettim');
      if(ok){ await change('delivered'); if(mounted) await showDialog<void>(context:context,builder:(d)=>AlertDialog(title:const Text('Teslimat tamamlandı'),content:Text('₺${widget.earning} kazanç olarak işlendi.'),actions:[FilledButton(onPressed:()=>Navigator.pop(d),child:const Text('Tamam'))])); }
    }
  }

  Future<bool> confirm(String title,String action) async => await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:Text(title),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Vazgeç')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:Text(action))]))??false;

  Future<void> change(String next) async {
    setState(()=>busy=true);
    try{ await AppDataService.instance.updateShipmentStatus(widget.shipmentId,next); }
    catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Bad state: ','')))); }
    finally{ if(mounted)setState(()=>busy=false); }
  }

  @override Widget build(BuildContext context)=>StreamBuilder<Map<String,dynamic>>(
    stream:AppDataService.instance.watchShipment(widget.shipmentId),
    builder:(context,snapshot){
      final row=snapshot.data??const <String,dynamic>{};
      final status=(row['status']??'accepted').toString();
      final step=stepFor(status);
      final pickup=(row['pickup_address']??widget.pickup).toString();
      final dropoff=(row['dropoff_address']??widget.dropoff).toString();
      final code=(row['public_code']??'Aktif İş').toString();
      return Scaffold(
        backgroundColor:const Color(0xFFF5FAFF),
        appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,title:Text(code,style:const TextStyle(color:navy,fontWeight:FontWeight.w900))),
        body:ListView(padding:const EdgeInsets.all(18),children:[
          Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF168CF5),Color(0xFF55CFFF)]),borderRadius:BorderRadius.circular(26)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('İşin Aktif!',style:TextStyle(color:Colors.white,fontSize:30,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Durum değişiklikleri müşteriye anında yansır.',style:TextStyle(color:Colors.white))])),
          const SizedBox(height:18),
          _progress(step),
          const SizedBox(height:18),
          _addressCard('Alım Noktası',pickup,blue,status=='accepted'||status=='at_pickup'),
          const SizedBox(height:12),
          _addressCard('Teslimat Adresi',dropoff,const Color(0xFFFF4757),status=='picked_up'||status=='at_dropoff'),
          const SizedBox(height:16),
          Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),child:Row(children:[const Icon(Icons.payments_rounded,color:green),const SizedBox(width:10),const Expanded(child:Text('Kurye Kazancı',style:TextStyle(color:muted))),Text('₺${widget.earning}',style:const TextStyle(color:green,fontSize:23,fontWeight:FontWeight.w900))])),
        ]),
        bottomNavigationBar:SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(18,8,18,14),child:FilledButton.icon(onPressed:status=='delivered'||busy?null:()=>advance(status),icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Icon(status=='at_pickup'||status=='at_dropoff'?Icons.check_circle_rounded:Icons.navigation_rounded),label:Text(labelFor(status)),style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(58),backgroundColor:status=='at_pickup'||status=='at_dropoff'?green:blue,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(28)),textStyle:const TextStyle(fontSize:16,fontWeight:FontWeight.w900))))),
      );
    },
  );

  Widget _progress(int step){
    const labels=['İşi Aldı','Alımda','Teslim Aldı','Teslimatta','Teslim Edildi'];
    return Row(children:[for(int i=0;i<labels.length;i++)...[
      Expanded(child:Column(children:[CircleAvatar(radius:15,backgroundColor:i<=step?blue:const Color(0xFFDDE8F4),child:i<=step?const Icon(Icons.check,color:Colors.white,size:17):null),const SizedBox(height:5),Text(labels[i],textAlign:TextAlign.center,style:TextStyle(fontSize:8.5,color:i<=step?blue:muted,fontWeight:i<=step?FontWeight.w800:FontWeight.w500))])),
      if(i<labels.length-1)Container(width:10,height:2,color:i<step?blue:const Color(0xFFDDE8F4))
    ]]);
  }

  Widget _addressCard(String title,String address,Color color,bool active)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:active?Border.all(color:color.withValues(alpha:.35)):null),child:Row(children:[CircleAvatar(backgroundColor:color.withValues(alpha:.12),child:Icon(Icons.location_on_rounded,color:color)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:navy,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(address,style:const TextStyle(color:muted,fontSize:12))])),IconButton(onPressed:()=>openNavigation(address),icon:const Icon(Icons.navigation_rounded,color:blue))]));
}
