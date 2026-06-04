import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/models/site_task_models.dart';
import '../bloc/home_bloc.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final int avatarColorIndex;
  final bool isAdmin;
  const TaskCard({super.key, required this.task,
    this.avatarColorIndex = 0, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: AppColors.statusColor(task.status), width: 3),
          top: const BorderSide(color: AppColors.divider, width: 0.5),
          right: const BorderSide(color: AppColors.divider, width: 0.5),
          bottom: const BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isAdmin ? () => _showStatusMenu(context) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, style: GoogleFonts.lato(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 8),
              Row(children: [
                AvatarCircle(initials: task.assigneeInitials,
                    colorIndex: avatarColorIndex, size: 22, fontSize: 9),
                const SizedBox(width: 5),
                Expanded(child: Text(task.assignedToName, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary))),
                TaskStatusBadge(status: task.status),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: _StatusSheet(task: task),
      ),
    );
  }
}

class _StatusSheet extends StatelessWidget {
  final TaskModel task;
  const _StatusSheet({required this.task});
  @override
  Widget build(BuildContext context) {
    final statuses = [TaskStatus.pending, TaskStatus.inProgress,
      TaskStatus.completed, TaskStatus.onHold];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Update task status', style: GoogleFonts.playfairDisplay(
              fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(task.title, style: GoogleFonts.lato(
              fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ...statuses.map((s) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(width: 4, height: 32, decoration: BoxDecoration(
                color: AppColors.statusColor(s), borderRadius: BorderRadius.circular(2))),
            title: Text(s.label, style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: task.status == s ? FontWeight.w700 : FontWeight.normal,
              color: task.status == s ? AppColors.statusColor(s) : AppColors.textPrimary)),
            trailing: task.status == s
                ? Icon(Icons.check_circle_rounded,
                    color: AppColors.statusColor(s), size: 20)
                : null,
            onTap: () {
              context.read<HomeBloc>().add(HomeTaskStatusChanged(task.id, s));
              Navigator.pop(context);
            },
          )),
        ]),
    );
  }
}
