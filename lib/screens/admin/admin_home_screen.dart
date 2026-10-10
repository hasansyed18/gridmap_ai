import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../services/auth_service.dart';
import '../../services/map_service.dart';
import '../../state/app_state.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  Future<void> _hydrate() async {
    final state = context.read<AppState>();
    final auth = context.read<AuthService>();
    if (state.organization != null) {
      setState(() => _loading = false);
      return;
    }
    if (!auth.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      final org = await MapService.loadAdminOrg(auth.user!.id);
      if (!mounted) return;
      if (org != null) {
        state.hydrate(org: org);
      }
    } catch (_) {
      // ignore
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasOrg = state.hasOrganization;
    final hasMap = state.hasMap;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SingleChildScrollView(
  padding: const EdgeInsets.all(20),
  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasOrg) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Organization',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.5,
                        )),
                    const SizedBox(height: 8),
                    Text(state.organization!.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 4),
                    Text(state.organization!.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.75),
                        )),
                    if (state.organization!.buildings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${state.organization!.buildings.first.floors.length} floor(s) · ${state.currentFloor?.cells.length ?? 0} cells',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text('Quick actions',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (!hasOrg)
              _ActionCard(
                icon: Icons.business_center_outlined,
                title: 'Register Organization',
                subtitle: 'Set name, description, and location',
                onTap: () => context.push('/admin/register'),
              ),
            if (hasOrg && !hasMap)
              _ActionCard(
                icon: Icons.grid_4x4,
                title: 'Create Map',
                subtitle: 'Name a building, start mapping',
                onTap: () => context.push('/admin/grid-setup'),
              ),
            if (hasMap) ...[
              _ActionCard(
                icon: Icons.edit_location_alt_outlined,
                title: 'Continue Editing',
                subtitle:
                    '${state.currentFloor!.rooms.length} rooms · ${state.currentFloor!.cells.length} cells',
                onTap: () => context.push('/admin/editor'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.add_home_work_outlined,
                title: 'Add New Floor',
                subtitle: 'Stack another floor',
                onTap: () {
                  state.addFloor();
                  context.push('/admin/editor');
                },
              ),
            ],
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.add_business_outlined,
              title: 'New Building',
              subtitle: hasOrg
                  ? 'Create another building under this org'
                  : 'Register an organization first',
              onTap: hasOrg
                  ? () => context.push('/admin/grid-setup')
                  : () => context.push('/admin/register'),
            ),
           const SizedBox(height: 24),
TextButton.icon(
              onPressed: () async {
                state.reset();
                await context.read<AuthService>().signOut();
                if (context.mounted) context.go('/');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out & Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.brand, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}