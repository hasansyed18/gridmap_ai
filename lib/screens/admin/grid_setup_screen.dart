import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../state/app_state.dart';

class GridSetupScreen extends StatefulWidget {
  const GridSetupScreen({super.key});
  @override
  State<GridSetupScreen> createState() => _GridSetupScreenState();
}

class _GridSetupScreenState extends State<GridSetupScreen> {
  final _buildingName = TextEditingController(text: 'Main Block');

  @override
  void dispose() {
    _buildingName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Name Your Building')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text('What should we call this building?',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                'You\'ll get an infinite canvas to map it. No dimensions needed.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 28),
            TextField(
              controller: _buildingName,
              decoration: const InputDecoration(hintText: 'e.g. Block A'),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('INFINITE CANVAS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                          )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Zoom out to see more. Zoom in for detail. Paint rooms as you go — no upfront setup.',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white.withOpacity(0.95)),
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                context.read<AppState>().createBuilding(
                      buildingName: _buildingName.text.trim().isEmpty
                          ? 'Main Building'
                          : _buildingName.text.trim(),
                    );
                context.pushReplacement('/admin/editor');
              },
              child: const Text('Open Canvas'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}