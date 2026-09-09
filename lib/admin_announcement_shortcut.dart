import 'package:flutter/material.dart';

import 'admin_management_page.dart';
import 'announcement_center_page.dart';
import 'pricing_engine_admin_page.dart';

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
          bottom: 86,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'admin-pricing-engine-shortcut',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PricingEngineAdminPage()),
                  ),
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text('Fiyat Motoru', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'admin-management-shortcut',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminManagementPage()),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Yönetim', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'admin-announcement-shortcut',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminAnnouncementPage()),
                  ),
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Duyuru Gönder', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
