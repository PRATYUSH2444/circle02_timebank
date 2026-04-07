import 'dart:ui';
import 'package:flutter/material.dart';

class NeonBackground extends StatelessWidget {
  final Widget child;

  const NeonBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔥 BASE DARK BACKGROUND
        Container(color: const Color(0xFF0D0D0D)),

        // 🔵 CYAN GLOW
        Positioned(
          top: 120,
          left: 40,
          child: _glowCircle(
            size: 100,
            color: const Color(0xFF00F5FF),
          ),
        ),

        // 🟣 PURPLE GLOW
        Positioned(
          bottom: 120,
          right: 40,
          child: _glowCircle(
            size: 120,
            color: const Color(0xFF7B61FF),
          ),
        ),

        // ✨ SOFT GLASS OVERLAY (IMPORTANT)
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: Colors.transparent,
          ),
        ),

        // 🧠 MAIN CONTENT
        child,
      ],
    );
  }

  // 🔥 CLEAN GLOW (PRO VERSION)
  Widget _glowCircle({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,

        // ✅ FIXED (no withOpacity)
        color: color.withValues(alpha: 0.12),

        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 100,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }
}