import 'package:equatable/equatable.dart';

/// Supported profile change request types.
enum ProfileChangeRequestType {
  allergens,
  diets;

  /// Database-friendly string value.
  String get value => switch (this) {
        ProfileChangeRequestType.allergens => 'allergens',
        ProfileChangeRequestType.diets => 'diets',
      };

  /// Human readable label used in the UI.
  String get label => switch (this) {
        ProfileChangeRequestType.allergens => 'Allergens',
        ProfileChangeRequestType.diets => 'Dietary preferences',
      };

  /// Parses enum value from database string.
  static ProfileChangeRequestType fromValue(String value) {
    return ProfileChangeRequestType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ProfileChangeRequestType.allergens,
    );
  }
}

/// Status for a profile change request.
enum ProfileChangeRequestStatus {
  pending,
  approved,
  rejected;

  String get value => switch (this) {
        ProfileChangeRequestStatus.pending => 'pending',
        ProfileChangeRequestStatus.approved => 'approved',
        ProfileChangeRequestStatus.rejected => 'rejected',
      };

  static ProfileChangeRequestStatus fromValue(String value) {
    return ProfileChangeRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProfileChangeRequestStatus.pending,
    );
  }
}

/// Represents a pending allergen/diet change requiring admin approval.
class ProfileChangeRequest extends Equatable {
  const ProfileChangeRequest({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.requestedValues,
    required this.requestedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.adminNote,
    this.userNameSnapshot,
    this.userEmailSnapshot,
  });

  final String id;
  final String userId;
  final ProfileChangeRequestType type;
  final ProfileChangeRequestStatus status;
  final List<String> requestedValues;
  final DateTime requestedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? adminNote;
  final String? userNameSnapshot;
  final String? userEmailSnapshot;

  factory ProfileChangeRequest.fromMap(Map<String, dynamic> map) {
    return ProfileChangeRequest(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: ProfileChangeRequestType.fromValue(map['type'] as String),
      status: ProfileChangeRequestStatus.fromValue(map['status'] as String),
      requestedValues: List<String>.from(
        (map['requested_values'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      requestedAt: DateTime.parse(map['requested_at'] as String),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'] as String)
          : null,
      resolvedBy: map['resolved_by'] as String?,
      adminNote: map['admin_note'] as String?,
      userNameSnapshot: map['user_name_snapshot'] as String?,
      userEmailSnapshot: map['user_email_snapshot'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'status': status.value,
      'requested_values': requestedValues,
      'requested_at': requestedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'admin_note': adminNote,
      'user_name_snapshot': userNameSnapshot,
      'user_email_snapshot': userEmailSnapshot,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        status,
        requestedValues,
        requestedAt,
        resolvedAt,
        resolvedBy,
        adminNote,
        userNameSnapshot,
        userEmailSnapshot,
      ];
}
