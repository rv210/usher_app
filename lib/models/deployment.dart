class Deployment {
  final String id;
  final String date; // YYYY-MM-DD
  final String usherId;
  final String usherName;
  final String serviceType; // e.g. Sunday Morning, Communion Service, Mid-week Rallies
  final String? customEventName;
  final String station; // e.g. Sanctuary, Vestibule, Balcony, Greeter, Overflow
  final String role; // e.g. Usher, Lead Usher, Prep
  final bool verified;
  final bool requestingCover;
  final String? originalUsherName;
  final String? updatedAt;

  Deployment({
    required this.id,
    required this.date,
    required this.usherId,
    required this.usherName,
    required this.serviceType,
    this.customEventName,
    this.station = 'Sanctuary',
    this.role = 'Usher',
    this.verified = false,
    this.requestingCover = false,
    this.originalUsherName,
    this.updatedAt,
  });

  factory Deployment.fromMap(Map<String, dynamic> data, String id) {
    return Deployment(
      id: id,
      date: data['date'] as String? ?? '',
      usherId: data['usherId'] as String? ?? '',
      usherName: data['usherName'] as String? ?? 'Unknown Usher',
      serviceType: data['serviceType'] as String? ?? 'Sunday Morning',
      customEventName: data['customEventName'] as String?,
      station: data['station'] as String? ?? 'Sanctuary',
      role: data['role'] as String? ?? 'Usher',
      verified: data['verified'] as bool? ?? false,
      requestingCover: data['requestingCover'] as bool? ?? false,
      originalUsherName: data['originalUsherName'] as String?,
      updatedAt: data['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'usherId': usherId,
      'usherName': usherName,
      'serviceType': serviceType,
      if (customEventName != null) 'customEventName': customEventName,
      'station': station,
      'role': role,
      'verified': verified,
      'requestingCover': requestingCover,
      if (originalUsherName != null) 'originalUsherName': originalUsherName,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}
