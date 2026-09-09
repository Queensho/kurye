import 'package:flutter/material.dart';

import 'admin_page.dart';
import 'courier_earnings_page.dart';
import 'courier_home_page.dart';
import 'courier_job_pool_page.dart';
import 'courier_profile_page.dart';
import 'customer_phone_auth_page.dart';
import 'data/app_data_service.dart';
import 'home_pixel_preview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await AppDataService.instance.initialize(); } catch (_) {}
  runApp(const KuryeApp());
}

class KuryeApp extends StatelessWidget {
  const KuryeApp({super.key});
  String get path => Uri.decodeComponent(Uri.base.path).toLowerCase();
  bool get isAdminPath => path.contains('/admin');
  bool get isCustomerPath => path.contains('/müsteri')||path.contains('/müşteri')||path.contains('/musteri');
  bool get isJobPoolPath => path.contains('/havuz')||path.contains('/is-havuzu')||path.contains('/iş-havuzu');
  bool get isCourierProfilePath => path.contains('/profil')||path.contains('/kurye-profili');
  bool get isCourierEarningsPath => path.contains('/kazanc')||path.contains('/kazanç')||path.contains('/earnings');

  @override Widget build(BuildContext context){
    Widget home;
    if(isAdminPath){home=const AdminPage();}
    else if(isCustomerPath){ home=AppDataService.instance.isSignedIn?const HomePixelPreview():const CustomerPhoneAuthPage(); }
    else if(isJobPoolPath){home=const CourierJobPoolPage();}
    else if(isCourierEarningsPath){home=const CourierEarningsPage();}
    else if(isCourierProfilePath){home=const CourierProfilePage();}
    else{home=const CourierHomePage();}
    return MaterialApp(
      debugShowCheckedModeBanner:false,
      title:isAdminPath?'Kurye Admin':isCustomerPath?'Kurye Müşteri':'Kurye',
      theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:const Color(0xFFF7FBFF),visualDensity:VisualDensity.compact,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF168CF5))),
      builder:(context,child){
        if(child==null||isCustomerPath||isAdminPath)return child??const SizedBox.shrink();
        final mq=MediaQuery.of(context);
        final scale=(mq.size.width/430).clamp(.84,1.0);
        return MediaQuery(data:mq.copyWith(textScaler:TextScaler.linear(scale)),child:Align(alignment:Alignment.topCenter,child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:480),child:child)));
      },
      home:home,
    );
  }
}
