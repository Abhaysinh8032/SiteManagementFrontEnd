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
    final name       = user['name'] ?? '';
    final employeeId = user['employeeId'] ?? '';
    final role       = user['role'] ?? '';
    final status     = user['status'] ?? '';
    final parts      = name.trim().split(' ');
    final initials   = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(
            color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.surfaceWarm, shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryLight, width: 2)),
          child: Center(child: Text(initials, style: GoogleFonts.playfairDisplay(
              fontSize: 26, color: AppColors.primaryDark, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(height: 12),
        Text(name, style: GoogleFonts.playfairDisplay(
            fontSize: 20, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: role == 'ADMIN' ? AppColors.pendingBg : AppColors.inProgressBg,
            borderRadius: BorderRadius.circular(12)),
          child: Text(role, style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600,
              color: role == 'ADMIN' ? AppColors.pending : AppColors.inProgress)),
        ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 16),
        _Row(Icons.badge_outlined, 'Employee ID', employeeId),
        _Row(Icons.verified_user_outlined, 'Status', status),
        _Row(Icons.work_outline_rounded, 'Role', role),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded, color: AppColors.primaryDark, size: 18),
            label: Text('Sign out', style: GoogleFonts.lato(
                fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          )),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textSecondary),
      const SizedBox(width: 12),
      Text(label, style: GoogleFonts.lato(fontSize: 13, color: AppColors.textSecondary)),
      const Spacer(),
      Text(value, style: GoogleFonts.lato(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]),
  );
}
