import 'package:flutter/foundation.dart';

class SiteModel {
  final String id, name, location;
  final String? description;
  final bool isActive;
  final int memberCount;
  const SiteModel({
    required this.id, required this.name, required this.location,
    this.description, this.isActive = true, this.memberCount = 0,
  });
  factory SiteModel.fromJson(Map<String, dynamic> json) => SiteModel(
    id: json['id'] as String, name: json['name'] as String,
    location: json['location'] as String,
    description: json['description'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    memberCount: json['memberCount'] as int? ?? 0);
  Map<String, dynamic> toJson() => {
    'name': name, 'location': location,
    if (description != null) 'description': description,
  };
}

enum TaskStatus { pending, inProgress, completed, onHold }

extension TaskStatusExt on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:    return 'Pending';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.completed:  return 'Completed';
      case TaskStatus.onHold:     return 'On Hold';
    }
  }
  String get apiValue {
    switch (this) {
      case TaskStatus.pending:    return 'PENDING';
      case TaskStatus.inProgress: return 'IN_PROGRESS';
      case TaskStatus.completed:  return 'COMPLETED';
      case TaskStatus.onHold:     return 'ON_HOLD';
    }
  }
  static TaskStatus fromApi(String v) {
    switch (v) {
      case 'IN_PROGRESS': return TaskStatus.inProgress;
      case 'COMPLETED':   return TaskStatus.completed;
      case 'ON_HOLD':     return TaskStatus.onHold;
      default:            return TaskStatus.pending;
    }
  }
}

class TaskModel {
  final String id, siteId, title, assignedToId, assignedToName,
      assignedToEmployeeId, createdById;
  final String? description;
  final TaskStatus status;
  final DateTime createdAt;

  const TaskModel({
    required this.id, required this.siteId, required this.title,
    this.description, required this.status, required this.assignedToId,
    required this.assignedToName, required this.assignedToEmployeeId,
    required this.createdById, required this.createdAt,
  });

  // ── FIXED fromJson ────────────────────────────────────────────────────────
  // Handles both GET /api/tasks/site/{id} and POST /api/tasks responses.
  // Both return the same shape but we add null-safe guards everywhere so
  // a missing field shows a placeholder instead of crashing/blank.
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final at = json['assignedTo'] as Map<String, dynamic>? ?? {};
    final site = json['site'] as Map<String, dynamic>? ?? {};
    final cb = json['createdBy'] as Map<String, dynamic>? ?? {};

    debugPrint('[TaskModel.fromJson] raw json keys: ${json.keys.toList()}');
    debugPrint('[TaskModel.fromJson] assignedTo: $at');
    debugPrint('[TaskModel.fromJson] title: ${json['title']}');

    return TaskModel(
      id:                   json['id'] as String? ?? '',
      siteId:               site['id'] as String? ?? '',
      title:                json['title'] as String? ?? '(no title)',
      description:          json['description'] as String?,
      status:               TaskStatusExt.fromApi(json['status'] as String? ?? 'PENDING'),
      assignedToId:         at['id'] as String? ?? '',
      assignedToName:       at['name'] as String? ?? '(unassigned)',
      assignedToEmployeeId: at['employeeId'] as String? ?? '',
      createdById:          cb['id'] as String? ?? '',
      createdAt:            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String get assigneeInitials {
    final p = assignedToName.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return assignedToName.isNotEmpty ? assignedToName[0].toUpperCase() : '?';
  }
}

class CreateTaskRequest {
  final String siteId, assignedToId, title;
  final String? description;
  const CreateTaskRequest({
    required this.siteId, required this.assignedToId,
    required this.title, this.description,
  });
  Map<String, dynamic> toJson() => {
    'siteId': siteId, 'assignedToId': assignedToId, 'title': title,
    if (description != null && description!.isNotEmpty) 'description': description,
  };
}

class CreateSiteRequest {
  final String name, location;
  final String? description;
  const CreateSiteRequest({required this.name, required this.location, this.description});
  Map<String, dynamic> toJson() => {
    'name': name, 'location': location,
    if (description != null) 'description': description,
  };
}

class SiteMemberModel {
  final String id, employeeId, name, role;
  const SiteMemberModel({
    required this.id, required this.employeeId,
    required this.name, required this.role,
  });

  factory SiteMemberModel.fromJson(Map<String, dynamic> json) {
    // Flat shape from /api/admin/users/active
    if (json.containsKey('name') && json.containsKey('employeeId')) {
      return SiteMemberModel(
        id: json['id'] as String, employeeId: json['employeeId'] as String,
        name: json['name'] as String, role: json['role'] as String? ?? 'WORKER',
      );
    }
    // Wrapped shape from /api/sites/{id}/members
    final u = json['user'] as Map<String, dynamic>? ?? json;
    return SiteMemberModel(
      id: u['id'] as String, employeeId: u['employeeId'] as String,
      name: u['name'] as String, role: u['role'] as String? ?? 'WORKER',
    );
  }

  String get initials {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
