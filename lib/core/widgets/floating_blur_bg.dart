import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingBlurBackground extends StatelessWidget {
  final Widget child;

  const FloatingBlurBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8FAFC),
                Color(0xFFEFF6FF),
              ],
            ),
          ),
        ),

        // Floating circles
        Positioned(
          top: -80,
          left: -60,
          child: _BlurCircle(
            size: 240,
            color: const Color(0xFF2563EB).withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          bottom: -90,
          right: -70,
          child: _BlurCircle(
            size: 260,
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          top: 220,
          right: -40,
          child: _BlurCircle(
            size: 180,
            color: const Color(0xFF6366F1).withValues(alpha: 0.16),
          ),
        ),

        // Blur layer
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(color: Colors.transparent),
        ),

        // Your actual UI
        SafeArea(child: child),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
