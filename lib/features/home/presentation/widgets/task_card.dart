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

  const TaskCard({
    super.key,
    required this.task,
    this.avatarColorIndex = 0,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    // Guard: show a clear error card if data is missing
    final hasData = task.title.isNotEmpty && task.title != '(no title)';

    return GestureDetector(
      onTap: isAdmin ? () => _showStatusMenu(context) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: AppColors.statusColor(task.status),
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: hasData ? _CardContent(task: task, avatarColorIndex: avatarColorIndex, isAdmin: isAdmin)
                        : _EmptyCardDebug(task: task),
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: _StatusSheet(task: task),
      ),
    );
  }
}

// ── Normal card content ───────────────────────────────────────────────────────

class _CardContent extends StatelessWidget {
  final TaskModel task;
  final int avatarColorIndex;
  final bool isAdmin;

  const _CardContent({
    required this.task,
    required this.avatarColorIndex,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with status dot
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                task.title,
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 6),
              Icon(Icons.edit_outlined, size: 14, color: AppColors.textHint),
            ],
          ],
        ),

        // Description
        if (task.description != null && task.description!.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            task.description!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],

        const SizedBox(height: 10),

        // Divider
        Container(height: 0.5, color: AppColors.divider),
        const SizedBox(height: 8),

        // Bottom row: avatar + name + status badge
        Row(
          children: [
            AvatarCircle(
              initials: task.assigneeInitials,
              colorIndex: avatarColorIndex,
              size: 24,
              fontSize: 9,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                task.assignedToName.isNotEmpty
                    ? task.assignedToName
                    : task.assignedToEmployeeId,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            TaskStatusBadge(status: task.status),
          ],
        ),
      ],
    );
  }
}

// ── Debug card shown when data is missing ─────────────────────────────────────
// This helps you see immediately that fromJson failed, instead of a blank card

class _EmptyCardDebug extends StatelessWidget {
  final TaskModel task;
  const _EmptyCardDebug({required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Text('Task data incomplete',
              style: GoogleFonts.lato(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange)),
        ]),
        const SizedBox(height: 4),
        Text('ID: ${task.id.isEmpty ? "missing" : task.id.substring(0, 8)}...',
            style: GoogleFonts.lato(fontSize: 10, color: AppColors.textHint)),
        Text('Check backend response format',
            style: GoogleFonts.lato(fontSize: 10, color: AppColors.textHint)),
      ],
    );
  }
}

// ── Status update bottom sheet ────────────────────────────────────────────────

class _StatusSheet extends StatelessWidget {
  final TaskModel task;
  const _StatusSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      TaskStatus.pending,
      TaskStatus.inProgress,
      TaskStatus.completed,
      TaskStatus.onHold,
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text('Update Status',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 17, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            task.title,
            style: GoogleFonts.lato(fontSize: 13, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Status options
          ...statuses.map((s) {
            final isSelected = task.status == s;
            return GestureDetector(
              onTap: () {
                context.read<HomeBloc>().add(HomeTaskStatusChanged(task.id, s));
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.statusColor(s).withOpacity(0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.statusColor(s) : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.statusColor(s),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.label,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.statusColor(s)
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.statusColor(s), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
