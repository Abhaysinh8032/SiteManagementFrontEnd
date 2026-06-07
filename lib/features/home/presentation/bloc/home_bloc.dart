import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/site_task_models.dart';
import '../../data/repositories/site_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeSitesLoadRequested extends HomeEvent {
  const HomeSitesLoadRequested();
}

class HomeSiteSelected extends HomeEvent {
  final SiteModel site;
  const HomeSiteSelected(this.site);
  @override
  List<Object?> get props => [site.id];
}

class HomeTaskCreateRequested extends HomeEvent {
  final CreateTaskRequest request;
  const HomeTaskCreateRequested(this.request);
  @override
  List<Object?> get props => [request];
}

class HomeSiteCreateRequested extends HomeEvent {
  final CreateSiteRequest request;
  const HomeSiteCreateRequested(this.request);
  @override
  List<Object?> get props => [request];
}

class HomeTaskStatusChanged extends HomeEvent {
  final String taskId;
  final TaskStatus newStatus;
  const HomeTaskStatusChanged(this.taskId, this.newStatus);
  @override
  List<Object?> get props => [taskId, newStatus];
}

// ── State ─────────────────────────────────────────────────────────────────────

class HomeState extends Equatable {
  final List<SiteModel>       sites;
  final SiteModel?            selectedSite;
  final List<TaskModel>       tasks;
  final List<SiteMemberModel> members;
  final List<SiteMemberModel> allUsers;
  final bool sitesLoading, tasksLoading, actionLoading;
  final String? errorMessage;

  const HomeState({
    this.sites         = const [],
    this.selectedSite,
    this.tasks         = const [],
    this.members       = const [],
    this.allUsers      = const [],
    this.sitesLoading  = false,
    this.tasksLoading  = false,
    this.actionLoading = false,
    this.errorMessage,
  });

  HomeState copyWith({
    List<SiteModel>?       sites,
    SiteModel?             selectedSite,
    List<TaskModel>?       tasks,
    List<SiteMemberModel>? members,
    List<SiteMemberModel>? allUsers,
    bool?   sitesLoading,
    bool?   tasksLoading,
    bool?   actionLoading,
    String? errorMessage,
    bool    clearError = false,
  }) =>
      HomeState(
        sites:         sites         ?? this.sites,
        selectedSite:  selectedSite  ?? this.selectedSite,
        tasks:         tasks         ?? this.tasks,
        members:       members       ?? this.members,
        allUsers:      allUsers      ?? this.allUsers,
        sitesLoading:  sitesLoading  ?? this.sitesLoading,
        tasksLoading:  tasksLoading  ?? this.tasksLoading,
        actionLoading: actionLoading ?? this.actionLoading,
        errorMessage:
            clearError ? null : (errorMessage ?? this.errorMessage),
      );

  List<TaskModel> get pendingTasks =>
      tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<TaskModel> get inProgressTasks =>
      tasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<TaskModel> get completedTasks =>
      tasks.where((t) => t.status == TaskStatus.completed).toList();
  List<TaskModel> get onHoldTasks =>
      tasks.where((t) => t.status == TaskStatus.onHold).toList();

  @override
  List<Object?> get props => [
        sites, selectedSite, tasks, members, allUsers,
        sitesLoading, tasksLoading, actionLoading, errorMessage,
      ];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final SiteRepository _repo;

  HomeBloc({required SiteRepository repository})
      : _repo = repository,
        super(const HomeState()) {
    on<HomeSitesLoadRequested>(_onLoad);
    on<HomeSiteSelected>(_onSelect);
    on<HomeTaskCreateRequested>(_onCreate);
    on<HomeSiteCreateRequested>(_onCreateSite);
    on<HomeTaskStatusChanged>(_onStatusChange);
  }

  // ── _onLoad — FIXED ───────────────────────────────────────────────────────
  //
  // OLD (broken for worker):
  //   Future.wait([getSites(), getAllActiveUsers()])
  //   If getAllActiveUsers() returned 403 for a worker, Future.wait threw
  //   immediately and BOTH sites and allUsers failed — even though sites
  //   returned 200.
  //
  // NEW (resilient):
  //   Fetch sites first — always works for both roles.
  //   Then fetch allUsers separately with its own try/catch.
  //   If allUsers fails (e.g. 403), we log it and continue with empty list.
  //   Sites load correctly regardless.
  Future<void> _onLoad(
      HomeSitesLoadRequested e, Emitter<HomeState> emit) async {
    debugPrint('[HomeBloc] _onLoad started');
    emit(state.copyWith(sitesLoading: true, clearError: true));

    // ── Step 1: Load sites (works for both ADMIN and WORKER) ──────────────
    List<SiteModel> sites = [];
    try {
      sites = await _repo.getSites();
      debugPrint('[HomeBloc] ✓ Sites loaded: ${sites.length}');
    } catch (e) {
      debugPrint('[HomeBloc] ✗ Sites failed: $e');
      emit(state.copyWith(
          sitesLoading: false,
          errorMessage: 'Failed to load sites. Please try again.'));
      return;
    }

    // ── Step 2: Load all active users (fails gracefully for worker if still 403) ──
    List<SiteMemberModel> allUsers = [];
    try {
      allUsers = await _repo.getAllActiveUsers();
      debugPrint('[HomeBloc] ✓ All active users loaded: ${allUsers.length}');
    } catch (e) {
      // Non-fatal: worker may not have access. They can still see their tasks.
      // After backend fix (remove class-level @PreAuthorize from AdminController)
      // this will succeed for workers too.
      debugPrint('[HomeBloc] ⚠ getAllActiveUsers failed (worker may lack access): $e');
    }

    emit(state.copyWith(
      sites:        sites,
      allUsers:     allUsers,
      sitesLoading: false,
    ));

    if (sites.isNotEmpty) {
      debugPrint('[HomeBloc] Auto-selecting first site: ${sites.first.name}');
      add(HomeSiteSelected(sites.first));
    } else {
      debugPrint('[HomeBloc] ⚠ No sites returned. '
          'Worker may not be assigned to any site yet.');
    }
  }

  // ── _onSelect — loads tasks + site members ────────────────────────────────
  Future<void> _onSelect(
      HomeSiteSelected e, Emitter<HomeState> emit) async {
    debugPrint('[HomeBloc] Site selected: ${e.site.name}');
    emit(state.copyWith(
        selectedSite: e.site, tasksLoading: true, tasks: []));
    try {
      final results = await Future.wait([
        _repo.getTasksForSite(e.site.id),
        _repo.getSiteMembers(e.site.id),
      ]);
      final tasks   = results[0] as List<TaskModel>;
      final members = results[1] as List<SiteMemberModel>;
      debugPrint(
          '[HomeBloc] ✓ Tasks: ${tasks.length}, Members: ${members.length}');
      emit(state.copyWith(
        tasks:        tasks,
        members:      members,
        tasksLoading: false,
        // allUsers intentionally NOT overwritten here
      ));
    } catch (e) {
      debugPrint('[HomeBloc] ✗ _onSelect error: $e');
      emit(state.copyWith(
          tasksLoading: false,
          errorMessage: 'Failed to load tasks: $e'));
    }
  }

  Future<void> _onCreate(
      HomeTaskCreateRequested e, Emitter<HomeState> emit) async {
    debugPrint('[HomeBloc] Creating task: ${e.request.title}');
    emit(state.copyWith(actionLoading: true, clearError: true));
    try {
      await _repo.createTask(e.request);
      final freshTasks =
          await _repo.getTasksForSite(state.selectedSite!.id);
      debugPrint('[HomeBloc] ✓ Task created. Reloaded ${freshTasks.length} tasks');
      emit(state.copyWith(tasks: freshTasks, actionLoading: false));
    } catch (e) {
      debugPrint('[HomeBloc] ✗ Create task error: $e');
      emit(state.copyWith(
          actionLoading: false,
          errorMessage: 'Failed to create task: $e'));
    }
  }

  Future<void> _onCreateSite(
      HomeSiteCreateRequested e, Emitter<HomeState> emit) async {
    emit(state.copyWith(actionLoading: true, clearError: true));
    try {
      final site    = await _repo.createSite(e.request);
      final updated = [...state.sites, site];
      emit(state.copyWith(sites: updated, actionLoading: false));
      add(HomeSiteSelected(site));
    } catch (e) {
      emit(state.copyWith(
          actionLoading: false,
          errorMessage: 'Failed to create site.'));
    }
  }

  Future<void> _onStatusChange(
      HomeTaskStatusChanged e, Emitter<HomeState> emit) async {
    try {
      final updated =
          await _repo.updateTaskStatus(e.taskId, e.newStatus);
      final tasks =
          state.tasks.map((t) => t.id == e.taskId ? updated : t).toList();
      emit(state.copyWith(tasks: tasks));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update status.'));
    }
  }
}
