import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class OrgRegistrationScreen extends StatefulWidget {
  const OrgRegistrationScreen({super.key});
  @override
  State<OrgRegistrationScreen> createState() => _OrgRegistrationScreenState();
}

class _OrgRegistrationScreenState extends State<OrgRegistrationScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _category = 'college';

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Organization')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tell us about your space',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('This appears on the visitor app.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 28),
            _label('Organization Name'),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'e.g. Guru Nanak Dev Engineering College',
              ),
            ),
            const SizedBox(height: 20),
            _label('Description'),
            TextField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Short description visitors will see',
              ),
            ),
            const SizedBox(height: 20),
            _label('Category'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'college', 'hospital', 'mall', 'office', 'warehouse', 'public'
              ].map((c) {
                final selected = _category == c;
                return ChoiceChip(
                  label: Text(c[0].toUpperCase() + c.substring(1)),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: const Color(0xFF0D7377).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected
                        ? const Color(0xFF0D7377)
                        : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final name = _name.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a name')),
                    );
                    return;
                  }
                  context.read<AppState>().createOrganization(
                        name: name,
                        description: _desc.text.trim().isEmpty
                            ? 'Indoor space'
                            : _desc.text.trim(),
                        category: _category,
                      );
                  context.pushReplacement('/admin/grid-setup');
                },
                child: const Text('Continue to Map Setup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87)),
      );
}