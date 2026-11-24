import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;
  final String title;
  final String? subtitle;

  const BrandLogo({
    super.key,
    this.size = 54,
    this.showText = true,
    this.isDark = false,
    this.title = 'SMART FINANCE',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing Icon Badge
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFF9333EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.35),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Stylized Chart & Diamond
                Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: size * 0.58,
                ),
              ],
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : AppTheme.textDarkNavy,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
