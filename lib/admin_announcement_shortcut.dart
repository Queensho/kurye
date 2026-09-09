import 'package:flutter/material.dart';

import 'announcement_center_page.dart';

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
            child: FloatingActionButton.extended(
              heroTag: 'admin-announcement-shortcut',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminAnnouncementPage()),
              ),
              icon: const Icon(Icons.notifications_active_rounded),
              label: const Text('Duyuru Gönder', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ],
    );
  }
}
