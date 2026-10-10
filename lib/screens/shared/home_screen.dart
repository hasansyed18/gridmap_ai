import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientHero),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Icon(Icons.grid_view_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Text('GridMap AI',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        )),
                    const Spacer(),
                    if (auth.isLoggedIn)
                      IconButton(
                        tooltip: 'Sign out',
                        icon: const Icon(Icons.logout,
                            color: Colors.white70),
                        onPressed: () async {
                          await context.read<AuthService>().signOut();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 60),
                Text(
                  auth.isLoggedIn
                      ? 'Welcome back.\nWhere to today?'
                      : 'Map any building.\nFrom your phone.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 36,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  auth.isLoggedIn
                      ? 'Choose how you want to use GridMap.'
                      : 'Indoor digital infrastructure — no CAD, no surveyors, no hardware.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                if (!auth.isLoggedIn) ...[
                  _RoleCard(
                    title: 'Sign In',
                    subtitle: 'Existing account',
                    icon: Icons.login,
                    gradient: AppColors.gradientAccent,
                    onTap: () => context.push('/signin'),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    title: 'Create Account',
                    subtitle: 'New to GridMap AI',
                    icon: Icons.person_add_alt,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    light: true,
                    onTap: () => context.push('/signup'),
                  ),
                ] else ...[
                  if (auth.isAdmin)
                    _RoleCard(
                      title: 'Admin Dashboard',
                      subtitle: 'Create and manage maps',
                      icon: Icons.architecture,
                      gradient: AppColors.gradientAccent,
                      onTap: () => context.push('/admin'),
                    ),
                  if (auth.isAdmin) const SizedBox(height: 14),
                  _RoleCard(
                    title: 'Visitor App',
                    subtitle: 'Find places indoors',
                    icon: Icons.explore_outlined,
                    gradient: auth.isAdmin
                        ? LinearGradient(colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ])
                        : AppColors.gradientAccent,
                    light: auth.isAdmin,
                   onTap: () => context.push('/visitor'),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final bool light;
  final VoidCallback onTap;
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.light = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: light
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(light ? 0.12 : 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75),
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.white.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}