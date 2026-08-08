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
import '../widgets/global_add_task_sheet.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/network/api_client.dart';

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
    _setupPushNotifications(); // <-- ADD THIS
  }

  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission (triggers prompt on iOS, required for Android 13+)
    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      final u = await SecureStorageService().getCachedUser();
      final userId = u['id'] ?? u['userId'];

      if (token != null && userId != null) {
        try {
          // Send the token to the new Spring Boot endpoint
          await ApiClient.instance.dio.patch(
            '/api/users/$userId/fcm-token',
            data: {'fcmToken': token},
          );
        } catch (e) {
          debugPrint('Failed to sync FCM token: $e');
        }
      }
    }
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
      child: BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (prev, curr) =>
            curr.errorMessage != null && curr.errorMessage != prev.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
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
                        // FIX 1: MobileBar has NO add task button — removed
                        _MobileBar(state: state),
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

// ── Sidebar ───────────────────────────────────────────────────────────────────

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
                : state.sites.isEmpty
                ? const EmptyState(
                    title: 'No sites yet',
                    subtitle: 'Create a site to get started',
                    icon: Icons.location_city_outlined,
                  )
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
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  ),
          ),

          // FIXED: Admin section now correctly stacks BOTH buttons!
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // 1. New Site Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.add_location_alt_rounded,
                        size: 16,
                      ),
                      label: const Text('New Site'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => BlocProvider.value(
                            value: context.read<HomeBloc>(),
                            child: const CreateSiteBottomSheet(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 2. Global New Task Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: const Text('New Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => BlocProvider.value(
                            value: context.read<HomeBloc>(),
                            child: GlobalAddTaskBottomSheet(
                              sites: state.sites,
                              members: state.allUsers,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
        contentPadding: EdgeInsets.symmetric(horizontal: isSelected ? 13 : 10),
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
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
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

// ── FIX 1: MobileBar — NO add task button ────────────────────────────────────

class _MobileBar extends StatelessWidget {
  final HomeState state;
  const _MobileBar({required this.state});

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
          // No add task button here — only in _TopBar below
        ],
      ),
    );
  }
}

// ── Main area ─────────────────────────────────────────────────────────────────

class _MainArea extends StatelessWidget {
  final HomeState state;
  final bool isAdmin;
  const _MainArea({required this.state, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    if (state.sitesLoading) return const WarmLoadingIndicator();
    if (state.selectedSite == null) {
      return const EmptyState(
        title: 'No site selected',
        subtitle: 'Choose a site from the menu',
        icon: Icons.location_city_outlined,
      );
    }
    return Column(
      children: [
        _TopBar(state: state, isAdmin: isAdmin),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: state.tasksLoading
              ? const WarmLoadingIndicator()
              : _TaskTabs(state: state, isAdmin: isAdmin),
        ),
      ],
    );
  }
}

// ── Top bar — single "Add Task" button for admin ──────────────────────────────

class _TopBar extends StatelessWidget {
  final HomeState state;
  final bool isAdmin;

  const _TopBar({required this.state, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.selectedSite?.name ?? '',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (state.selectedSite?.location != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          state.selectedSite!.location,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.people_outline,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${state.members.length} members',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (isAdmin)
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 15),
              label: Text(
                'Task',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
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
// ── Task tabs — 5 tabs including Review Requested ─────────────────────────────

class _TaskTabs extends StatefulWidget {
  final HomeState state;
  final bool isAdmin;
  const _TaskTabs({required this.state, required this.isAdmin});
  @override
  State<_TaskTabs> createState() => _TaskTabsState();
}

class _TaskTabsState extends State<_TaskTabs> with TickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.lato(fontSize: 12),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabs: [
              _TabChip('Pending', s.pendingTasks.length, AppColors.pending),
              _TabChip(
                'In Progress',
                s.inProgressTasks.length,
                AppColors.inProgress,
              ),
              _TabChip(
                'Review',
                s.reviewTasks.length,
                Colors.purple,
              ), // Added Review!
              _TabChip(
                'Completed',
                s.completedTasks.length,
                AppColors.completed,
              ),
              _TabChip('On Hold', s.onHoldTasks.length, AppColors.onHold),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _TaskList(tasks: s.pendingTasks, isAdmin: widget.isAdmin),
              _TaskList(tasks: s.inProgressTasks, isAdmin: widget.isAdmin),
              _TaskList(
                tasks: s.reviewTasks,
                isAdmin: widget.isAdmin,
              ), // Added Review!
              _TaskList(tasks: s.completedTasks, isAdmin: widget.isAdmin),
              _TaskList(tasks: s.onHoldTasks, isAdmin: widget.isAdmin),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _TabChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final bool isAdmin;
  const _TaskList({required this.tasks, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return EmptyState(
        title: 'No tasks here',
        subtitle: isAdmin
            ? 'Tap "+ Add Task" to create one'
            : 'No tasks in this status',
        icon: Icons.check_circle_outline,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: tasks.length,
      itemBuilder: (_, i) =>
          TaskCard(task: tasks[i], avatarColorIndex: i, isAdmin: isAdmin),
    );
  }
}
