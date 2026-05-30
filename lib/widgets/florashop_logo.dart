import 'package:flutter/material.dart';

class FloraShopLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const FloraShopLogo({
    super.key,
    this.size = 56,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.24);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFFB11E5C).withValues(alpha: 0.24),
                  blurRadius: size * 0.34,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/icons/app_icon.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5C9D), Color(0xFFE21666)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: radius,
          ),
          child: Icon(
            Icons.local_florist_rounded,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
