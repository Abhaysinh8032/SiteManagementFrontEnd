import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart'; // <-- ADDED THIS IMPORT
import '../../data/models/site_task_models.dart';
import '../../data/repositories/site_repository.dart';

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

class HomeTaskDescriptionUpdated extends HomeEvent {
  final String taskId;
  final String? description;
  const HomeTaskDescriptionUpdated(this.taskId, this.description);
  @override
  List<Object?> get props => [taskId, description];
}

class HomeTaskImagesUploadRequested extends HomeEvent {
  final String taskId;
  final List<XFile> files;

  const HomeTaskImagesUploadRequested(this.taskId, this.files);

  @override
  List<Object?> get props => [taskId, files];
}

class HomeState extends Equatable {
  final List<SiteModel> sites;
  final SiteModel? selectedSite;
  final List<TaskModel> tasks;
  final List<SiteMemberModel> members;
  final List<SiteMemberModel> allUsers;
  final bool sitesLoading, tasksLoading, actionLoading;
  final String? errorMessage;
  const HomeState({
    this.sites = const [],
    this.selectedSite,
    this.tasks = const [],
    this.members = const [],
    this.allUsers = const [],
    this.sitesLoading = false,
    this.tasksLoading = false,
    this.actionLoading = false,
    this.errorMessage,
  });

  HomeState copyWith({
    List<SiteModel>? sites,
    SiteModel? selectedSite,
    List<TaskModel>? tasks,
    List<SiteMemberModel>? members,
    List<SiteMemberModel>? allUsers,
    bool? sitesLoading,
    bool? tasksLoading,
    bool? actionLoading,
    String? errorMessage,
    bool clearError = false,
  }) => HomeState(
    sites: sites ?? this.sites,
    selectedSite: selectedSite ?? this.selectedSite,
    tasks: tasks ?? this.tasks,
    members: members ?? this.members,
    allUsers: allUsers ?? this.allUsers,
    sitesLoading: sitesLoading ?? this.sitesLoading,
    tasksLoading: tasksLoading ?? this.tasksLoading,
    actionLoading: actionLoading ?? this.actionLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  List<TaskModel> get pendingTasks =>
      tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<TaskModel> get inProgressTasks =>
      tasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<TaskModel> get reviewTasks =>
      tasks.where((t) => t.status == TaskStatus.reviewRequested).toList();
  List<TaskModel> get completedTasks =>
      tasks.where((t) => t.status == TaskStatus.completed).toList();
  List<TaskModel> get onHoldTasks =>
      tasks.where((t) => t.status == TaskStatus.onHold).toList();

  @override
  List<Object?> get props => [
    sites,
    selectedSite,
    tasks,
    members,
    allUsers,
    sitesLoading,
    tasksLoading,
    actionLoading,
    errorMessage,
  ];
}

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
    on<HomeTaskDescriptionUpdated>(_onUpdateDescription);
    on<HomeTaskImagesUploadRequested>(
      _onUploadTaskImages,
    ); // <-- ADDED THIS LISTENER
  }

  Future<void> _onLoad(
    HomeSitesLoadRequested e,
    Emitter<HomeState> emit,
  ) async {
    debugPrint('[HomeBloc] _onLoad');
    emit(state.copyWith(sitesLoading: true, clearError: true));
    List<SiteModel> sites = [];
    try {
      sites = await _repo.getSites();
      debugPrint('[HomeBloc] ✓ Sites: ${sites.length}');
    } catch (e) {
      emit(
        state.copyWith(
          sitesLoading: false,
          errorMessage: 'Failed to load sites.',
        ),
      );
      return;
    }
    List<SiteMemberModel> allUsers = [];
    try {
      allUsers = await _repo.getAllActiveUsers();
      debugPrint('[HomeBloc] ✓ AllUsers: ${allUsers.length}');
    } catch (e) {
      debugPrint('[HomeBloc] ⚠ getAllActiveUsers failed: $e');
    }
    emit(state.copyWith(sites: sites, allUsers: allUsers, sitesLoading: false));
    if (sites.isNotEmpty) add(HomeSiteSelected(sites.first));
  }

  Future<void> _onSelect(HomeSiteSelected e, Emitter<HomeState> emit) async {
    debugPrint('[HomeBloc] Site selected: ${e.site.name}');
    emit(
      state.copyWith(
        selectedSite: e.site,
        tasksLoading: true,
        tasks: [],
        clearError: true,
      ),
    );

    List<TaskModel> fetchedTasks = [];
    List<SiteMemberModel> fetchedMembers = [];

    try {
      fetchedTasks = await _repo.getTasksForSite(e.site.id);
      debugPrint('[HomeBloc] ✓ Tasks loaded: ${fetchedTasks.length}');
    } catch (e) {
      debugPrint('[HomeBloc] ✗ Task fetch error: $e');
      emit(
        state.copyWith(
          tasksLoading: false,
          errorMessage: 'Failed to load tasks.',
        ),
      );
      return;
    }

    try {
      fetchedMembers = await _repo.getSiteMembers(e.site.id);
    } catch (e) {
      debugPrint(
        '[HomeBloc] ⚠ Member fetch failed (Worker may lack access): $e',
      );
    }

    emit(
      state.copyWith(
        tasks: fetchedTasks,
        members: fetchedMembers,
        tasksLoading: false,
      ),
    );
  }

  Future<void> _onCreate(
    HomeTaskCreateRequested e,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(actionLoading: true, clearError: true));
    try {
      await _repo.createTask(e.request);
      final fresh = await _repo.getTasksForSite(state.selectedSite!.id);
      emit(state.copyWith(tasks: fresh, actionLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: 'Failed to create task: $e',
        ),
      );
    }
  }

  Future<void> _onCreateSite(
    HomeSiteCreateRequested e,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(actionLoading: true, clearError: true));
    try {
      final newSite = await _repo.createSite(e.request);
      debugPrint('[HomeBloc] ✓ Site created: ${newSite.name}');
      final updatedSites = await _repo.getSites();
      emit(state.copyWith(sites: updatedSites, actionLoading: false));
      add(HomeSiteSelected(newSite));
    } catch (e) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: 'Failed to create site: $e',
        ),
      );
    }
  }

  Future<void> _onStatusChange(
    HomeTaskStatusChanged e,
    Emitter<HomeState> emit,
  ) async {
    try {
      final updated = await _repo.updateTaskStatus(e.taskId, e.newStatus);
      final tasks = state.tasks
          .map((t) => t.id == e.taskId ? updated : t)
          .toList();
      emit(state.copyWith(tasks: tasks));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update status: $e'));
    }
  }

  Future<void> _onUpdateDescription(
    HomeTaskDescriptionUpdated e,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(actionLoading: true, clearError: true));
    try {
      final updated = await _repo.updateTaskDescription(
        e.taskId,
        e.description,
      );
      final tasks = state.tasks
          .map((t) => t.id == e.taskId ? updated : t)
          .toList();
      emit(state.copyWith(tasks: tasks, actionLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: 'Failed to update description.',
        ),
      );
    }
  }

  // <-- ADDED THIS UPLOAD HANDLER METHOD
  Future<void> _onUploadTaskImages(
    HomeTaskImagesUploadRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(state.copyWith(actionLoading: true));
      final responseTask = await _repo.uploadTaskImages(
        event.taskId,
        event.files,
      );

      final updatedTasks = state.tasks.map((existingTask) {
        if (existingTask.id == event.taskId) {
          return TaskModel(
            id: existingTask.id,
            siteId: existingTask.siteId,
            title: existingTask.title,
            description: existingTask.description,
            status: existingTask.status,
            assignedToId: existingTask.assignedToId,
            assignedToName: existingTask.assignedToName,
            assignedToEmployeeId: existingTask.assignedToEmployeeId,
            createdById: existingTask.createdById,
            createdAt: existingTask.createdAt,
            images: responseTask.images,
          );
        }
        return existingTask;
      }).toList();

      emit(state.copyWith(tasks: updatedTasks, actionLoading: false));
    } catch (e) {
      debugPrint('[HomeBloc] Failed to upload images: $e');
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: 'Failed to upload images. Please try again.',
        ),
      );
    }
  }
}
