import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/app_data_service.dart';

class CourierAuthPage extends StatefulWidget {
  const CourierAuthPage({super.key, required this.onAuthenticated, this.initialMessage});
  final VoidCallback onAuthenticated;
  final String? initialMessage;
  @override State<CourierAuthPage> createState() => _CourierAuthPageState();
}

class _CourierAuthPageState extends State<CourierAuthPage> {
  static const orange=Color(0xFFFF5A1F), navy=Color(0xFF10152B), muted=Color(0xFF7B8191), bg=Color(0xFFFFFBF8);
  final data=AppDataService.instance;
  final email=TextEditingController(), password=TextEditingController(), passwordAgain=TextEditingController(), fullName=TextEditingController(), phone=TextEditingController();
  bool register=false,busy=false,obscure=true,rememberMe=true; String vehicleType='motorcycle'; String? message;
  @override void initState(){super.initState();message=widget.initialMessage;}
  @override void dispose(){email.dispose();password.dispose();passwordAgain.dispose();fullName.dispose();phone.dispose();super.dispose();}

  Future<void> _submit() async {
    final mail=email.text.trim().toLowerCase(),pass=password.text;
    if(mail.isEmpty||!mail.contains('@')){setState(()=>message='Geçerli bir e-posta adresi gir.');return;}
    if(pass.length<6){setState(()=>message='Şifre en az 6 karakter olmalı.');return;}
    if(register&&fullName.text.trim().length<2){setState(()=>message='Ad soyad alanını doldur.');return;}
    if(register&&passwordAgain.text!=pass){setState(()=>message='Şifreler eşleşmiyor.');return;}
    setState((){busy=true;message=null;});
    try{
      if(register){
        final res=await data.client.auth.signUp(email:mail,password:pass,data:{'role':'courier','full_name':fullName.text.trim(),'phone':phone.text.trim(),'vehicle_type':vehicleType});
        if(!mounted)return;
        if(res.session==null){setState((){busy=false;register=false;message='Kurye hesabın oluşturuldu. E-posta doğrulaması açıksa gelen bağlantıyı onayladıktan sonra giriş yap.';});return;}
      }else{await data.client.auth.signInWithPassword(email:mail,password:pass);}
      final courier=await data.client.from('couriers').select('user_id,is_approved,is_online,vehicle_type').eq('user_id',data.userId).maybeSingle();
      if(courier==null){await data.client.auth.signOut();throw StateError('Bu hesap kurye hesabı değil. Kurye kaydı oluşturmalısın.');}
      final profile=await data.client.from('profiles').select('account_status').eq('id',data.userId).maybeSingle();
      if(profile?['account_status']=='suspended'){await data.client.auth.signOut();throw StateError('Bu kurye hesabı askıya alınmış. Destek ile iletişime geç.');}
      if(mounted)widget.onAuthenticated();
    }on AuthException catch(e){if(mounted)setState(()=>message=_authMessage(e.message));}catch(e){if(mounted)setState(()=>message=e.toString().replaceFirst('Bad state: ',''));}finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> _forgotPassword() async {final mail=email.text.trim().toLowerCase();if(mail.isEmpty||!mail.contains('@')){setState(()=>message='Şifre sıfırlamak için önce e-posta adresini yaz.');return;}try{await data.client.auth.resetPasswordForEmail(mail);if(mounted)setState(()=>message='Şifre sıfırlama bağlantısı e-posta adresine gönderildi.');}catch(e){if(mounted)setState(()=>message=e.toString());}}
  String _authMessage(String raw){final t=raw.toLowerCase();if(t.contains('invalid login'))return 'E-posta veya şifre hatalı.';if(t.contains('email not confirmed'))return 'E-posta adresini doğruladıktan sonra giriş yapabilirsin.';if(t.contains('already registered'))return 'Bu e-posta ile zaten bir hesap var.';return raw;}

  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:bg,body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:SingleChildScrollView(padding:EdgeInsets.zero,child:Column(mainAxisSize:MainAxisSize.min,children:[
    _hero(),
    Transform.translate(offset:const Offset(0,-8),child:Container(width:double.infinity,padding:const EdgeInsets.fromLTRB(22,10,22,18),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(28))),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      _tabs(),const SizedBox(height:12),
      if(register)...[_field(fullName,'Ad Soyad',Icons.person_outline_rounded),const SizedBox(height:8),_field(phone,'Telefon',Icons.phone_outlined,keyboard:TextInputType.phone),const SizedBox(height:8),DropdownButtonFormField<String>(value:vehicleType,decoration:_input('Araç tipi',Icons.two_wheeler_outlined),items:const [DropdownMenuItem(value:'motorcycle',child:Text('Motosiklet')),DropdownMenuItem(value:'car',child:Text('Otomobil'))],onChanged:(v)=>setState(()=>vehicleType=v??'motorcycle')),const SizedBox(height:8)],
      _field(email,'E-posta',Icons.mail_outline_rounded,keyboard:TextInputType.emailAddress),const SizedBox(height:8),
      TextField(controller:password,obscureText:obscure,decoration:_input('Şifre',Icons.lock_outline_rounded).copyWith(suffixIcon:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility_off_outlined:Icons.visibility_outlined,color:muted,size:20))),onSubmitted:register?null:(_)=>_submit()),
      if(register)...[const SizedBox(height:8),TextField(controller:passwordAgain,obscureText:obscure,decoration:_input('Şifre Tekrar',Icons.lock_reset_rounded))],
      if(!register)...[const SizedBox(height:6),Row(children:[InkWell(onTap:()=>setState(()=>rememberMe=!rememberMe),child:Row(children:[Container(width:21,height:21,decoration:BoxDecoration(color:rememberMe?orange:Colors.white,borderRadius:BorderRadius.circular(5),border:Border.all(color:rememberMe?orange:const Color(0xFFD8D9DE))),child:rememberMe?const Icon(Icons.check_rounded,color:Colors.white,size:16):null),const SizedBox(width:8),const Text('Beni hatırla',style:TextStyle(color:Color(0xFF4E5360),fontSize:13.5,fontWeight:FontWeight.w600))])),const Spacer(),TextButton(onPressed:_forgotPassword,child:const Text('Şifremi unuttum?',style:TextStyle(color:orange,fontWeight:FontWeight.w700,fontSize:13.5)))])],
      if(message!=null)...[const SizedBox(height:6),Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:const Color(0xFFFFF2EA),borderRadius:BorderRadius.circular(12)),child:Text(message!,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFF9B4B24),fontWeight:FontWeight.w700,fontSize:12)))],
      const SizedBox(height:9),SizedBox(height:50,child:FilledButton(onPressed:busy?null:_submit,style:FilledButton.styleFrom(backgroundColor:orange,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),child:busy?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(register?'Kayıt Ol':'Giriş Yap',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)))),
      if(!register)...[const SizedBox(height:10),const Row(children:[Expanded(child:Divider()),Padding(padding:EdgeInsets.symmetric(horizontal:10),child:Text('veya',style:TextStyle(color:muted))),Expanded(child:Divider())]),const SizedBox(height:8),SizedBox(height:46,child:OutlinedButton.icon(onPressed:()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Google ile giriş yakında aktif olacak.'))),icon:const Text('G',style:TextStyle(fontWeight:FontWeight.w900,fontSize:19,color:Color(0xFF4285F4))),label:const Text('Google ile giriş yap',style:TextStyle(color:navy,fontWeight:FontWeight.w700)),style:OutlinedButton.styleFrom(side:const BorderSide(color:Color(0xFFE2E2E7)),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15))))),const SizedBox(height:10),InkWell(onTap:()=>setState((){register=true;message=null;}),child:Container(padding:const EdgeInsets.symmetric(horizontal:15,vertical:10),decoration:BoxDecoration(color:const Color(0xFFFFF1E9),borderRadius:BorderRadius.circular(16)),child:const Row(children:[Icon(Icons.delivery_dining_rounded,color:orange,size:30),SizedBox(width:12),Expanded(child:Text('Henüz hesabın yok mu?   Kayıt ol  →',style:TextStyle(color:orange,fontSize:14,fontWeight:FontWeight.w800)))])))],
      if(register)...[const SizedBox(height:9),const Text('Yeni kurye hesabı onay bekler. Admin onayından sonra online olup iş havuzundan iş alabilirsin.',textAlign:TextAlign.center,style:TextStyle(color:muted,fontSize:11,height:1.3))]
    ])))
  ])))));

  Widget _hero()=>SizedBox(
    height:170,
    width:double.infinity,
    child:Image.asset('assets/images/Kgiris.png',width:double.infinity,height:170,fit:BoxFit.cover,alignment:Alignment.center),
  );
  Widget _tabs()=>Row(children:[Expanded(child:_mode(false,'Giriş Yap')),Expanded(child:_mode(true,'Kayıt Ol'))]);
  Widget _mode(bool value,String label){final selected=register==value;return InkWell(onTap:busy?null:()=>setState((){register=value;message=null;}),child:Container(height:42,alignment:Alignment.center,decoration:BoxDecoration(border:Border(bottom:BorderSide(color:selected?orange:const Color(0xFFE7E7EA),width:selected?2.5:1))),child:Text(label,style:TextStyle(color:selected?orange:muted,fontWeight:FontWeight.w800,fontSize:16))));}
  Widget _field(TextEditingController c,String label,IconData icon,{TextInputType? keyboard})=>TextField(controller:c,keyboardType:keyboard,autocorrect:false,decoration:_input(label,icon));
  InputDecoration _input(String label,IconData icon)=>InputDecoration(hintText:label,prefixIcon:Icon(icon,color:muted,size:20),filled:true,fillColor:const Color(0xFFF8F8FB),isDense:true,contentPadding:const EdgeInsets.symmetric(horizontal:13,vertical:14),border:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:const BorderSide(color:Color(0xFFE8E8ED))),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:const BorderSide(color:Color(0xFFE8E8ED))),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:const BorderSide(color:orange,width:1.4)));
}
