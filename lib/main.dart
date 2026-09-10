import 'package:flutter/material.dart';

import 'admin_announcement_shortcut.dart';
import 'admin_page.dart';
import 'announcement_center_page.dart';
import 'courier_auth_gate.dart';
import 'courier_earnings_page.dart';
import 'courier_home_page.dart';
import 'courier_job_pool_page.dart';
import 'courier_profile_page.dart';
import 'customer_phone_auth_page.dart';
import 'data/app_data_service.dart';
import 'fixed_notification_bell_overlay.dart';
import 'home_pixel_preview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await AppDataService.instance.initialize(); } catch (_) {}
  runApp(const KuryeApp());
}

class KuryeApp extends StatelessWidget {
  const KuryeApp({super.key});

  String get path => Uri.decodeComponent(Uri.base.path).toLowerCase();
  bool get isAdminNotificationsPath => path.contains('/admin/bildirim') || path.contains('/admin/duyuru');
  bool get isAdminPath => path.contains('/admin');
  bool get isCustomerPath => path.contains('/müsteri') || path.contains('/müşteri') || path.contains('/musteri');
  bool get isJobPoolPath => path.contains('/havuz') || path.contains('/is-havuzu') || path.contains('/iş-havuzu');
  bool get isCourierProfilePath => path.contains('/profil') || path.contains('/kurye-profili');
  bool get isCourierEarningsPath => path.contains('/kazanc') || path.contains('/kazanç') || path.contains('/earnings');

  Widget _courierGate(Widget child) => CourierAuthGate(child: child);

  ThemeData get _customerTheme {
    const orange = Color(0xFFFF5A1F);
    const navy = Color(0xFF171052);
    const bg = Color(0xFFF7F7FA);
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.light,
      primary: orange,
      secondary: navy,
      surface: Colors.white,
      error: const Color(0xFFD94A4A),
    );
    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE9E7EF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: navy),
        titleTextStyle: TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w900),
      ),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: orange, selectionHandleColor: orange),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        prefixIconColor: navy,
        suffixIconColor: navy,
        hintStyle: const TextStyle(color: Color(0xFF8B8997)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: orange, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE7E4ED))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: orange, foregroundColor: Colors.white),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: orange),
      snackBarTheme: SnackBarThemeData(backgroundColor: navy, contentTextStyle: const TextStyle(color: Colors.white), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), behavior: SnackBarBehavior.floating),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.white),
      dialogTheme: DialogThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (isAdminNotificationsPath) {
      home = const AdminAnnouncementPage();
    } else if (isAdminPath) {
      home = const AdminAnnouncementShortcut(child: AdminPage());
    } else if (isCustomerPath) {
      home = AppDataService.instance.isSignedIn
          ? const FixedNotificationBellOverlay(audience: 'customer', child: HomePixelPreview())
          : const CustomerPhoneAuthPage();
    } else if (isJobPoolPath) {
      home = _courierGate(const FixedNotificationBellOverlay(audience: 'courier', child: CourierJobPoolPage()));
    } else if (isCourierEarningsPath) {
      home = _courierGate(const FixedNotificationBellOverlay(audience: 'courier', child: CourierEarningsPage()));
    } else if (isCourierProfilePath) {
      home = _courierGate(const FixedNotificationBellOverlay(audience: 'courier', child: CourierProfilePage()));
    } else {
      home = _courierGate(const FixedNotificationBellOverlay(audience: 'courier', child: CourierHomePage()));
    }

    final theme = isCustomerPath
        ? _customerTheme
        : ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF7FBFF),
            visualDensity: VisualDensity.compact,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF168CF5)),
          );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: isAdminPath ? 'Kurye Admin' : isCustomerPath ? 'Open' : 'Kurye',
      theme: theme,
      builder: (context, child) {
        if (child == null || isCustomerPath || isAdminPath) return child ?? const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        final scale = (mq.size.width / 430).clamp(.84, 1.0);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: child)),
        );
      },
      home: home,
    );
  }
}
