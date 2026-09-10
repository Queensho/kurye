import 'package:flutter/material.dart';

import 'announcement_center_page.dart';
import 'data/app_data_service.dart';

class FixedNotificationBellOverlay extends StatelessWidget {
  const FixedNotificationBellOverlay({
    super.key,
    required this.child,
    required this.audience,
  });

  final Widget child;
  final String audience;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: child),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          right: 14,
          child: _NotificationBell(
            audience: audience,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnnouncementCenterPage(audience: audience),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.audience, required this.onTap});

  final String audience;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = AppDataService.instance;
    final isCustomer = audience == 'customer';
    final bellColor = isCustomer ? const Color(0xFF171052) : const Color(0xFF168CF5);
    final badgeColor = isCustomer ? const Color(0xFFFF5A1F) : const Color(0xFFFF4D67);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: data.client
          .from('announcements')
          .stream(primaryKey: ['id'])
          .eq('is_active', true),
      builder: (context, snapshot) {
        final count = (snapshot.data ?? const <Map<String, dynamic>>[])
            .where((r) => r['audience'] == 'all' || r['audience'] == audience)
            .length;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .97),
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [
                  BoxShadow(color: Color(0x1B100A39), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(child: Icon(Icons.notifications_none_rounded, color: bellColor, size: 27)),
                  if (count > 0)
                    Positioned(
                      right: 4,
                      top: 3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                        padding: count > 1 ? const EdgeInsets.symmetric(horizontal: 3) : EdgeInsets.zero,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                        child: count > 1
                            ? Text(count > 9 ? '9+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900))
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
