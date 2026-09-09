import 'package:flutter/material.dart';

import 'admin_management_page.dart';
import 'admin_payouts_page.dart';
import 'announcement_center_page.dart';
import 'pricing_engine_admin_page.dart';
import 'service_region_map_admin_page.dart';

class AdminAnnouncementShortcut extends StatelessWidget {
  const AdminAnnouncementShortcut({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 18,
          bottom: 92,
          child: SafeArea(
            top: false,
            child: FloatingActionButton(
              heroTag: 'admin-tools-shortcut',
              onPressed: () => _openAdminTools(context),
              child: const Icon(Icons.grid_view_rounded),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAdminTools(BuildContext context) async {
    final page = await showModalBottomSheet<Widget>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        const navy = Color(0xFF10213E);
        const muted = Color(0xFF74839A);
        const blue = Color(0xFF168CF5);

        Widget item({
          required IconData icon,
          required String title,
          required String subtitle,
          required Widget page,
        }) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: blue),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: muted),
            onTap: () => Navigator.pop(sheetContext, page),
          );
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7DEE8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Admin Araçları',
                      style: TextStyle(
                        color: navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              item(
                icon: Icons.polyline_rounded,
                title: 'Bölge Haritası',
                subtitle: 'Servis bölgelerini haritada düzenle',
                page: const ServiceRegionMapAdminPage(),
              ),
              item(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Ödemeler',
                subtitle: 'Kurye ödeme taleplerini yönet',
                page: const AdminPayoutsPage(),
              ),
              item(
                icon: Icons.calculate_rounded,
                title: 'Fiyat Motoru',
                subtitle: 'Fiyat ve komisyon kurallarını yönet',
                page: const PricingEngineAdminPage(),
              ),
              item(
                icon: Icons.tune_rounded,
                title: 'Yönetim',
                subtitle: 'Kullanıcı, kurye ve operasyon ayarları',
                page: const AdminManagementPage(),
              ),
              item(
                icon: Icons.notifications_active_rounded,
                title: 'Duyuru Gönder',
                subtitle: 'Müşteri ve kuryelere duyuru yayınla',
                page: const AdminAnnouncementPage(),
              ),
            ],
          ),
        );
      },
    );

    if (page != null && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }
  }
}
