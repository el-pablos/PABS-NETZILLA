import 'package:uuid/uuid.dart';

/// Enum untuk jenis operasi CNC
enum CncOperationType {
  setup,
  start,
  stop,
  status,
  restart,
  update,
}

/// Enum untuk status operasi CNC
enum CncOperationStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

/// Model untuk operasi Command and Control (CNC)
class CncOperation {
  final String id;
  final CncOperationType type;
  final String vpsId;
  final String vpsName;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final CncOperationStatus status;
  final String? result;
  final String? errorMessage;
  final Duration? duration;

  CncOperation({
    String? id,
    required this.type,
    required this.vpsId,
    required this.vpsName,
    Map<String, dynamic>? parameters,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    this.status = CncOperationStatus.pending,
    this.result,
    this.errorMessage,
    this.duration,
  }) : id = id ?? const Uuid().v4(),
       parameters = parameters ?? {},
       createdAt = createdAt ?? DateTime.now();

  /// Create a copy with updated fields
  CncOperation copyWith({
    String? id,
    CncOperationType? type,
    String? vpsId,
    String? vpsName,
    Map<String, dynamic>? parameters,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    CncOperationStatus? status,
    String? result,
    String? errorMessage,
    Duration? duration,
  }) {
    return CncOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      vpsId: vpsId ?? this.vpsId,
      vpsName: vpsName ?? this.vpsName,
      parameters: parameters ?? this.parameters,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      duration: duration ?? this.duration,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'vpsId': vpsId,
      'vpsName': vpsName,
      'parameters': parameters,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'result': result,
      'errorMessage': errorMessage,
      'duration': duration?.inMilliseconds,
    };
  }

  /// Create from JSON
  factory CncOperation.fromJson(Map<String, dynamic> json) {
    return CncOperation(
      id: json['id'] as String,
      type: CncOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CncOperationType.status,
      ),
      vpsId: json['vpsId'] as String,
      vpsName: json['vpsName'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt'] as String) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      status: CncOperationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CncOperationStatus.pending,
      ),
      result: json['result'] as String?,
      errorMessage: json['errorMessage'] as String?,
      duration: json['duration'] != null 
          ? Duration(milliseconds: json['duration'] as int) 
          : null,
    );
  }

  /// Get operation type display name
  String get typeDisplayName {
    switch (type) {
      case CncOperationType.setup:
        return 'Setup';
      case CncOperationType.start:
        return 'Start';
      case CncOperationType.stop:
        return 'Stop';
      case CncOperationType.status:
        return 'Status Check';
      case CncOperationType.restart:
        return 'Restart';
      case CncOperationType.update:
        return 'Update';
    }
  }

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case CncOperationStatus.pending:
        return 'Pending';
      case CncOperationStatus.running:
        return 'Running';
      case CncOperationStatus.completed:
        return 'Completed';
      case CncOperationStatus.failed:
        return 'Failed';
      case CncOperationStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case CncOperationStatus.pending:
        return '#FFA500'; // Orange
      case CncOperationStatus.running:
        return '#2196F3'; // Blue
      case CncOperationStatus.completed:
        return '#4CAF50'; // Green
      case CncOperationStatus.failed:
        return '#F44336'; // Red
      case CncOperationStatus.cancelled:
        return '#9E9E9E'; // Grey
    }
  }

  /// Check if operation is active
  bool get isActive {
    return status == CncOperationStatus.pending || 
           status == CncOperationStatus.running;
  }

  /// Check if operation is completed
  bool get isCompleted {
    return status == CncOperationStatus.completed ||
           status == CncOperationStatus.failed ||
           status == CncOperationStatus.cancelled;
  }

  /// Get operation progress (0.0 to 1.0)
  double get progress {
    switch (status) {
      case CncOperationStatus.pending:
        return 0.0;
      case CncOperationStatus.running:
        return 0.5;
      case CncOperationStatus.completed:
        return 1.0;
      case CncOperationStatus.failed:
      case CncOperationStatus.cancelled:
        return 0.0;
    }
  }

  @override
  String toString() {
    return 'CncOperation(id: $id, type: ${type.name}, vps: $vpsName, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CncOperation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model untuk batch CNC operations
class CncBatchOperation {
  final String id;
  final String name;
  final List<CncOperation> operations;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final CncOperationStatus status;

  CncBatchOperation({
    String? id,
    required this.name,
    required this.operations,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    this.status = CncOperationStatus.pending,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// Get overall progress
  double get progress {
    if (operations.isEmpty) return 0.0;
    
    final totalProgress = operations.fold<double>(
      0.0, 
      (sum, op) => sum + op.progress,
    );
    
    return totalProgress / operations.length;
  }

  /// Get completed operations count
  int get completedCount {
    return operations.where((op) => op.isCompleted).length;
  }

  /// Get failed operations count
  int get failedCount {
    return operations.where((op) => op.status == CncOperationStatus.failed).length;
  }

  /// Check if all operations are completed
  bool get isAllCompleted {
    return operations.every((op) => op.isCompleted);
  }

  /// Check if any operation is running
  bool get hasRunningOperations {
    return operations.any((op) => op.status == CncOperationStatus.running);
  }

  @override
  String toString() {
    return 'CncBatchOperation(id: $id, name: $name, operations: ${operations.length}, status: ${status.name})';
  }
}
