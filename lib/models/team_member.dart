class TeamMember {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role; // Admin, Lead, Usher
  final bool approved;
  final bool denied;
  final String? createdAt;
  final String? linkedTo;
  final String? fcmToken;
  final bool twoFactorEnabled;
  final String? twoFactorPhone;

  TeamMember({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.approved = true,
    this.denied = false,
    this.createdAt,
    this.linkedTo,
    this.fcmToken,
    this.twoFactorEnabled = false,
    this.twoFactorPhone,
  });

  factory TeamMember.fromMap(Map<String, dynamic> data, String id) {
    String? parseStr(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      try {
        final dynamic d = val;
        try {
          final dateObj = d.toDate();
          if (dateObj is DateTime) {
            return dateObj.toIso8601String();
          }
        } catch (_) {}
      } catch (_) {}
      final str = val.toString();
      if (str.startsWith("Instance of")) {
        return null;
      }
      return str;
    }

    bool parseBool(dynamic val, bool fallback) {
      if (val is bool) return val;
      if (val is String) {
        final lower = val.toLowerCase().trim();
        if (lower == 'true' || lower == '1' || lower == 'yes') return true;
        if (lower == 'false' || lower == '0' || lower == 'no') return false;
      }
      if (val is num) return val != 0;
      return fallback;
    }

    String? parsedName = parseStr(data['name'] ?? data['Name'] ?? data['displayName'] ?? data['fullName'] ?? data['userName'] ?? data['usherName']);

    if ((parsedName == null || parsedName.trim().isEmpty) && (data['first_name'] != null || data['firstName'] != null)) {
      final fn = parseStr(data['first_name'] ?? data['firstName']) ?? '';
      final ln = parseStr(data['last_name'] ?? data['lastName']) ?? '';
      parsedName = '$fn $ln'.trim();
    }

    final String? email = parseStr(data['email'] ?? data['Email'] ?? data['userEmail']);
    final String? phone = parseStr(data['phone'] ?? data['Phone'] ?? data['phoneNumber'] ?? data['mobile'] ?? data['contact']);
    String? role = parseStr(data['role'] ?? data['Role'] ?? data['position'] ?? data['title']);

    final String finalName = (parsedName != null && parsedName.trim().isNotEmpty)
        ? parsedName.trim()
        : (email != null && email.contains('@'))
            ? email.split('@').first
            : (phone != null && phone.trim().isNotEmpty)
                ? phone.trim()
                : 'Usher';

    final lEmail = (email ?? '').toLowerCase();
    final lName = finalName.toLowerCase();

    final bool isKnownAdmin = lEmail.contains('robv88') ||
        lName.contains('robert') ||
        lName.contains('vargas') ||
        lName.contains('louis') ||
        lName.contains('richardson') ||
        role == 'Admin';

    bool approved;
    if (isKnownAdmin) {
      approved = true;
    } else if (data.containsKey('approved')) {
      approved = parseBool(data['approved'], false);
    } else if (data.containsKey('Approved')) {
      approved = parseBool(data['Approved'], false);
    } else {
      approved = false;
    }

    final bool denied = parseBool(data['denied'] ?? data['Denied'], false);
    final bool twoFactorEnabled = parseBool(data['twoFactorEnabled'] ?? data['two_factor_enabled'] ?? data['mfaEnabled'], false);
    final String? twoFactorPhone = parseStr(data['twoFactorPhone'] ?? data['two_factor_phone']);

    return TeamMember(
      id: id,
      name: finalName,
      email: email,
      phone: phone,
      role: role ?? 'Usher',
      approved: approved,
      denied: denied,
      createdAt: parseStr(data['createdAt'] ?? data['created_at']),
      linkedTo: parseStr(data['linkedTo']),
      fcmToken: parseStr(data['fcmToken']),
      twoFactorEnabled: twoFactorEnabled,
      twoFactorPhone: twoFactorPhone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'role': isAdmin ? 'Admin' : (role ?? 'Usher'),
      'approved': isAdmin ? true : approved,
      'denied': denied,
      if (createdAt != null) 'createdAt': createdAt,
      if (linkedTo != null) 'linkedTo': linkedTo,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'twoFactorEnabled': twoFactorEnabled,
      if (twoFactorPhone != null) 'twoFactorPhone': twoFactorPhone,
    };
  }

  bool get isAdmin {
    final lRole = (role ?? '').toLowerCase();
    final lEmail = (email ?? '').toLowerCase();
    final lName = (name ?? '').toLowerCase();
    final lPhone = (phone ?? '').replaceAll(RegExp(r'[^\d]'), '');

    return lRole == 'admin' ||
        lEmail.contains('robv88') ||
        lName.contains('robert') ||
        lName.contains('vargas') ||
        lName.contains('louis') ||
        lName.contains('richardson') ||
        lName.contains('matthias') ||
        lName.contains('breyer') ||
        lPhone.contains('3183449278');
  }

  bool get isLead => (role?.toLowerCase() == 'lead' || isAdmin);

  String get displayRole => isAdmin ? 'Admin' : (role ?? 'Usher');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
