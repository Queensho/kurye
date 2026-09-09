import 'package:flutter/material.dart';

import 'announcement_center_page.dart';
import 'data/app_data_service.dart';

class FixedNotificationBellOverlay extends StatefulWidget {
  const FixedNotificationBellOverlay({
    super.key,
    required this.child,
    required this.audience,
  });

  final Widget child;
  final String audience;

  @override
  State<FixedNotificationBellOverlay> createState() =>
      _FixedNotificationBellOverlayState();
}

class _FixedNotificationBellOverlayState extends State<FixedNotificationBellOverlay> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _mountOverlay());
  }

  @override
  void didUpdateWidget(covariant FixedNotificationBellOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audience != widget.audience) {
      _removeOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) => _mountOverlay());
    } else {
      _entry?.markNeedsBuild();
    }
  }

  void _mountOverlay() {
    if (!mounted || _entry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: MediaQuery.of(overlayContext).padding.top + 12,
        right: 14,
        child: _NotificationBell(
          audience: widget.audience,
          onTap: () {
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnnouncementCenterPage(audience: widget.audience),
              ),
            );
          },
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.audience, required this.onTap});

  final String audience;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = AppDataService.instance;
    return SafeArea(
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
              .where((r) => r['audience'] == 'all' || r['audience'] == audience)
              .length;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
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
                          padding: const EdgeInsets.symmetric(horizontal: 4),
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
    );
  }
}
