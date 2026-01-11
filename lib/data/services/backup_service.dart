import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

/// Cloud Backup Service for app data backup and restore
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// Create a local backup of all app data
  Future<BackupResult> createLocalBackup({
    required Map<String, dynamic> data,
    String? customName,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = customName ?? 'aquastockpro_backup_$timestamp.json';
      final file = File('${backupDir.path}/$fileName');

      final backupData = {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'app': 'AquaStock Pro',
        'data': data,
      };

      await file.writeAsString(jsonEncode(backupData), flush: true);

      return BackupResult(
        success: true,
        filePath: file.path,
        fileName: fileName,
        size: await file.length(),
      );
    } catch (e) {
      return BackupResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Restore from a local backup file
  Future<RestoreResult> restoreFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return RestoreResult(
          success: false,
          error: 'Backup file not found',
        );
      }

      final content = await file.readAsString();
      final backupData = jsonDecode(content) as Map<String, dynamic>;

      // Validate backup format
      if (!backupData.containsKey('data') || !backupData.containsKey('version')) {
        return RestoreResult(
          success: false,
          error: 'Invalid backup file format',
        );
      }

      return RestoreResult(
        success: true,
        data: backupData['data'] as Map<String, dynamic>,
        version: backupData['version'] as String,
        createdAt: DateTime.parse(backupData['created_at'] as String),
      );
    } catch (e) {
      return RestoreResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// List all available local backups
  Future<List<BackupInfo>> listLocalBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir.list().toList();
      final backups = <BackupInfo>[];

      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.json')) {
          final stat = await entity.stat();
          final name = entity.path.split(Platform.pathSeparator).last;
          
          backups.add(BackupInfo(
            fileName: name,
            filePath: entity.path,
            size: stat.size,
            createdAt: stat.modified,
          ));
        }
      }

      // Sort by date, newest first
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } catch (e) {
      return [];
    }
  }

  /// Delete a local backup
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Share backup file
  Future<void> shareBackup(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'AquaStock Pro Backup',
        text: 'AquaStock Pro data backup file',
      );
    } catch (e) {
      debugPrint('Error sharing backup: $e');
    }
  }

  /// Get backup directory path
  Future<String> getBackupDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/backups';
  }

  /// Calculate total backup size
  Future<int> getTotalBackupSize() async {
    final backups = await listLocalBackups();
    int total = 0;
    for (final backup in backups) {
      total += backup.size;
    }
    return total;
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Backup operation result
class BackupResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final int? size;
  final String? error;

  BackupResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.size,
    this.error,
  });
}

/// Restore operation result
class RestoreResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? version;
  final DateTime? createdAt;
  final String? error;

  RestoreResult({
    required this.success,
    this.data,
    this.version,
    this.createdAt,
    this.error,
  });
}

/// Backup file info
class BackupInfo {
  final String fileName;
  final String filePath;
  final int size;
  final DateTime createdAt;

  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.size,
    required this.createdAt,
  });

  String get sizeFormatted => BackupService.formatFileSize(size);
}
