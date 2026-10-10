import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';

class VerifyEmailScreen extends StatelessWidget {
  final String? email;
  const VerifyEmailScreen({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.brand, size: 40),
              ),
              const SizedBox(height: 30),
              Text('Check your email',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(
                email == null
                    ? 'We sent you a verification link.'
                    : 'We sent a verification link to\n$email',
                style: GoogleFonts.inter(
                    fontSize: 15, height: 1.5, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/signin'),
                  child: const Text('Back to Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}