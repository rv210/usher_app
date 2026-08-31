import 'package:flutter_test/flutter_test.dart';
import 'package:usher_app/models/deployment.dart';
import 'package:usher_app/models/attendance_log.dart';
import 'package:usher_app/models/team_member.dart';
import 'package:usher_app/models/comms_message.dart';

void main() {
  group('Deployment Model Tests', () {
    test('Deployment.fromMap creates instance with default values', () {
      final map = <String, dynamic>{
        'station': 'Main Sanctuary - Doors 1 & 2',
        'usherName': 'Robert Vargas',
        'usherId': 'user_001',
        'date': '2026-09-06',
      };
      final dep = Deployment.fromMap(map, 'dep_001');

      expect(dep.id, 'dep_001');
      expect(dep.station, 'Main Sanctuary - Doors 1 & 2');
      expect(dep.usherName, 'Robert Vargas');
      expect(dep.usherId, 'user_001');
      expect(dep.date, '2026-09-06');
      expect(dep.role, 'Usher');
      expect(dep.serviceType, 'Sunday Service');
      expect(dep.customEventName, isNull);
    });

    test('Deployment.fromMap parses custom service types and custom event names', () {
      final map = <String, dynamic>{
        'station': 'Balcony Left',
        'usherName': 'Sister Sarah',
        'usherId': 'user_002',
        'date': '2026-09-12',
        'role': 'Lead Usher',
        'serviceType': 'Special Events',
        'customEventName': 'Annual Revival Night 1',
      };
      final dep = Deployment.fromMap(map, 'dep_002');

      expect(dep.id, 'dep_002');
      expect(dep.role, 'Lead Usher');
      expect(dep.serviceType, 'Special Events');
      expect(dep.customEventName, 'Annual Revival Night 1');

      final serialized = dep.toMap();
      expect(serialized['serviceType'], 'Special Events');
      expect(serialized['customEventName'], 'Annual Revival Night 1');
      expect(serialized['role'], 'Lead Usher');
    });

    test('Deployment.fromMap handles Communion Service', () {
      final map = <String, dynamic>{
        'station': 'Altar Rails',
        'usherName': 'Deacon John',
        'usherId': 'user_003',
        'date': '2026-09-06',
        'serviceType': 'Communion Service',
      };
      final dep = Deployment.fromMap(map, 'dep_003');
      expect(dep.serviceType, 'Communion Service');
      expect(dep.toMap()['serviceType'], 'Communion Service');
    });
  });

  group('AttendanceLogEntry Model Tests', () {
    test('AttendanceLogEntry serialization & deserialization', () {
      final map = <String, dynamic>{
        'headcount': 245,
        'serviceType': 'Sunday Service',
        'serviceDate': '2026-09-06',
        'notes': 'High attendance in morning service',
        'submittedBy': 'Robert Vargas',
        'createdAt': '2026-09-06T11:45:00.000Z',
      };
      final entry = AttendanceLogEntry.fromMap(map, 'log_123');

      expect(entry.id, 'log_123');
      expect(entry.headcount, 245);
      expect(entry.serviceType, 'Sunday Service');
      expect(entry.serviceDate, '2026-09-06');
      expect(entry.notes, 'High attendance in morning service');
      expect(entry.submittedBy, 'Robert Vargas');

      final serialized = entry.toMap();
      expect(serialized['headcount'], 245);
      expect(serialized['serviceType'], 'Sunday Service');
      expect(serialized['submittedBy'], 'Robert Vargas');
    });

    test('AttendanceLogEntry handles missing optional fields gracefully', () {
      final map = <String, dynamic>{
        'headcount': 80,
      };
      final entry = AttendanceLogEntry.fromMap(map, 'log_minimal');
      expect(entry.headcount, 80);
      expect(entry.serviceType, 'Sunday Service');
      expect(entry.submittedBy, 'Unknown Usher');
      expect(entry.notes, isNull);
    });
  });

  group('TeamMember Model Tests', () {
    test('TeamMember correctly parses permissions and 2FA info', () {
      final map = <String, dynamic>{
        'name': 'Robert Vargas',
        'email': 'robv88@live.com',
        'phone': '7575257900',
        'role': 'Admin',
        'approved': true,
        'denied': false,
        'twoFactorEnabled': true,
        'twoFactorPhone': '7575257900',
      };
      final member = TeamMember.fromMap(map, 'user_001');

      expect(member.id, 'user_001');
      expect(member.name, 'Robert Vargas');
      expect(member.email, 'robv88@live.com');
      expect(member.phone, '7575257900');
      expect(member.role, 'Admin');
      expect(member.approved, isTrue);
      expect(member.denied, isFalse);
      expect(member.twoFactorEnabled, isTrue);
      expect(member.twoFactorPhone, '7575257900');
    });

    test('TeamMember defaults to pending if approved/denied not specified', () {
      final map = <String, dynamic>{
        'name': 'New Usher Candidate',
        'email': 'candidate@church.org',
      };
      final member = TeamMember.fromMap(map, 'user_pending');
      expect(member.approved, isFalse);
      expect(member.denied, isFalse);
      expect(member.role, 'Usher');
    });
  });

  group('CommsMessage Model Tests', () {
    test('CommsMessage fromMap and toMap', () {
      final map = <String, dynamic>{
        'text': 'Service starts in 15 minutes at Station 1.',
        'authorName': 'Robert Vargas',
        'authorUid': 'user_001',
        'createdAt': '2026-08-31T10:00:00.000Z',
        'edited': true,
      };
      final msg = CommsMessage.fromMap(map, 'msg_001');

      expect(msg.id, 'msg_001');
      expect(msg.text, 'Service starts in 15 minutes at Station 1.');
      expect(msg.authorName, 'Robert Vargas');
      expect(msg.authorUid, 'user_001');
      expect(msg.edited, isTrue);

      final outMap = msg.toMap();
      expect(outMap['text'], 'Service starts in 15 minutes at Station 1.');
      expect(outMap['edited'], isTrue);
    });
  });
}
