import 'package:flutter/material.dart';

import 'data/app_data_service.dart';

class CourierEarningsPage extends StatefulWidget {
  const CourierEarningsPage({super.key});
  @override State<CourierEarningsPage> createState()=>_CourierEarningsPageState();
}

class _CourierEarningsPageState extends State<CourierEarningsPage>{
  static const blue=Color(0xFF168CF5), navy=Color(0xFF10213E), green=Color(0xFF10B866), muted=Color(0xFF718198), red=Color(0xFFFF4D67);
  final data=AppDataService.instance;
  Map<String,dynamic> summary={};
  Map<String,dynamic>? bank;
  bool loading=true;

  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    try{
      final values=await Future.wait([data.getCourierEarningsSummary(),data.getCourierBankAccount()]);
      if(mounted)setState((){summary=Map<String,dynamic>.from(values[0] as Map);bank=values[1] as Map<String,dynamic>?;loading=false;});
    }catch(e){if(mounted){setState(()=>loading=false);_msg(e.toString().replaceFirst('Bad state: ',''));}}
  }
  int v(String key)=>(summary[key] as num?)?.toInt()??0;
  String money(int n)=>'₺${n.toString()}';
  String date(dynamic raw){final d=DateTime.tryParse((raw??'').toString())?.toLocal();if(d==null)return '';return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';}
  void _msg(String text)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));

  Future<void> _bankDialog() async {
    final holder=TextEditingController(text:(bank?['account_holder']??'').toString());
    final bankName=TextEditingController(text:(bank?['bank_name']??'').toString());
    final iban=TextEditingController();
    final ok=await showModalBottomSheet<bool>(
      context:context,isScrollControlled:true,showDragHandle:true,
      builder:(c)=>Padding(
        padding:EdgeInsets.fromLTRB(18,4,18,MediaQuery.of(c).viewInsets.bottom+22),
        child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          const Text('Banka Hesabı',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900,color:navy)),
          const SizedBox(height:5),
          Text(bank==null?'Hakediş ödemeleri için IBAN bilgilerini kaydet.':'Kayıtlı IBAN: ${bank?['iban_masked']??'••••'}',style:const TextStyle(color:muted)),
          const SizedBox(height:16),
          TextField(controller:holder,textCapitalization:TextCapitalization.words,decoration:_input('Hesap sahibi',Icons.person_outline_rounded)),
          const SizedBox(height:10),
          TextField(controller:bankName,decoration:_input('Banka adı',Icons.account_balance_outlined)),
          const SizedBox(height:10),
          TextField(controller:iban,textCapitalization:TextCapitalization.characters,keyboardType:TextInputType.text,decoration:_input('Yeni IBAN (TR...)',Icons.credit_card_rounded)),
          const SizedBox(height:8),
          const Text('Güvenlik için mevcut IBAN tam olarak gösterilmez. Değiştirmek için yeni IBANı tekrar gir.',style:TextStyle(color:muted,fontSize:11,height:1.35)),
          const SizedBox(height:16),
          FilledButton(onPressed:()=>Navigator.pop(c,true),style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(54),backgroundColor:blue),child:const Text('Kaydet',style:TextStyle(fontWeight:FontWeight.w900))),
        ])),
      ),
    );
    if(ok==true){
      if(iban.text.trim().isEmpty){_msg('IBAN alanını doldur.');}
      else{
        try{
          final saved=await data.saveCourierBankAccount(accountHolder:holder.text.trim(),bankName:bankName.text.trim(),iban:iban.text.trim());
          if(mounted)setState(()=>bank=saved);
          _msg('IBAN kalıcı olarak kaydedildi.');
        }catch(e){_msg(e.toString().replaceFirst('Bad state: ',''));}
      }
    }
    holder.dispose();bankName.dispose();iban.dispose();
  }

  Future<void> _requestPayout() async {
    if(bank==null){await _bankDialog();if(bank==null)return;}
    final available=v('available_balance');
    if(available<=0){_msg('Kullanılabilir bakiyen yok.');return;}
    final amount=TextEditingController(text:'$available');
    final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(
      title:const Text('Ödeme Talebi'),
      content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Kullanılabilir bakiye: ${money(available)}',style:const TextStyle(fontWeight:FontWeight.w800)),
        const SizedBox(height:12),
        TextField(controller:amount,keyboardType:TextInputType.number,decoration:_input('Talep tutarı',Icons.payments_outlined)),
        const SizedBox(height:10),
        Text('${bank?['bank_name']??''} • ${bank?['iban_masked']??''}',style:const TextStyle(color:muted,fontSize:12)),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Vazgeç')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Talep Oluştur'))],
    ));
    if(ok==true){
      final n=int.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'),''))??0;
      try{await data.requestCourierPayout(n);await _load();_msg('Ödeme talebin oluşturuldu.');}catch(e){_msg(e.toString().replaceFirst('Bad state: ',''));}
    }
    amount.dispose();
  }

  InputDecoration _input(String label,IconData icon)=>InputDecoration(labelText:label,prefixIcon:Icon(icon),filled:true,fillColor:const Color(0xFFF4F8FC),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none));

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFFF5FAFF),
    appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,title:const Text('Kazançlarım',style:TextStyle(color:navy,fontWeight:FontWeight.w900))),
    body:RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(16,16,16,28),children:[
      if(loading)const LinearProgressIndicator(minHeight:2),
      Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF168CF5),Color(0xFF55CFFF)]),borderRadius:BorderRadius.circular(26)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Kullanılabilir Bakiye',style:TextStyle(color:Color(0xE6FFFFFF),fontWeight:FontWeight.w700)),const SizedBox(height:5),Text(money(v('available_balance')),style:const TextStyle(color:Colors.white,fontSize:36,fontWeight:FontWeight.w900)),const SizedBox(height:14),Row(children:[Expanded(child:_heroStat('Toplam Hakediş',money(v('total_earned')))),Expanded(child:_heroStat('Bonus',money(v('bonus_total'))))]),
        const SizedBox(height:16),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:loading?null:_requestPayout,style:FilledButton.styleFrom(backgroundColor:Colors.white,foregroundColor:blue),icon:const Icon(Icons.account_balance_wallet_rounded),label:const Text('Ödeme Talep Et',style:TextStyle(fontWeight:FontWeight.w900))))
      ])),
      const SizedBox(height:14),Row(children:[Expanded(child:_summaryCard('Bugün',v('today'))),const SizedBox(width:9),Expanded(child:_summaryCard('Bu Hafta',v('week'))),const SizedBox(width:9),Expanded(child:_summaryCard('Bu Ay',v('month')))]),
      const SizedBox(height:14),
      InkWell(onTap:_bankDialog,borderRadius:BorderRadius.circular(20),child:Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Row(children:[CircleAvatar(backgroundColor:blue.withValues(alpha:.12),child:const Icon(Icons.account_balance_rounded,color:blue)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Ödeme Hesabı',style:TextStyle(color:navy,fontWeight:FontWeight.w900)),const SizedBox(height:2),Text(bank==null?'IBAN ekle':'${bank?['bank_name']??''} • ${bank?['iban_masked']??''}',style:const TextStyle(color:muted,fontSize:11))])),Icon(bank==null?Icons.add_circle_outline_rounded:Icons.edit_outlined,color:blue)]))),
      const SizedBox(height:22),const Text('Hakediş & Bonus Geçmişi',style:TextStyle(color:navy,fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:10),
      StreamBuilder<List<Map<String,dynamic>>>(stream:data.watchCourierEarnings(),builder:(context,s){final rows=s.data??const[];if(s.connectionState==ConnectionState.waiting&&!s.hasData)return const Center(child:Padding(padding:EdgeInsets.all(20),child:CircularProgressIndicator()));if(rows.isEmpty)return _empty('Henüz hakediş yok','Teslim ettiğin işler ve tanımlanan bonuslar burada görünür.');return Column(children:rows.map(_earningTile).toList());}),
      const SizedBox(height:22),const Text('Ödeme Geçmişi',style:TextStyle(color:navy,fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:10),
      StreamBuilder<List<Map<String,dynamic>>>(stream:data.watchCourierPayouts(),builder:(context,s){final rows=s.data??const[];if(rows.isEmpty)return _empty('Henüz ödeme kaydı yok','Ödeme talebi oluşturduğunda ve admin işlediğinde burada görünür.');return Column(children:rows.map(_payoutTile).toList());}),
    ])),
  );

  Widget _heroStat(String t,String val)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(color:Color(0xDFFFFFFF),fontSize:11)),const SizedBox(height:2),Text(val,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17))]);
  Widget _summaryCard(String t,int n)=>Container(padding:const EdgeInsets.symmetric(vertical:15,horizontal:8),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Column(children:[Text(t,style:const TextStyle(color:muted,fontSize:10.5)),const SizedBox(height:4),Text(money(n),style:const TextStyle(color:navy,fontWeight:FontWeight.w900,fontSize:15))]));
  Widget _earningTile(Map<String,dynamic> r){final type=(r['entry_type']??'delivery').toString();final bonus=type=='bonus';return Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Row(children:[CircleAvatar(backgroundColor:(bonus?const Color(0xFFFFB300):green).withValues(alpha:.12),child:Icon(bonus?Icons.card_giftcard_rounded:Icons.check_circle_rounded,color:bonus?const Color(0xFFFFA000):green)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((r['title']??(bonus?'Bonus':'Teslimat Hakedişi')).toString(),style:const TextStyle(color:navy,fontWeight:FontWeight.w900)),const SizedBox(height:2),Text('${r['description']??''} • ${date(r['created_at'])}',style:const TextStyle(color:muted,fontSize:10.5))])),Text('+${money((r['amount'] as num?)?.toInt()??0)}',style:const TextStyle(color:green,fontSize:16,fontWeight:FontWeight.w900))]));}
  Widget _payoutTile(Map<String,dynamic> r){final st=(r['status']??'pending').toString();final paid=st=='paid';final failed=st=='failed'||st=='cancelled';final label=switch(st){'paid'=>'Ödendi','processing'=>'İşleniyor','failed'=>'Başarısız','cancelled'=>'İptal','pending'=>'Bekliyor',_=>st};return Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Row(children:[CircleAvatar(backgroundColor:(failed?red:paid?green:blue).withValues(alpha:.12),child:Icon(Icons.account_balance_rounded,color:failed?red:paid?green:blue)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:navy,fontWeight:FontWeight.w900)),const SizedBox(height:2),Text('${r['bank_name']??'Banka'} • ${r['iban_last4']==null?'':'•••• ${r['iban_last4']}'} • ${date(r['created_at'])}',style:const TextStyle(color:muted,fontSize:10.5))])),Text(money((r['amount'] as num?)?.toInt()??0),style:const TextStyle(color:navy,fontWeight:FontWeight.w900,fontSize:16))]));}
  Widget _empty(String t,String s)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Column(children:[const Icon(Icons.receipt_long_outlined,color:blue,size:34),const SizedBox(height:7),Text(t,style:const TextStyle(color:navy,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(s,textAlign:TextAlign.center,style:const TextStyle(color:muted,fontSize:11))]));
}
