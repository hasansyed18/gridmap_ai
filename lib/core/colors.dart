import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const brand = Color(0xFF0D7377);
  static const brandLight = Color(0xFF14B8A6);
  static const brandDark = Color(0xFF0A4F52);
  static const brandGlow = Color(0xFF2DD4BF);

  // Accent
  static const accent = Color(0xFFFFB703);
  static const accentSoft = Color(0xFFFFE9B3);

  // Neutrals
  static const ink = Color(0xFF0F172A);
  static const inkSoft = Color(0xFF64748B);
  static const inkFaint = Color(0xFF94A3B8);
  static const surface = Color(0xFFF8FAFC);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);

  // Cell type colors
  static const cellEmpty = Color(0xFFF1F5F9);
  static const cellWalkable = Color(0xFFB8E6D9);
  static const cellBlocked = Color(0xFF334155);
  static const cellRoom = Color(0xFF4DB6AC);
  static const cellCorridor = Color(0xFFFFD97D);
  static const cellStairs = Color(0xFFF87171);
  static const cellLift = Color(0xFFA78BFA);
  static const cellRamp = Color(0xFF38BDF8);
  static const cellEntrance = Color(0xFF34D399);
  static const cellExit = Color(0xFFEF4444);
  static const cellLandmark = Color(0xFFF472B6);
  static const cellWashroom = Color(0xFF60A5FA);

  // Gradients
  static const gradientPrimary = LinearGradient(
    colors: [brand, brandDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientHero = LinearGradient(
    colors: [Color(0xFF0D7377), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientAccent = LinearGradient(
    colors: [brandGlow, brand],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}