import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/site_task_models.dart';
import '../../data/repositories/site_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override List<Object?> get props => [];
}

class HomeSitesLoadRequested extends HomeEvent {
  const HomeSitesLoadRequested();
}

class HomeSiteSelected extends HomeEvent {
  final SiteModel site;
  const HomeSiteSelected(this.site);
  @override List<Object?> get props => [site.id];
}

class HomeTaskCreateRequested extends HomeEvent {
  final CreateTaskRequest request;
  const HomeTaskCreateRequested(this.request);
  @override List<Object?> get props => [request];
}

class HomeSiteCreateRequested extends HomeEvent {
  final CreateSiteRequest request;
  const HomeSiteCreateRequested(this.request);
  @override List<Object?> get props => [request];
}

class HomeTaskStatusChanged extends HomeEvent {
  final String taskId;
  final TaskStatus newStatus;
  const HomeTaskStatusChanged(this.taskId, this.newStatus);
  @override List<Object?> get props => [taskId, newStatus];
}

// ── State ─────────────────────────────────────────────────────────────────────

class HomeState extends Equatable {
  final List<SiteModel>       sites;
  final SiteModel?            selectedSite;
  final List<TaskModel>       tasks;
  final List<SiteMemberModel> members;     // members of the selected site
  final List<SiteMemberModel> allUsers;    // ALL active users — for task assign dropdown
  final bool sitesLoading, tasksLoading, actionLoading;
  final String? errorMessage;

  const HomeState({
    this.sites        = const [],
    this.selectedSite,
    this.tasks        = const [],
    this.members      = const [],
    this.allUsers     = const [],
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
    bool?                  sitesLoading,
    bool?                  tasksLoading,
    bool?                  actionLoading,
    String?                errorMessage,
    bool                   clearError = false,
  }) => HomeState(
    sites:         sites         ?? this.sites,
    selectedSite:  selectedSite  ?? this.selectedSite,
    tasks:         tasks         ?? this.tasks,
    members:       members       ?? this.members,
    allUsers:      allUsers      ?? this.allUsers,
    sitesLoading:  sitesLoading  ?? this.sitesLoading,
    tasksLoading:  tasksLoading  ?? this.tasksLoading,
    actionLoading: actionLoading ?? this.actionLoading,
    errorMessage:  clearError ? null : (errorMessage ?? this.errorMessage),
  );

  List<TaskModel> get pendingTasks    => tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<TaskModel> get inProgressTasks => tasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<TaskModel> get completedTasks  => tasks.where((t) => t.status == TaskStatus.completed).toList();

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

  // ── Load sites + ALL active users in parallel ─────────────────────────────
  // ── FIX 4: allUsers now fetched from API, not copied from site members ─────
  Future<void> _onLoad(HomeSitesLoadRequested e, Emitter<HomeState> emit) async {
    debugPrint('[HomeBloc] HomeSitesLoadRequested — loading sites + all users');
    emit(state.copyWith(sitesLoading: true, clearError: true));
    try {
      // Fetch sites and all active users in parallel
      final results = await Future.wait([
        _repo.getSites(),
        _repo.getAllActiveUsers(),   // ← NEW: fetches /api/admin/users/active
      ]);

      final sites    = results[0] as List<SiteModel>;
      final allUsers = results[1] as List<SiteMemberModel>;

      debugPrint('[HomeBloc] ✓ Sites: ${sites.length}, All users: ${allUsers.length}');

      emit(state.copyWith(
        sites:        sites,
        allUsers:     allUsers,   // ← stored for task assignment dropdown
        sitesLoading: false,
      ));

      if (sites.isNotEmpty) {
        add(HomeSiteSelected(sites.first));
      }
    } catch (e) {
      debugPrint('[HomeBloc] ✗ ERROR in _onLoad: $e');
      emit(state.copyWith(
        sitesLoading: false,
        errorMessage: 'Failed to load data: $e',
      ));
    }
  }

  // ── Select site — loads tasks + site members (members ≠ allUsers) ─────────
  Future<void> _onSelect(HomeSiteSelected e, Emitter<HomeState> emit) async {
    debugPrint('[HomeBloc] HomeSiteSelected: ${e.site.name}');
    emit(state.copyWith(selectedSite: e.site, tasksLoading: true, tasks: []));
    try {
      // Load tasks and site-specific members in parallel
      final results = await Future.wait([
        _repo.getTasksForSite(e.site.id),
        _repo.getSiteMembers(e.site.id),
      ]);

      final tasks   = results[0] as List<TaskModel>;
      final members = results[1] as List<SiteMemberModel>;

      debugPrint('[HomeBloc] ✓ Tasks: ${tasks.length}, Site members: ${members.length}');
      debugPrint('[HomeBloc] ✓ allUsers in state: ${state.allUsers.length} (unchanged)');

      emit(state.copyWith(
        tasks:        tasks,
        members:      members,
        // allUsers is NOT reset here — it stays from _onLoad
        tasksLoading: false,
      ));
    } catch (e) {
      debugPrint('[HomeBloc] ✗ ERROR in _onSelect: $e');
      emit(state.copyWith(
        tasksLoading: false,
        errorMessage: 'Failed to load tasks: $e',
      ));
    }
  }

  Future<void> _onCreate(HomeTaskCreateRequested e, Emitter<HomeState> emit) async {
    emit(state.copyWith(actionLoading: true, clearError: true));
    try {
      final task = await _repo.createTask(e.request);
      emit(state.copyWith(tasks: [...state.tasks, task], actionLoading: false));
    } catch (e) {
      emit(state.copyWith(actionLoading: false, errorMessage: 'Failed to create task.'));
    }
  }

  Future<void> _onCreateSite(HomeSiteCreateRequested e, Emitter<HomeState> emit) async {
    emit(state.copyWith(actionLoading: true, clearError: true));
    try {
      final site    = await _repo.createSite(e.request);
      final updated = [...state.sites, site];
      emit(state.copyWith(sites: updated, actionLoading: false));
      add(HomeSiteSelected(site));
    } catch (e) {
      emit(state.copyWith(actionLoading: false, errorMessage: 'Failed to create site.'));
    }
  }

  Future<void> _onStatusChange(HomeTaskStatusChanged e, Emitter<HomeState> emit) async {
    try {
      final updated = await _repo.updateTaskStatus(e.taskId, e.newStatus);
      final tasks   = state.tasks.map((t) => t.id == e.taskId ? updated : t).toList();
      emit(state.copyWith(tasks: tasks));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update status.'));
    }
  }
}
