import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/app_data_service.dart';

class PromoBannerWidget extends StatelessWidget {
  final double height;
  final BorderRadius borderRadius;
  final String audience;
  const PromoBannerWidget({super.key, required this.height, required this.borderRadius, this.audience = 'customer'});

  @override
  Widget build(BuildContext context) {
    final stream = AppDataService.instance.client
        .from('promo_banners')
        .stream(primaryKey: ['id'])
        .order('sort_order')
        .order('created_at', ascending: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final now = DateTime.now().toUtc();
        final list = (snapshot.data ?? const <Map<String, dynamic>>[]).where((p) {
          if (p['is_active'] != true) return false;
          final target = (p['audience'] ?? 'customer').toString();
          if (target != 'all' && target != audience) return false;
          final start = DateTime.tryParse((p['starts_at'] ?? '').toString());
          final end = DateTime.tryParse((p['ends_at'] ?? '').toString());
          if (start != null && start.isAfter(now)) return false;
          if (end != null && end.isBefore(now)) return false;
          return true;
        }).toList();
        if (list.isEmpty) {
          return ClipRRect(
            borderRadius: borderRadius,
            child: SizedBox(height: height, width: double.infinity, child: Image.asset('assets/images/promo_hd.png', fit: BoxFit.cover)),
          );
        }
        final p = list.first;
        final image = (p['image_url'] ?? '').toString();
        final title = (p['title'] ?? '').toString();
        final subtitle = (p['subtitle'] ?? '').toString();
        final action = (p['action_label'] ?? '').toString();
        final url = (p['action_url'] ?? '').toString();
        return ClipRRect(
          borderRadius: borderRadius,
          child: Material(
            color: const Color(0xFF168CF5),
            child: InkWell(
              onTap: url.isEmpty ? null : () async {
                final uri = Uri.tryParse(url);
                if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: SizedBox(
                height: height,
                child: Stack(fit: StackFit.expand, children: [
                  if (image.isNotEmpty)
                    Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  if (image.isNotEmpty) Container(color: Colors.black.withValues(alpha: .16)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(children: [
                      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                        if (subtitle.isNotEmpty) ...[const SizedBox(height: 3), Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11))],
                      ])),
                      if (action.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Text(action, style: const TextStyle(color: Color(0xFF168CF5), fontWeight: FontWeight.w800, fontSize: 11))),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}