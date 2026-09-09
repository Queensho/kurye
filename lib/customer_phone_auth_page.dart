import 'package:flutter/material.dart';
import 'data/app_data_service.dart';
import 'home_pixel_preview.dart';

class CustomerPhoneAuthPage extends StatefulWidget {
  const CustomerPhoneAuthPage({super.key});
  @override State<CustomerPhoneAuthPage> createState()=>_CustomerPhoneAuthPageState();
}

class _CustomerPhoneAuthPageState extends State<CustomerPhoneAuthPage>{
  final phone=TextEditingController();
  final password=TextEditingController();
  final confirmPassword=TextEditingController();
  bool isRegister=false, loading=false, obscure=true, obscure2=true;
  String? error;

  String normalized(){
    var v=phone.text.replaceAll(RegExp(r'\D'),'');
    if(v.startsWith('0')) v=v.substring(1);
    if(v.startsWith('90')) return '+$v';
    return '+90$v';
  }

  bool validPhone()=>phone.text.replaceAll(RegExp(r'\D'),'').length>=10;

  Future<void> submit() async {
    if(!validPhone()){setState(()=>error='Geçerli bir telefon numarası gir.');return;}
    if(password.text.length<6){setState(()=>error='Şifre en az 6 karakter olmalı.');return;}
    if(isRegister && password.text!=confirmPassword.text){setState(()=>error='Şifreler eşleşmiyor.');return;}
    setState((){loading=true;error=null;});
    try{
      if(isRegister){
        await AppDataService.instance.signUpWithPhonePassword(phone:normalized(),password:password.text);
      }else{
        await AppDataService.instance.signInWithPhonePassword(phone:normalized(),password:password.text);
      }
      if(mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>const HomePixelPreview()));
    }catch(e){
      if(!mounted)return;
      final text=e.toString();
      setState(()=>error=text.contains('Invalid login credentials')?'Telefon numarası veya şifre hatalı.':text.replaceFirst('StateError: ',''));
    }finally{if(mounted)setState(()=>loading=false);}
  }

  InputDecoration fieldDecoration(String label,{Widget? suffix})=>InputDecoration(
    labelText:label,
    filled:true,
    fillColor:Colors.white,
    suffixIcon:suffix,
    border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none),
  );

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xfff6faff),
    body:SafeArea(
      child:Center(
        child:SingleChildScrollView(
          padding:const EdgeInsets.all(28),
          child:ConstrainedBox(
            constraints:const BoxConstraints(maxWidth:430),
            child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              const CircleAvatar(radius:38,backgroundColor:Color(0xff168cf5),child:Icon(Icons.local_shipping_rounded,color:Colors.white,size:38)),
              const SizedBox(height:24),
              Text(isRegister?'Hesap Oluştur':'Hoş Geldin',textAlign:TextAlign.center,style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:Color(0xff10213e))),
              const SizedBox(height:8),
              Text(isRegister?'Telefon numaran ve şifrenle müşteri hesabını oluştur.':'Telefon numaran ve şifrenle giriş yap.',textAlign:TextAlign.center,style:const TextStyle(color:Color(0xff718096),fontSize:14)),
              const SizedBox(height:26),
              Container(
                padding:const EdgeInsets.all(4),
                decoration:BoxDecoration(color:const Color(0xffeaf3fb),borderRadius:BorderRadius.circular(18)),
                child:Row(children:[
                  Expanded(child:_tab('Giriş Yap',!isRegister,()=>setState((){isRegister=false;error=null;}))),
                  Expanded(child:_tab('Kayıt Ol',isRegister,()=>setState((){isRegister=true;error=null;}))),
                ]),
              ),
              const SizedBox(height:22),
              TextField(controller:phone,keyboardType:TextInputType.phone,decoration:fieldDecoration('Telefon Numarası').copyWith(prefixText:'+90  ',hintText:'5XX XXX XX XX')),
              const SizedBox(height:14),
              TextField(controller:password,obscureText:obscure,decoration:fieldDecoration('Şifre',suffix:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility_off_outlined:Icons.visibility_outlined)))),
              if(isRegister)...[
                const SizedBox(height:14),
                TextField(controller:confirmPassword,obscureText:obscure2,decoration:fieldDecoration('Şifre Tekrar',suffix:IconButton(onPressed:()=>setState(()=>obscure2=!obscure2),icon:Icon(obscure2?Icons.visibility_off_outlined:Icons.visibility_outlined)))),
              ],
              if(error!=null)...[const SizedBox(height:12),Text(error!,textAlign:TextAlign.center,style:const TextStyle(color:Colors.red,fontWeight:FontWeight.w600))],
              const SizedBox(height:18),
              FilledButton(
                onPressed:loading?null:submit,
                style:FilledButton.styleFrom(backgroundColor:const Color(0xff168cf5),minimumSize:const Size.fromHeight(58),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))),
                child:loading?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(isRegister?'Kayıt Ol':'Giriş Yap',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900)),
              ),
              const SizedBox(height:18),
              const Text('Devam ederek Kullanım Koşulları ve Gizlilik Politikasını kabul etmiş olursun.',textAlign:TextAlign.center,style:TextStyle(color:Color(0xff94a3b8),fontSize:11)),
            ]),
          ),
        ),
      ),
    ),
  );

  Widget _tab(String text,bool selected,VoidCallback onTap)=>InkWell(
    onTap:onTap,
    borderRadius:BorderRadius.circular(15),
    child:Container(
      padding:const EdgeInsets.symmetric(vertical:13),
      decoration:BoxDecoration(color:selected?Colors.white:Colors.transparent,borderRadius:BorderRadius.circular(15),boxShadow:selected?const [BoxShadow(color:Color(0x12000000),blurRadius:8,offset:Offset(0,2))]:null),
      child:Text(text,textAlign:TextAlign.center,style:TextStyle(color:selected?const Color(0xff168cf5):const Color(0xff718096),fontWeight:FontWeight.w800)),
    ),
  );
}
