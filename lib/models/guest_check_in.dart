class GuestCheckInEntry {
  final String id;
  final String guestName;
  final int partySize;
  final String checkInTime;
  final String entrance;
  final String status;
  final String? notes;
  final String createdAt;

  const GuestCheckInEntry({
    required this.id,
    required this.guestName,
    this.partySize = 1,
    required this.checkInTime,
    this.entrance = 'Vestibule Station',
    this.status = 'Checked In',
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guestName': guestName,
      'partySize': partySize,
      'checkInTime': checkInTime,
      'entrance': entrance,
      'status': status,
      if (notes != null) 'notes': notes,
      'createdAt': createdAt,
    };
  }

  factory GuestCheckInEntry.fromMap(Map<String, dynamic> map, String docId) {
    return GuestCheckInEntry(
      id: docId,
      guestName: map['guestName'] as String? ?? 'Guest Family',
      partySize: (map['partySize'] as num?)?.toInt() ?? 1,
      checkInTime: map['checkInTime'] as String? ?? '10:00 AM',
      entrance: map['entrance'] as String? ?? 'Vestibule Station',
      status: map['status'] as String? ?? 'Checked In',
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
