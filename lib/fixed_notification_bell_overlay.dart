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
    final data = AppDataService.instance;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 14,
            child: SafeArea(
              top: false,
              left: false,
              bottom: false,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: data.client
                    .from('announcements')
                    .stream(primaryKey: ['id'])
                    .eq('is_active', true),
                builder: (context, snapshot) {
                  final count = (snapshot.data ?? const <Map<String, dynamic>>[])
                      .where((r) =>
                          r['audience'] == 'all' || r['audience'] == audience)
                      .length;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AnnouncementCenterPage(
                            audience: audience,
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .96),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 14,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Center(
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: Color(0xFF168CF5),
                                size: 27,
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                right: -2,
                                top: -3,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 19,
                                    minHeight: 19,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF4D67),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
