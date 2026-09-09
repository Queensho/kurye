import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/app_data_service.dart';

class CourierAuthPage extends StatefulWidget {
  const CourierAuthPage({super.key, required this.onAuthenticated, this.initialMessage});

  final VoidCallback onAuthenticated;
  final String? initialMessage;

  @override
  State<CourierAuthPage> createState() => _CourierAuthPageState();
}

class _CourierAuthPageState extends State<CourierAuthPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10213E);
  static const muted = Color(0xFF74839A);
  static const bg = Color(0xFFF4F8FC);

  final data = AppDataService.instance;
  final email = TextEditingController();
  final password = TextEditingController();
  final passwordAgain = TextEditingController();
  final fullName = TextEditingController();
  final phone = TextEditingController();

  bool register = false;
  bool busy = false;
  bool obscure = true;
  String vehicleType = 'motorcycle';
  String? message;

  @override
  void initState() {
    super.initState();
    message = widget.initialMessage;
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    passwordAgain.dispose();
    fullName.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final mail = email.text.trim().toLowerCase();
    final pass = password.text;
    if (mail.isEmpty || !mail.contains('@')) {
      setState(() => message = 'Geçerli bir e-posta adresi gir.');
      return;
    }
    if (pass.length < 6) {
      setState(() => message = 'Şifre en az 6 karakter olmalı.');
      return;
    }
    if (register) {
      if (fullName.text.trim().length < 2) {
        setState(() => message = 'Ad soyad alanını doldur.');
        return;
      }
      if (passwordAgain.text != pass) {
        setState(() => message = 'Şifreler eşleşmiyor.');
        return;
      }
    }

    setState(() {
      busy = true;
      message = null;
    });

    try {
      if (register) {
        final res = await data.client.auth.signUp(
          email: mail,
          password: pass,
          data: {
            'role': 'courier',
            'full_name': fullName.text.trim(),
            'phone': phone.text.trim(),
            'vehicle_type': vehicleType,
          },
        );
        if (!mounted) return;
        if (res.session == null) {
          setState(() {
            busy = false;
            register = false;
            message = 'Kurye hesabın oluşturuldu. E-posta doğrulaması açıksa gelen bağlantıyı onayladıktan sonra giriş yap.';
          });
          return;
        }
      } else {
        await data.client.auth.signInWithPassword(email: mail, password: pass);
      }

      final courier = await data.client
          .from('couriers')
          .select('user_id,is_approved,is_online,vehicle_type')
          .eq('user_id', data.userId)
          .maybeSingle();
      if (courier == null) {
        await data.client.auth.signOut();
        throw StateError('Bu hesap kurye hesabı değil. Kurye kaydı oluşturmalısın.');
      }

      final profile = await data.client
          .from('profiles')
          .select('account_status')
          .eq('id', data.userId)
          .maybeSingle();
      if (profile?['account_status'] == 'suspended') {
        await data.client.auth.signOut();
        throw StateError('Bu kurye hesabı askıya alınmış. Destek ile iletişime geç.');
      }

      if (!mounted) return;
      widget.onAuthenticated();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => message = _authMessage(e.message));
    } catch (e) {
      if (!mounted) return;
      setState(() => message = e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _authMessage(String raw) {
    final text = raw.toLowerCase();
    if (text.contains('invalid login')) return 'E-posta veya şifre hatalı.';
    if (text.contains('email not confirmed')) return 'E-posta adresini doğruladıktan sonra giriş yapabilirsin.';
    if (text.contains('already registered') || text.contains('already been registered')) return 'Bu e-posta ile zaten bir hesap var.';
    if (text.contains('password')) return 'Şifre kabul edilmedi. En az 6 karakter kullan.';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF168CF5), Color(0xFF4BC8FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 27,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 30),
                        ),
                        SizedBox(height: 13),
                        Text('Kurye Girişi', style: TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900)),
                        Text('İş havuzu, kazanç ve teslimatlar tek hesapta.', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFE8F2FC), borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        Expanded(child: _mode(false, 'Giriş Yap')),
                        Expanded(child: _mode(true, 'Kurye Ol')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (register) ...[
                    TextField(controller: fullName, textCapitalization: TextCapitalization.words, decoration: _input('Ad Soyad', Icons.person_outline_rounded)),
                    const SizedBox(height: 10),
                    TextField(controller: phone, keyboardType: TextInputType.phone, decoration: _input('Telefon', Icons.phone_outlined)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: vehicleType,
                      decoration: _input('Araç tipi', Icons.two_wheeler_outlined),
                      items: const [
                        DropdownMenuItem(value: 'motorcycle', child: Text('Motosiklet')),
                        DropdownMenuItem(value: 'car', child: Text('Otomobil')),
                      ],
                      onChanged: (v) => setState(() => vehicleType = v ?? 'motorcycle'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: _input('E-posta', Icons.email_outlined),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    decoration: _input('Şifre', Icons.lock_outline_rounded).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    onSubmitted: register ? null : (_) => _submit(),
                  ),
                  if (register) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordAgain,
                      obscureText: obscure,
                      decoration: _input('Şifre Tekrar', Icons.lock_reset_rounded),
                    ),
                  ],
                  if (message != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFFF4DF), borderRadius: BorderRadius.circular(16)),
                      child: Text(message!, style: const TextStyle(color: Color(0xFF7A5A13), fontWeight: FontWeight.w700)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                      ),
                      icon: busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(register ? Icons.person_add_alt_1_rounded : Icons.login_rounded),
                      label: Text(busy ? 'İşleniyor...' : register ? 'Kurye Hesabı Oluştur' : 'Giriş Yap', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  if (register) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Yeni kurye hesabı varsayılan olarak onay bekler. Admin onayından sonra online olup iş havuzundan iş alabilirsin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 12, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mode(bool value, String label) {
    final selected = register == value;
    return InkWell(
      onTap: busy ? null : () => setState(() { register = value; message = null; }),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: selected ? const [BoxShadow(color: Color(0x10000000), blurRadius: 8)] : null,
        ),
        child: Text(label, style: TextStyle(color: selected ? navy : muted, fontWeight: FontWeight.w900)),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: blue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide.none),
      );
}
