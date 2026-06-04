import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/site_task_models.dart';

class SiteRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<SiteModel>> getSites() async {
    try {
      debugPrint('[SiteRepository] Fetching sites from: ${AppConstants.endpointSites}');
      final r = await _dio.get(AppConstants.endpointSites);
      debugPrint('[SiteRepository] ✓ Sites loaded. Count: ${r.data.length}');
      return (r.data as List)
          .map((e) => SiteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SiteRepository] ✗ ERROR fetching sites: $e');
      rethrow;
    }
  }

  Future<SiteModel> createSite(CreateSiteRequest req) async {
    final r = await _dio.post(AppConstants.endpointSites, data: req.toJson());
    return SiteModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<TaskModel>> getTasksForSite(String siteId) async {
    try {
      final url = AppConstants.endpointSiteTasks.replaceAll('{siteId}', siteId);
      debugPrint('[SiteRepository] Fetching tasks from: $url');
      final r = await _dio.get(url);
      debugPrint('[SiteRepository] ✓ Tasks loaded. Count: ${r.data.length}');
      return (r.data as List)
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SiteRepository] ✗ ERROR fetching tasks: $e');
      rethrow;
    }
  }

  Future<TaskModel> createTask(CreateTaskRequest req) async {
    final r = await _dio.post(AppConstants.endpointTasks, data: req.toJson());
    return TaskModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<TaskModel> updateTaskStatus(String taskId, TaskStatus status) async {
    final r = await _dio.patch(
      '${AppConstants.endpointTasks}/$taskId/status',
      data: {'status': status.apiValue},
    );
    return TaskModel.fromJson(r.data as Map<String, dynamic>);
  }

  // Shape A — returns wrapped: { "user": { "id":..., "name":..., ... } }
  Future<List<SiteMemberModel>> getSiteMembers(String siteId) async {
    try {
      final url = AppConstants.endpointSiteMembers.replaceAll('{id}', siteId);
      debugPrint('[SiteRepository] Fetching site members from: $url');
      final r = await _dio.get(url);
      debugPrint('[SiteRepository] ✓ Site members loaded. Count: ${r.data.length}');
      return (r.data as List)
          .map((e) => SiteMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SiteRepository] ✗ ERROR fetching site members: $e');
      rethrow;
    }
  }

  // ── FIX 3: was calling /api/admin/users (wrong — needs ADMIN role guard
  //           AND returns ALL users including inactive/pending)
  //           now calls /api/admin/users/active (correct endpoint) ──────────
  // Shape B — returns flat: { "id":..., "name":..., "employeeId":..., "role":... }
  Future<List<SiteMemberModel>> getAllActiveUsers() async {
    try {
      debugPrint(
        '[SiteRepository] Fetching all active users from: ${AppConstants.endpointAllActiveUsers}',
      );
      final r = await _dio.get(AppConstants.endpointAllActiveUsers);
      debugPrint('[SiteRepository] ✓ All active users loaded. Count: ${r.data.length}');
      return (r.data as List)
          .map((e) => SiteMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SiteRepository] ✗ ERROR fetching all active users: $e');
      rethrow;
    }
  }
}
