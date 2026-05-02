// lib/data/models/attendance.dart
// ─────────────────────────────────
// Data models for attendance records returned by the API.

class AttendanceModel {
  final String id;
  final String userId;
  final String date;         // "YYYY-MM-DD"
  final String? checkinTime;
  final double? checkinLat;
  final double? checkinLng;
  final String? checkoutTime;
  final double? checkoutLat;
  final double? checkoutLng;
  final String status;       // "present" | "checked_out" | "absent"

  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.date,
    this.checkinTime,
    this.checkinLat,
    this.checkinLng,
    this.checkoutTime,
    this.checkoutLat,
    this.checkoutLng,
    required this.status,
  });

  bool get isPresent     => status == 'present';
  bool get isCheckedOut  => status == 'checked_out';
  bool get isAbsent      => status == 'absent';

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id:           json['id']           as String,
      userId:       json['user_id']      as String,
      date:         json['date']         as String,
      checkinTime:  json['checkin_time']  as String?,
      checkinLat:   (json['checkin_lat']  as num?)?.toDouble(),
      checkinLng:   (json['checkin_lng']  as num?)?.toDouble(),
      checkoutTime: json['checkout_time'] as String?,
      checkoutLat:  (json['checkout_lat'] as num?)?.toDouble(),
      checkoutLng:  (json['checkout_lng'] as num?)?.toDouble(),
      status:       json['status']        as String,
    );
  }
}

// ── Paginated response wrapper ──────────────────────────────────────────────

class PaginatedAttendance {
  final int total;
  final int page;
  final int pageSize;
  final List<AttendanceModel> records;

  const PaginatedAttendance({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.records,
  });

  bool get hasMore => (page * pageSize) < total;

  factory PaginatedAttendance.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'] as List<dynamic>;
    return PaginatedAttendance(
      total:    json['total']     as int,
      page:     json['page']      as int,
      pageSize: json['page_size'] as int,
      records:  rawRecords
          .map((r) => AttendanceModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Team attendance (attendance + user info) ─────────────────────────────────

class TeamAttendanceModel extends AttendanceModel {
  final String userName;
  final String userEmail;

  const TeamAttendanceModel({
    required super.id,
    required super.userId,
    required super.date,
    super.checkinTime,
    super.checkinLat,
    super.checkinLng,
    super.checkoutTime,
    super.checkoutLat,
    super.checkoutLng,
    required super.status,
    required this.userName,
    required this.userEmail,
  });

  factory TeamAttendanceModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    return TeamAttendanceModel(
      id:           json['id']            as String,
      userId:       json['user_id']       as String,
      date:         json['date']          as String,
      checkinTime:  json['checkin_time']  as String?,
      checkinLat:   (json['checkin_lat']  as num?)?.toDouble(),
      checkinLng:   (json['checkin_lng']  as num?)?.toDouble(),
      checkoutTime: json['checkout_time'] as String?,
      checkoutLat:  (json['checkout_lat'] as num?)?.toDouble(),
      checkoutLng:  (json['checkout_lng'] as num?)?.toDouble(),
      status:       json['status']        as String,
      userName:     userJson['name']      as String,
      userEmail:    userJson['email']     as String,
    );
  }
}
