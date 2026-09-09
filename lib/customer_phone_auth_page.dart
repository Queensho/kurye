import 'package:flutter/material.dart';
import 'data/app_data_service.dart';
import 'home_pixel_preview.dart';

class CustomerPhoneAuthPage extends StatefulWidget {
  const CustomerPhoneAuthPage({super.key});
  @override State<CustomerPhoneAuthPage> createState()=>_CustomerPhoneAuthPageState();
}

class _CustomerPhoneAuthPageState extends State<CustomerPhoneAuthPage>{
  final phone=TextEditingController(); final otp=TextEditingController();
  bool codeSent=false, loading=false; String? error;
  String normalized(){ var v=phone.text.replaceAll(RegExp(r'\D'),''); if(v.startsWith('0'))v=v.substring(1); if(v.startsWith('90'))return '+$v'; return '+90$v'; }
  Future<void> send() async { if(phone.text.replaceAll(RegExp(r'\D'),'').length<10){setState(()=>error='Geçerli telefon numarası gir.');return;} setState(()=>loading=true); try{await AppDataService.instance.sendPhoneOtp(normalized()); if(mounted)setState((){codeSent=true;error=null;});}catch(e){if(mounted)setState(()=>error='OTP gönderilemedi: $e');}finally{if(mounted)setState(()=>loading=false);} }
  Future<void> verify() async { if(otp.text.length!=6){setState(()=>error='6 haneli kodu gir.');return;} setState(()=>loading=true); try{await AppDataService.instance.verifyPhoneOtp(phone:normalized(),token:otp.text); if(mounted)Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>const HomePixelPreview()));}catch(e){if(mounted)setState(()=>error='Kod doğrulanamadı.');}finally{if(mounted)setState(()=>loading=false);} }
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xfff6faff),body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(28),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:430),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const CircleAvatar(radius:38,backgroundColor:Color(0xff168cf5),child:Icon(Icons.local_shipping_rounded,color:Colors.white,size:38)),const SizedBox(height:24),
    Text(codeSent?'Doğrulama Kodu':'Hoş Geldin',textAlign:TextAlign.center,style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:Color(0xff10213e))),const SizedBox(height:8),
    Text(codeSent?'${normalized()} numarasına gelen 6 haneli kodu gir.':'Telefon numaranla giriş yap veya yeni hesap oluştur.',textAlign:TextAlign.center,style:const TextStyle(color:Color(0xff718096),fontSize:14)),const SizedBox(height:30),
    if(!codeSent) TextField(controller:phone,keyboardType:TextInputType.phone,decoration:InputDecoration(prefixText:'+90  ',labelText:'Telefon Numarası',hintText:'5XX XXX XX XX',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none))) else TextField(controller:otp,keyboardType:TextInputType.number,maxLength:6,textAlign:TextAlign.center,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800,letterSpacing:10),decoration:InputDecoration(counterText:'',hintText:'••••••',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none))),
    if(error!=null)...[const SizedBox(height:12),Text(error!,textAlign:TextAlign.center,style:const TextStyle(color:Colors.red,fontWeight:FontWeight.w600))],const SizedBox(height:18),
    FilledButton(onPressed:loading?null:(codeSent?verify:send),style:FilledButton.styleFrom(backgroundColor:const Color(0xff168cf5),minimumSize:const Size.fromHeight(58),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))),child:loading?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(codeSent?'Giriş Yap':'Kod Gönder',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900))),
    if(codeSent)TextButton(onPressed:loading?null:()=>setState((){codeSent=false;otp.clear();error=null;}),child:const Text('Telefon numarasını değiştir')),
    const SizedBox(height:18),const Text('Devam ederek Kullanım Koşulları ve Gizlilik Politikasını kabul etmiş olursun.',textAlign:TextAlign.center,style:TextStyle(color:Color(0xff94a3b8),fontSize:11)),
  ]))))));
}
