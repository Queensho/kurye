import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class CourierEarningsPage extends StatefulWidget {
  const CourierEarningsPage({super.key});
  @override State<CourierEarningsPage> createState()=>_CourierEarningsPageState();
}

class _CourierEarningsPageState extends State<CourierEarningsPage>{
  static const blue=Color(0xFF168CF5), navy=Color(0xFF10213E), green=Color(0xFF10B866), muted=Color(0xFF718198);
  final data=AppDataService.instance;
  Map<String,dynamic> summary={};
  bool loading=true;

  @override void initState(){super.initState();_load();}
  Future<void> _load() async {try{final s=await data.getCourierEarningsSummary();if(mounted)setState((){summary=s;loading=false;});}catch(_){if(mounted)setState(()=>loading=false);}}
  int v(String key)=>(summary[key] as num?)?.toInt()??0;
  String money(int n)=>'₺${n.toString()}';
  String date(dynamic raw){final d=DateTime.tryParse((raw??'').toString())?.toLocal();if(d==null)return '';return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';}

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFFF5FAFF),
    appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,title:const Text('Kazançlarım',style:TextStyle(color:navy,fontWeight:FontWeight.w900))),
    body:RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(16,16,16,28),children:[
      if(loading)const LinearProgressIndicator(minHeight:2),
      Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF168CF5),Color(0xFF55CFFF)]),borderRadius:BorderRadius.circular(26)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Kullanılabilir Bakiye',style:TextStyle(color:Color(0xE6FFFFFF),fontWeight:FontWeight.w700)),const SizedBox(height:5),Text(money(v('available_balance')),style:const TextStyle(color:Colors.white,fontSize:36,fontWeight:FontWeight.w900)),const SizedBox(height:14),Row(children:[Expanded(child:_heroStat('Toplam Hakediş',money(v('total_earned')))),Expanded(child:_heroStat('Bonus',money(v('bonus_total'))))])
      ])),
      const SizedBox(height:14),Row(children:[Expanded(child:_summaryCard('Bugün',v('today'))),const SizedBox(width:9),Expanded(child:_summaryCard('Bu Hafta',v('week'))),const SizedBox(width:9),Expanded(child:_summaryCard('Bu Ay',v('month')))]),
      const SizedBox(height:22),const Text('Hakediş & Bonus Geçmişi',style:TextStyle(color:navy,fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:10),
      StreamBuilder<List<Map<String,dynamic>>>(stream:data.watchCourierEarnings(),builder:(context,s){final rows=s.data??const[];if(s.connectionState==ConnectionState.waiting&&!s.hasData)return const Center(child:Padding(padding:EdgeInsets.all(20),child:CircularProgressIndicator()));if(rows.isEmpty)return _empty('Henüz hakediş yok','Teslim ettiğin işler ve tanımlanan bonuslar burada görünür.');return Column(children:rows.map(_earningTile).toList());}),
      const SizedBox(height:22),const Text('Ödeme Geçmişi',style:TextStyle(color:navy,fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:10),
      StreamBuilder<List<Map<String,dynamic>>>(stream:data.watchCourierPayouts(),builder:(context,s){final rows=s.data??const[];if(rows.isEmpty)return _empty('Henüz ödeme kaydı yok','Banka ödemeleri işlendikçe burada görünür.');return Column(children:rows.map(_payoutTile).toList());}),
    ])),
  );

  Widget _heroStat(String t,String val)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(color:Color(0xDFFFFFFF),fontSize:11)),const SizedBox(height:2),Text(val,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17))]);
  Widget _summaryCard(String t,int n)=>Container(padding:const EdgeInsets.symmetric(vertical:15,horizontal:8),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Column(children:[Text(t,style:const TextStyle(color:muted,fontSize:10.5)),const SizedBox(height:4),Text(money(n),style:const TextStyle(color:navy,fontWeight:FontWeight.w900,fontSize:15))]));
  Widget _earningTile(Map<String,dynamic> r){final type=(r['entry_type']??'delivery').toString();final bonus=type=='bonus';return Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Row(children:[CircleAvatar(backgroundColor:(bonus?const Color(0xFFFFB300):green).withValues(alpha:.12),child:Icon(bonus?Icons.card_giftcard_rounded:Icons.check_circle_rounded,color:bonus?const Color(0xFFFFA000):green)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((r['title']??(bonus?'Bonus':'Teslimat Hakedişi')).toString(),style:const TextStyle(color:navy,fontWeight:FontWeight.w900)),const SizedBox(height:2),Text('${r['description']??''} • ${date(r['created_at'])}',style:const TextStyle(color:muted,fontSize:10.5))])),Text('+${money((r['amount'] as num?)?.toInt()??0)}',style:const TextStyle(color:green,fontSize:16,fontWeight:FontWeight.w900))]));}
  Widget _payoutTile(Map<String,dynamic> r){final st=(r['status']??'pending').toString();final paid=st=='paid';final label=switch(st){'paid'=>'Ödendi','processing'=>'İşleniyor','failed'=>'Başarısız','cancelled'=>'İptal','pending'=>'Bekliyor',_=>st};return Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Row(children:[CircleAvatar(backgroundColor:(paid?green:blue).withValues(alpha:.12),child:Icon(Icons.account_balance_rounded,color:paid?green:blue)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:navy,fontWeight:FontWeight.w900)),const SizedBox(height:2),Text('${r['bank_name']??'Banka'} • ${r['iban_last4']==null?'':'•••• ${r['iban_last4']}'} • ${date(r['created_at'])}',style:const TextStyle(color:muted,fontSize:10.5))])),Text(money((r['amount'] as num?)?.toInt()??0),style:const TextStyle(color:navy,fontWeight:FontWeight.w900,fontSize:16))]));}
  Widget _empty(String t,String s)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Column(children:[const Icon(Icons.receipt_long_outlined,color:blue,size:34),const SizedBox(height:7),Text(t,style:const TextStyle(color:navy,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(s,textAlign:TextAlign.center,style:const TextStyle(color:muted,fontSize:11))]));
}
