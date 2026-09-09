import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class AdminPayoutsPage extends StatefulWidget {
  const AdminPayoutsPage({super.key});
  @override State<AdminPayoutsPage> createState()=>_AdminPayoutsPageState();
}

class _AdminPayoutsPageState extends State<AdminPayoutsPage>{
  static const blue=Color(0xFF168CF5),navy=Color(0xFF10213E),muted=Color(0xFF74839A),green=Color(0xFF20C997),red=Color(0xFFFF4D67),orange=Color(0xFFFFA726);
  final data=AppDataService.instance;
  bool loading=true;
  String filter='Tümü';
  List<Map<String,dynamic>> rows=[];

  @override void initState(){super.initState();_load();}
  Future<void> _load() async{
    try{
      final value=await data.client.from('courier_payouts').select().order('created_at',ascending:false);
      if(mounted)setState((){rows=List<Map<String,dynamic>>.from(value);loading=false;});
    }catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Ödemeler yüklenemedi: $e')));}}
  }

  String tr(String s)=>switch(s){'pending'=>'Bekleyen','processing'=>'İşleniyor','paid'=>'Ödendi','failed'=>'Başarısız','cancelled'=>'İptal',_=>s};
  Color color(String s)=>s=='paid'?green:(s=='failed'||s=='cancelled')?red:s=='processing'?blue:orange;
  String date(dynamic raw){final d=DateTime.tryParse('${raw??''}')?.toLocal();if(d==null)return '-';return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';}

  Future<void> _status(Map<String,dynamic> row,String status) async{
    try{
      await data.client.rpc('admin_update_payout_status',params:{'p_payout_id':row['id'],'p_status':status});
      await _load();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Güncellenemedi: $e')));}
  }

  Future<void> _detail(Map<String,dynamic> r) async{
    final st=(r['status']??'pending').toString();
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,builder:(c)=>SafeArea(child:Padding(
      padding:const EdgeInsets.fromLTRB(18,4,18,24),
      child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,mainAxisSize:MainAxisSize.min,children:[
        const Text('Ödeme Talebi',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:navy)),
        const SizedBox(height:14),
        _kv('Tutar','₺${r['amount']??0}'),
        _kv('Durum',tr(st)),
        _kv('Hesap sahibi',r['account_holder']),
        _kv('Banka',r['bank_name']),
        _kv('IBAN',r['iban_snapshot']),
        _kv('Kurye ID',r['courier_id']),
        _kv('Talep',date(r['requested_at']??r['created_at'])),
        _kv('İşlendi',date(r['processed_at'])),
        _kv('Ödendi',date(r['paid_at'])),
        _kv('Transfer yöntemi',r['provider']??'manual_bank_transfer'),
        _kv('Transfer ID',r['provider_transfer_id']),
        _kv('Referans',r['reference_code']),
        _kv('Hata',r['failure_reason']),
        const SizedBox(height:16),
        if(st=='pending') FilledButton.icon(onPressed:(){Navigator.pop(c);_status(r,'processing');},icon:const Icon(Icons.play_arrow_rounded),label:const Text('Ödemeyi İşleme Al')),
        if(st=='processing') ...[
          FilledButton.icon(onPressed:(){Navigator.pop(c);_status(r,'paid');},style:FilledButton.styleFrom(backgroundColor:green),icon:const Icon(Icons.check_circle_rounded),label:const Text('Banka Transferi Tamamlandı')),
          const SizedBox(height:8),
          FilledButton.tonalIcon(onPressed:(){Navigator.pop(c);_status(r,'failed');},icon:const Icon(Icons.error_outline_rounded),label:const Text('Transfer Başarısız')),
        ],
        if(st=='pending'||st=='processing') ...[
          const SizedBox(height:8),
          TextButton.icon(onPressed:(){Navigator.pop(c);_status(r,'cancelled');},icon:const Icon(Icons.cancel_outlined),label:const Text('Talebi İptal Et')),
        ],
        const SizedBox(height:10),
        const Text('Not: Bu ekran banka transferi operasyonunu yönetir. Otomatik banka API transferi için sağlayıcı kimlik bilgileri ayrıca bağlanmalıdır.',style:TextStyle(color:muted,fontSize:11,height:1.4)),
      ])),
    )));
  }

  Widget _kv(String label,dynamic value)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:115,child:Text(label,style:const TextStyle(color:muted,fontWeight:FontWeight.w700))),Expanded(child:SelectableText('${value??'-'}',style:const TextStyle(color:navy,fontWeight:FontWeight.w800)))]));

  @override Widget build(BuildContext context){
    final visible=rows.where((r)=>filter=='Tümü'||tr((r['status']??'pending').toString())==filter).toList();
    return Scaffold(
      backgroundColor:const Color(0xFFF4F8FC),
      appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,title:const Text('Kurye Ödemeleri',style:TextStyle(color:navy,fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh_rounded))]),
      body:loading?const Center(child:CircularProgressIndicator()):Column(children:[
        SizedBox(height:52,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:14,vertical:7),children:[for(final f in ['Tümü','Bekleyen','İşleniyor','Ödendi','Başarısız','İptal'])Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(selected:filter==f,onSelected:(_)=>setState(()=>filter=f),label:Text(f)))])),
        Expanded(child:visible.isEmpty?const Center(child:Text('Ödeme talebi yok',style:TextStyle(color:muted))):RefreshIndicator(onRefresh:_load,child:ListView.builder(padding:const EdgeInsets.fromLTRB(14,8,14,24),itemCount:visible.length,itemBuilder:(_,i){final r=visible[i];final st=(r['status']??'pending').toString();return Card(elevation:0,color:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),child:ListTile(onTap:()=>_detail(r),contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:8),leading:CircleAvatar(backgroundColor:color(st).withValues(alpha:.12),child:Icon(Icons.account_balance_wallet_rounded,color:color(st))),title:Text('₺${r['amount']??0}',style:const TextStyle(color:navy,fontWeight:FontWeight.w900)),subtitle:Text('${r['account_holder']??'Kurye'}\n${r['bank_name']??'Banka'} • •••• ${r['iban_last4']??''}',maxLines:2),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(tr(st),style:TextStyle(color:color(st),fontWeight:FontWeight.w900,fontSize:11)),const Icon(Icons.chevron_right_rounded,color:muted)])));}))),
      ]),
    );
  }
}
