import 'package:flutter/foundation.dart';

class SiteModel {
  final String id, name, location;
  final String? description;
  final bool isActive;
  final int memberCount;
  const SiteModel({
    required this.id,
    required this.name,
    required this.location,
    this.description,
    this.isActive = true,
    this.memberCount = 0,
  });
  factory SiteModel.fromJson(Map<String, dynamic> json) {
    bool parseActive(dynamic v) {
      if (v == null) return true;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v.toLowerCase() == 'true';
      return true;
    }

    return SiteModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String?,
      isActive: parseActive(json['isActive']),
      memberCount: json['memberCount'] as int? ?? 0,
    );
  }
  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    if (description != null) 'description': description,
  };
}

// ── TaskStatus — added reviewRequested ───────────────────────────────────────

enum TaskStatus { pending, inProgress, reviewRequested, completed, onHold }

extension TaskStatusExt on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.reviewRequested:
        return 'Review Requested';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.onHold:
        return 'On Hold';
    }
  }

  String get apiValue {
    switch (this) {
      case TaskStatus.pending:
        return 'PENDING';
      case TaskStatus.inProgress:
        return 'IN_PROGRESS';
      case TaskStatus.reviewRequested:
        return 'REVIEW_REQUESTED';
      case TaskStatus.completed:
        return 'COMPLETED';
      case TaskStatus.onHold:
        return 'ON_HOLD';
    }
  }

  static TaskStatus fromApi(String v) {
    switch (v.toUpperCase()) {
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'REVIEW_REQUESTED':
        return TaskStatus.reviewRequested;
      case 'COMPLETED':
        return TaskStatus.completed;
      case 'ON_HOLD':
        return TaskStatus.onHold;
      default:
        return TaskStatus.pending;
    }
  }
}

// ── TaskModel ─────────────────────────────────────────────────────────────────

class TaskModel {
  final String id,
      siteId,
      title,
      assignedToId,
      assignedToName,
      assignedToEmployeeId,
      createdById;
  final String? description;
  final TaskStatus status;
  final DateTime createdAt;

  // 1. MUST HAVE THIS LINE
  final List<TaskImageModel> images;

  const TaskModel({
    required this.id,
    required this.siteId,
    required this.title,
    this.description,
    required this.status,
    required this.assignedToId,
    required this.assignedToName,
    required this.assignedToEmployeeId,
    required this.createdById,
    required this.createdAt,
    // 2. MUST HAVE THIS LINE
    this.images = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    try {
      final at = json['assignedTo'] as Map<String, dynamic>? ?? {};
      final site = json['site'] as Map<String, dynamic>? ?? {};
      final cb = json['createdBy'] as Map<String, dynamic>? ?? {};

      return TaskModel(
        id: json['id']?.toString() ?? '',
        siteId: site['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '(no title)',
        description: json['description']?.toString(),
        status: TaskStatusExt.fromApi(json['status']?.toString() ?? 'PENDING'),
        assignedToId: at['id']?.toString() ?? '',
        assignedToName: at['name']?.toString() ?? '(unassigned)',
        assignedToEmployeeId: at['employeeId']?.toString() ?? '',
        createdById: cb['id']?.toString() ?? '',
        createdAt: _parseDate(json['createdAt']),

        // 3. MUST HAVE THIS LINE to parse the images from the backend
        images:
            (json['images'] as List?)
                ?.map((e) => TaskImageModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e) {
      debugPrint('🚨 Failed to parse a task: $e');
      return TaskModel(
        id: 'error',
        siteId: '',
        title: 'Corrupted Data',
        status: TaskStatus.pending,
        assignedToId: '',
        assignedToName: 'Error',
        assignedToEmployeeId: '',
        createdById: '',
        createdAt: DateTime.now(),
      );
    }
  }

  // Add this helper function at the bottom of the file
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    if (date is List && date.length >= 3) {
      // Spring Boot's Jackson can serialize dates as an array of numbers
      // [year, month, day, hour, minute, second, nanosecond]
      return DateTime(
        date[0] as int,
        date[1] as int,
        date[2] as int,
        date.length > 3 ? date[3] as int : 0,
        date.length > 4 ? date[4] as int : 0,
        date.length > 5 ? date[5] as int : 0,
      );
    }
    return DateTime.now();
  }

  String get assigneeInitials {
    if (assignedToName.isEmpty || assignedToName == '(unassigned)') return '?';
    final p = assignedToName.trim().split(' ');
    if (p.isEmpty || p.first.isEmpty) return '?';
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return p[0][0].toUpperCase();
  }
}

// ── TaskImageModel ────────────────────────────────────────────────────────────

class TaskImageModel {
  final String id;
  final String imageUrl;

  const TaskImageModel({required this.id, required this.imageUrl});

  factory TaskImageModel.fromJson(Map<String, dynamic> json) {
    return TaskImageModel(
      id: json['id'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}

// ── Requests ──────────────────────────────────────────────────────────────────

class CreateTaskRequest {
  final String siteId, assignedToId, title;
  final String? description;
  const CreateTaskRequest({
    required this.siteId,
    required this.assignedToId,
    required this.title,
    this.description,
  });
  Map<String, dynamic> toJson() => {
    'siteId': siteId,
    'assignedToId': assignedToId,
    'title': title,
    if (description != null && description!.isNotEmpty)
      'description': description,
  };
}

class CreateSiteRequest {
  final String name, location;
  final String? description;
  const CreateSiteRequest({
    required this.name,
    required this.location,
    this.description,
  });
  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    if (description != null) 'description': description,
  };
}

// NEW — admin updates task description
class UpdateDescriptionRequest {
  final String? description;
  const UpdateDescriptionRequest({this.description});
  Map<String, dynamic> toJson() => {'description': description ?? ''};
}

// ── SiteMemberModel ───────────────────────────────────────────────────────────

class SiteMemberModel {
  final String id, employeeId, name, role;
  const SiteMemberModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.role,
  });

  factory SiteMemberModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('name') && json.containsKey('employeeId')) {
      return SiteMemberModel(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        name: json['name'] as String,
        role: json['role'] as String? ?? 'WORKER',
      );
    }
    final u = json['user'] as Map<String, dynamic>? ?? json;
    return SiteMemberModel(
      id: u['id'] as String,
      employeeId: u['employeeId'] as String,
      name: u['name'] as String,
      role: u['role'] as String? ?? 'WORKER',
    );
  }

  String get initials {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
