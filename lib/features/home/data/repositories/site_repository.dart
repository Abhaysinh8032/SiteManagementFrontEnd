import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart'; // <-- ADDED IMPORT
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/site_task_models.dart';

class SiteRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<SiteModel>> getSites() async {
    try {
      debugPrint('[SiteRepository] Fetching sites');
      final r = await _dio.get(AppConstants.endpointSites);
      debugPrint('[SiteRepository] ✓ Sites: ${r.data.length}');
      return (r.data as List)
          .map((e) => SiteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SiteRepository] ✗ Sites error: $e');
      rethrow;
    }
  }

  Future<SiteModel> createSite(CreateSiteRequest req) async {
    try {
      debugPrint('[SiteRepository] Creating site: ${req.name}');
      final r = await _dio.post(AppConstants.endpointSites, data: req.toJson());
      debugPrint('[SiteRepository] ✓ Site created');
      return SiteModel.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[SiteRepository] ✗ Create site error: $e');
      rethrow;
    }
  }

  Future<List<TaskModel>> getTasksForSite(String siteId) async {
    try {
      final url = AppConstants.endpointSiteTasks.replaceAll('{siteId}', siteId);
      debugPrint('[SiteRepository] Fetching tasks: $url');
      final r = await _dio.get(url);
      debugPrint('[SiteRepository] ✓ Tasks: ${r.data.length}');
      return (r.data as List)
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SiteRepository] ✗ Tasks error: $e');
      rethrow;
    }
  }

  Future<TaskModel> createTask(CreateTaskRequest req) async {
    try {
      debugPrint('[SiteRepository] Creating task: ${req.title}');
      final r = await _dio.post(AppConstants.endpointTasks, data: req.toJson());
      debugPrint('[SiteRepository] ✓ Task created');
      return TaskModel.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[SiteRepository] ✗ Create task error: $e');
      rethrow;
    }
  }

  Future<TaskModel> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      debugPrint(
        '[SiteRepository] Updating task $taskId status → ${status.apiValue}',
      );
      final r = await _dio.patch(
        '${AppConstants.endpointTasks}/$taskId/status',
        data: {'status': status.apiValue},
      );
      debugPrint('[SiteRepository] ✓ Status updated');
      return TaskModel.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[SiteRepository] ✗ Status update error: $e');
      rethrow;
    }
  }

  // Admin updates task description
  Future<TaskModel> updateTaskDescription(
    String taskId,
    String? description,
  ) async {
    try {
      debugPrint('[SiteRepository] Updating task $taskId description');
      final r = await _dio.patch(
        '${AppConstants.endpointTasks}/$taskId/description',
        data: {'description': description ?? ''},
      );
      debugPrint('[SiteRepository] ✓ Description updated');
      return TaskModel.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[SiteRepository] ✗ Description update error: $e');
      rethrow;
    }
  }

  Future<List<SiteMemberModel>> getSiteMembers(String siteId) async {
    try {
      final url = AppConstants.endpointSiteMembers.replaceAll('{id}', siteId);
      debugPrint('[SiteRepository] Fetching site members: $url');
      final r = await _dio.get(url);
      debugPrint('[SiteRepository] ✓ Site members: ${r.data.length}');
      return (r.data as List)
          .map((e) => SiteMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SiteRepository] ✗ Site members error: $e');
      rethrow;
    }
  }

  Future<List<SiteMemberModel>> getAllActiveUsers() async {
    try {
      debugPrint(
        '[SiteRepository] Fetching all active users: ${AppConstants.endpointAllMembers}',
      );
      final r = await _dio.get(AppConstants.endpointAllMembers);
      debugPrint('[SiteRepository] ✓ All active users: ${r.data.length}');
      return (r.data as List)
          .map((e) => SiteMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SiteRepository] ✗ getAllActiveUsers error: $e');
      rethrow;
    }
  }

  // <-- ADDED THIS MISSING METHOD -->
  Future<TaskModel> uploadTaskImages(String taskId, List<XFile> files) async {
    try {
      FormData formData = FormData();

      for (var file in files) {
        final fileName = file.name.isNotEmpty ? file.name : 'image.jpg';

        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          formData.files.add(
            MapEntry(
              'files',
              MultipartFile.fromBytes(bytes, filename: fileName),
            ),
          );
        } else {
          formData.files.add(
            MapEntry(
              'files',
              await MultipartFile.fromFile(file.path, filename: fileName),
            ),
          );
        }
      }

      final r = await _dio.post(
        '${AppConstants.endpointTasks}/$taskId/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return TaskModel.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[SiteRepository] ✗ Image upload error: $e');
      rethrow;
    }
  }
}
