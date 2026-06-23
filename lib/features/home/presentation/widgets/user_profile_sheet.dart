import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class UserProfileSheet extends StatelessWidget {
  final Map<String, String?> user;
  const UserProfileSheet({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name       = user['name']       ?? '';
    final employeeId = user['employeeId'] ?? '';
    final role       = user['role']       ?? '';
    final status     = user['status']     ?? '';

    final parts    = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';

    final isAdmin    = role == 'ADMIN';
    final roleColor  = isAdmin ? AppColors.pending     : AppColors.inProgress;
    final roleBgColor = isAdmin ? AppColors.pendingBg  : AppColors.inProgressBg;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 0),
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Warm gradient header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF3E8), Color(0xFFF5E6D3)],
              ),
            ),
            child: Column(children: [
              // Avatar circle — dark brown bg, white text for contrast
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primaryLight, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(initials,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 14),

              // Name — dark on light bg
              Text(name,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),

              // Role pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: roleColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAdmin ? '⚙  Admin / Supervisor' : '👷  Worker',
                  style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ]),
          ),

          // Details section — white background, clear separation
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(children: [
              _DetailRow(
                icon: Icons.badge_outlined,
                label: 'Employee ID',
                value: employeeId,
                valueBg: AppColors.surfaceWarm,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.verified_user_outlined,
                label: 'Account Status',
                value: status,
                valueBg: status == 'ACTIVE'
                    ? const Color(0xFFEAF3DE)
                    : const Color(0xFFFAEEDA),
                valueColor: status == 'ACTIVE'
                    ? AppColors.completed
                    : AppColors.pending,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.work_outline_rounded,
                label: 'Role',
                value: role,
                valueBg: roleBgColor,
                valueColor: roleColor,
              ),
            ]),
          ),

          const SizedBox(height: 8),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),

          // Sign out button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.primaryDark, size: 18),
                label: Text('Sign Out',
                    style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context
                      .read<AuthBloc>()
                      .add(const AuthLogoutRequested());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueBg;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueBg,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      const SizedBox(width: 12),
      Text(label,
          style: GoogleFonts.lato(
              fontSize: 13, color: AppColors.textSecondary)),
      const Spacer(),
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: valueBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(value,
            style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary)),
      ),
    ]);
  }
}
