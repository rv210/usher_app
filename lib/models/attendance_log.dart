class AttendanceLogEntry {
  final String id;
  final int headcount;
  final String serviceType;
  final String serviceDate;
  final String? notes;
  final String submittedBy;
  final String createdAt;

  AttendanceLogEntry({
    required this.id,
    required this.headcount,
    required this.serviceType,
    required this.serviceDate,
    this.notes,
    required this.submittedBy,
    required this.createdAt,
  });

  factory AttendanceLogEntry.fromMap(Map<String, dynamic> data, String id) {
    final created = data['createdAt'] as String? ?? DateTime.now().toIso8601String();
    final defaultDate = created.split('T').first;
    return AttendanceLogEntry(
      id: id,
      headcount: (data['headcount'] as num?)?.toInt() ?? 0,
      serviceType: data['serviceType'] as String? ?? 'Sunday Service',
      serviceDate: data['serviceDate'] as String? ?? defaultDate,
      notes: data['notes'] as String?,
      submittedBy: data['submittedBy'] as String? ?? 'Unknown Usher',
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'headcount': headcount,
      'serviceType': serviceType,
      'serviceDate': serviceDate,
      if (notes != null) 'notes': notes,
      'submittedBy': submittedBy,
      'createdAt': createdAt,
    };
  }
}
