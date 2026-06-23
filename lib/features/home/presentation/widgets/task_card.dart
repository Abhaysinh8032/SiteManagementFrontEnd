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
    final hasData = task.title.isNotEmpty && task.title != '(no title)';

    return GestureDetector(
      // FIXED: Now both Admins and Workers can tap the card to update status
      onTap: () => _showStatusMenu(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.statusColor(task.status),
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: hasData
                  ? _CardContent(
                      task: task,
                      avatarColorIndex: avatarColorIndex,
                      isAdmin: isAdmin,
                    )
                  : _EmptyCardDebug(task: task),
            ),
          ),
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
        child: _StatusSheet(task: task, isAdmin: isAdmin), // Pass isAdmin down
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
        Container(height: 0.5, color: AppColors.divider),
        const SizedBox(height: 8),
        Row(
          children: [
            // FIXED: Removed the AvatarCircle DP as requested and added a clean icon
            const Icon(
              Icons.person_outline,
              size: 14,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 4),
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

class _EmptyCardDebug extends StatelessWidget {
  final TaskModel task;
  const _EmptyCardDebug({required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              'Task data incomplete',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ID: ${task.id.isEmpty ? "missing" : task.id.substring(0, 8)}...',
          style: GoogleFonts.lato(fontSize: 10, color: AppColors.textHint),
        ),
        Text(
          'Check backend response format',
          style: GoogleFonts.lato(fontSize: 10, color: AppColors.textHint),
        ),
      ],
    );
  }
}

// ── Status update bottom sheet ────────────────────────────────────────────────

class _StatusSheet extends StatelessWidget {
  final TaskModel task;
  final bool isAdmin;

  const _StatusSheet({required this.task, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    // FIXED: Admin gets all statuses. Workers only get Pending, InProgress, ReviewRequested
    // This perfectly matches your Spring Boot TaskService backend logic!
    final statuses = isAdmin
        ? [
            TaskStatus.pending,
            TaskStatus.inProgress,
            TaskStatus.reviewRequested,
            TaskStatus.completed,
            TaskStatus.onHold,
          ]
        : [
            TaskStatus.pending,
            TaskStatus.inProgress,
            TaskStatus.reviewRequested,
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
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Update Status',
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            task.title,
            style: GoogleFonts.lato(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.statusColor(s).withOpacity(0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.statusColor(s)
                        : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
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
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.statusColor(s)
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.statusColor(s),
                        size: 20,
                      ),
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
// ── Task action sheet — status + description edit ─────────────────────────────

class _TaskActionSheet extends StatefulWidget {
  final TaskModel task;
  final bool isAdmin;
  const _TaskActionSheet({required this.task, required this.isAdmin});
  @override
  State<_TaskActionSheet> createState() => _TaskActionSheetState();
}

class _TaskActionSheetState extends State<_TaskActionSheet> {
  bool _editingDescription = false;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.task.description ?? '');
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  // Statuses a worker can pick
  static const _workerStatuses = [
    TaskStatus.pending,
    TaskStatus.inProgress,
    TaskStatus.onHold,
    TaskStatus.reviewRequested, // worker submits for admin review
  ];

  // Admin sees all statuses including completed
  static const _adminStatuses = [
    TaskStatus.pending,
    TaskStatus.inProgress,
    TaskStatus.onHold,
    TaskStatus.reviewRequested,
    TaskStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final statuses = widget.isAdmin ? _adminStatuses : _workerStatuses;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Task title
              Text(
                widget.task.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isAdmin
                    ? 'Tap a status to update · Edit description below'
                    : 'Tap a status to update · Use "Review Requested" when done',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 16),

              // Status options
              Text(
                'Update Status',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),

              ...statuses.map((s) {
                final isSelected = widget.task.status == s;
                final isCompletedForWorker =
                    s == TaskStatus.completed && !widget.isAdmin;
                return GestureDetector(
                  onTap: isCompletedForWorker
                      ? null
                      : () {
                          context.read<HomeBloc>().add(
                            HomeTaskStatusChanged(widget.task.id, s),
                          );
                          Navigator.pop(context);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.statusColor(s).withOpacity(0.08)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.statusColor(s)
                            : AppColors.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isCompletedForWorker
                                ? AppColors.textHint
                                : AppColors.statusColor(s),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.label,
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: isCompletedForWorker
                                      ? AppColors.textHint
                                      : isSelected
                                      ? AppColors.statusColor(s)
                                      : AppColors.textPrimary,
                                ),
                              ),
                              // Hint for Review Requested
                              if (s == TaskStatus.reviewRequested)
                                Text(
                                  'Notify admin your work is ready for review',
                                  style: GoogleFonts.lato(
                                    fontSize: 10,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              // Hint: completed locked for worker
                              if (isCompletedForWorker)
                                Text(
                                  'Admin only',
                                  style: GoogleFonts.lato(
                                    fontSize: 10,
                                    color: AppColors.textHint,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.statusColor(s),
                            size: 20,
                          ),
                        if (isCompletedForWorker)
                          const Icon(
                            Icons.lock_outline,
                            color: AppColors.textHint,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                );
              }),

              // Description edit — admin only
              if (widget.isAdmin) ...[
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Description',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(
                        () => _editingDescription = !_editingDescription,
                      ),
                      child: Text(
                        _editingDescription ? 'Cancel' : 'Edit',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_editingDescription) ...[
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    autofocus: true,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add task description...',
                      hintStyle: GoogleFonts.lato(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<HomeBloc>().add(
                          HomeTaskDescriptionUpdated(
                            widget.task.id,
                            _descCtrl.text.trim().isEmpty
                                ? null
                                : _descCtrl.text.trim(),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Description',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else
                  Text(
                    widget.task.description?.isNotEmpty == true
                        ? widget.task.description!
                        : 'No description. Tap Edit to add one.',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: widget.task.description?.isNotEmpty == true
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                      fontStyle: widget.task.description?.isNotEmpty == true
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
