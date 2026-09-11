import 'package:flutter/material.dart';

class CourierBottomNav extends StatelessWidget {
  const CourierBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const orange = Color(0xFFFF5A1F);
  static const inactive = Color(0xFF687084);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final s = (width / 390).clamp(.92, 1.08).toDouble();
    final items = const [
      (Icons.layers_rounded, 'Havuz'),
      (Icons.work_outline_rounded, 'Atananlar'),
      (Icons.bar_chart_rounded, 'Kazançlar'),
      (Icons.person_rounded, 'Profil'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 68 * s,
        padding: EdgeInsets.fromLTRB(8 * s, 6 * s, 8 * s, 7 * s),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -3))],
        ),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: i == currentIndex ? null : () => onTap(i),
                  borderRadius: BorderRadius.circular(14 * s),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].$1, color: i == currentIndex ? orange : inactive, size: 20 * s),
                      SizedBox(height: 3 * s),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          color: i == currentIndex ? orange : inactive,
                          fontSize: 8.5 * s,
                          fontWeight: i == currentIndex ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 3 * s),
                      Container(
                        width: 30 * s,
                        height: 2.2 * s,
                        decoration: BoxDecoration(
                          color: i == currentIndex ? orange : Colors.transparent,
                          borderRadius: BorderRadius.circular(3 * s),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
