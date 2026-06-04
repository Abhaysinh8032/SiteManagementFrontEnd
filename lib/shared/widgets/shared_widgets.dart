import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/data/models/site_task_models.dart';

class AvatarCircle extends StatelessWidget {
  final String initials;
  final int colorIndex;
  final double size, fontSize;
  const AvatarCircle({super.key, required this.initials,
    this.colorIndex = 0, this.size = 36, this.fontSize = 13});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
        color: AppColors.avatarBg(colorIndex), shape: BoxShape.circle),
    child: Center(child: Text(initials, style: GoogleFonts.lato(
        fontSize: fontSize, fontWeight: FontWeight.w600,
        color: AppColors.avatarFg(colorIndex)))),
  );
}

class TaskStatusBadge extends StatelessWidget {
  final TaskStatus status;
  const TaskStatusBadge({super.key, required this.status});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: AppColors.statusBg(status), borderRadius: BorderRadius.circular(10)),
    child: Text(status.label, style: GoogleFonts.lato(
        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.statusColor(status))),
  );
}

class WarmLoadingIndicator extends StatelessWidget {
  const WarmLoadingIndicator({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5));
}

class EmptyState extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  const EmptyState({super.key, required this.title, required this.subtitle,
    this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 48, color: AppColors.textHint),
      const SizedBox(height: 12),
      Text(title, style: GoogleFonts.playfairDisplay(
          fontSize: 16, color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      Text(subtitle, style: GoogleFonts.lato(fontSize: 13, color: AppColors.textHint)),
    ]),
  );
}
