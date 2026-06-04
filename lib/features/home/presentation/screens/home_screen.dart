import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/site_task_models.dart';
import '../bloc/home_bloc.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/create_site_sheet.dart';
import '../widgets/user_profile_sheet.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  const HomeScreen({super.key, required this.role});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String?> _cachedUser = {};
  bool get isAdmin => widget.role == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _loadUser();
    context.read<HomeBloc>().add(const HomeSitesLoadRequested());
  }

  Future<void> _loadUser() async {
    final u = await SecureStorageService().getCachedUser();
    if (mounted) setState(() => _cachedUser = u);
  }

  String get _initials {
    final name = _cachedUser['name'] ?? '';
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) context.go(AppConstants.routeLogin);
      },
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final isWide = MediaQuery.of(context).size.width >= 600;
          return Scaffold(
            backgroundColor: AppColors.background,
            drawer: !isWide
                ? Drawer(
                    child: _Sidebar(
                      state: state,
                      isAdmin: isAdmin,
                      initials: _initials,
                      cachedUser: _cachedUser,
                    ),
                  )
                : null,
            body: SafeArea(
              child: isWide
                  ? Row(
                      children: [
                        SizedBox(
                          width: 220,
                          child: _Sidebar(
                            state: state,
                            isAdmin: isAdmin,
                            initials: _initials,
                            cachedUser: _cachedUser,
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          color: AppColors.divider,
                        ),
                        Expanded(
                          child: _MainArea(state: state, isAdmin: isAdmin),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _MobileBar(state: state, isAdmin: isAdmin),
                        Expanded(
                          child: _MainArea(state: state, isAdmin: isAdmin),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final HomeState state;
  final bool isAdmin;
  final String initials;
  final Map<String, String?> cachedUser;
  const _Sidebar({
    required this.state,
    required this.isAdmin,
    required this.initials,
    required this.cachedUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'SiteTracker',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              'MY SITES',
              style: GoogleFonts.lato(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: state.sitesLoading
                ? const WarmLoadingIndicator()
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: state.sites.length,
                    itemBuilder: (_, i) {
                      final site = state.sites[i];
                      final isSelected = state.selectedSite?.id == site.id;
                      return _SiteItem(
                        site: site,
                        isSelected: isSelected,
                        index: i,
                        onTap: () {
                          context.read<HomeBloc>().add(HomeSiteSelected(site));
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) => BlocProvider.value(
                      value: context.read<HomeBloc>(),
                      child: const CreateSiteBottomSheet(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'New Site',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Divider(color: AppColors.divider, height: 1),
          _UserFooter(initials: initials, cachedUser: cachedUser),
        ],
      ),
    );
  }
}

class _SiteItem extends StatelessWidget {
  final SiteModel site;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;
  const _SiteItem({
    required this.site,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  static const _dots = [
    AppColors.primary,
    Color(0xFF3B6D11),
    Color(0xFF185FA5),
    Color(0xFF993C1D),
    Color(0xFF534AB7),
  ];

  @override
  Widget build(BuildContext context) {
    final dot = _dots[index % _dots.length];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: EdgeInsets.fromLTRB(isSelected ? 0 : 6, 1, 6, 1),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceWarm : Colors.transparent,
        borderRadius: isSelected
            ? const BorderRadius.horizontal(right: Radius.circular(8))
            : BorderRadius.circular(8),
        border: isSelected
            ? const Border(left: BorderSide(color: AppColors.primary, width: 3))
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSelected ? 13 : 10,
          vertical: 0,
        ),
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        title: Text(
          site.name,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  final String initials;
  final Map<String, String?> cachedUser;
  const _UserFooter({required this.initials, required this.cachedUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cachedUser['name'] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  cachedUser['role'] ?? '',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => BlocProvider.value(
                value: context.read<AuthBloc>(),
                child: UserProfileSheet(user: cachedUser),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBar extends StatelessWidget {
  final HomeState state;
  final bool isAdmin;
  const _MobileBar({required this.state, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              state.selectedSite?.name ?? 'Select a site',
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isAdmin && state.selectedSite != null)
            TextButton.icon(
              icon: const Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: Text(
                'Task',
                style: GoogleFonts.lato(fontSize: 13, color: AppColors.primary),
              ),
              onPressed: () => _addTask(context, state),
            ),
        ],
      ),
    );
  }

  void _addTask(BuildContext context, HomeState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: AddTaskBottomSheet(
          siteId: state.selectedSite!.id,
          members: state.allUsers,
        ),
      ),
    );
  }
}

class _MainArea extends StatelessWidget {
  final HomeState state;
  final bool isAdmin;
  const _MainArea({required this.state, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    if (state.selectedSite == null && !state.sitesLoading) {
      return const EmptyState(
        title: 'No site selected',
        subtitle: 'Choose a site from the sidebar',
        icon: Icons.location_city_outlined,
      );
    }
    return Column(
      children: [
        if (MediaQuery.of(context).size.width >= 600) ...[
          _TopBar(state: state, isAdmin: isAdmin),
          const Divider(height: 1, color: AppColors.divider),
        ],
        Expanded(
          child: state.tasksLoading
              ? const WarmLoadingIndicator()
              : state.tasks.isEmpty
              ? EmptyState(
                  title: 'No tasks yet',
                  subtitle: isAdmin
                      ? 'Tap "Add Task" to create the first one'
                      : 'No tasks assigned yet',
                  icon: Icons.task_alt_outlined,
                )
              : _KanbanBoard(state: state, isAdmin: isAdmin),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final HomeState state;
  final bool isAdmin;
  const _TopBar({required this.state, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.selectedSite?.name ?? '',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (state.selectedSite?.location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 13,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        state.selectedSite!.location,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.people_outline,
                        size: 13,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${state.members.length} members',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isAdmin && state.selectedSite != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                'Add Task',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => BlocProvider.value(
                  value: context.read<HomeBloc>(),
                  child: AddTaskBottomSheet(
                    siteId: state.selectedSite!.id,
                    members: state.allUsers,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  final HomeState state;
  final bool isAdmin;
  const _KanbanBoard({required this.state, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 220 * 3 + 12 * 2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Col(
              title: 'Pending',
              tasks: state.pendingTasks,
              color: AppColors.pending,
              isAdmin: isAdmin,
            ),
            const SizedBox(width: 12),
            _Col(
              title: 'In Progress',
              tasks: state.inProgressTasks,
              color: AppColors.inProgress,
              isAdmin: isAdmin,
            ),
            const SizedBox(width: 12),
            _Col(
              title: 'Completed',
              tasks: state.completedTasks,
              color: AppColors.completed,
              isAdmin: isAdmin,
            ),
          ],
        ),
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String title;
  final List<TaskModel> tasks;
  final Color color;
  final bool isAdmin;
  const _Col({
    required this.title,
    required this.tasks,
    required this.color,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...tasks.asMap().entries.map(
            (e) => TaskCard(
              task: e.value,
              avatarColorIndex: e.key,
              isAdmin: isAdmin,
            ),
          ),
        ],
      ),
    );
  }
}
