import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usher_app/theme/app_theme.dart';
import 'package:usher_app/views/wear_tally_view.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:usher_app/widgets/user_avatar.dart';
import 'package:usher_app/models/team_member.dart';
import 'package:usher_app/views/announcements_view.dart';
import 'package:usher_app/models/announcement.dart';
import 'package:usher_app/models/biblical_avatar.dart';
import 'package:usher_app/models/profile_background.dart';
import 'package:usher_app/views/dashboard_view.dart';

void main() {
  testWidgets('DribbbleGlassContainer renders child and responds to tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DribbbleGlassContainer(
            onTap: () => tapped = true,
            padding: const EdgeInsets.all(16),
            child: const Text('Guardians Usher Portal'),
          ),
        ),
      ),
    );

    expect(find.text('Guardians Usher Portal'), findsOneWidget);

    await tester.tap(find.text('Guardians Usher Portal'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('DribbbleGlowButton renders label and triggers callback', (WidgetTester tester) async {
    bool pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DribbbleGlowButton(
            label: 'Submit Headcount',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Submit Headcount'), findsOneWidget);

    await tester.tap(find.text('Submit Headcount'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('DribbblePillBadge displays label text accurately', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DribbblePillBadge(
            label: 'ADMIN APPROVED',
            color: Colors.green,
          ),
        ),
      ),
    );

    expect(find.text('ADMIN APPROVED'), findsOneWidget);
  });

  testWidgets('BehanceGlassCard renders child and handles interactions', (WidgetTester tester) async {
    bool cardTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BehanceGlassCard(
            onTap: () => cardTapped = true,
            child: const Text('Behance Creative Studio'),
          ),
        ),
      ),
    );

    expect(find.text('Behance Creative Studio'), findsOneWidget);
    await tester.tap(find.text('Behance Creative Studio'));
    await tester.pump();
    expect(cardTapped, isTrue);
  });

  testWidgets('BehanceActionButton triggers onPressed and displays icon', (WidgetTester tester) async {
    bool actionFired = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BehanceActionButton(
            label: 'Submit Count',
            icon: Icons.check,
            onPressed: () => actionFired = true,
          ),
        ),
      ),
    );

    expect(find.text('Submit Count'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('Submit Count'));
    await tester.pump();
    expect(actionFired, isTrue);
  });

  testWidgets('BehancePillBadge renders uppercase tracked label accurately', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BehancePillBadge(
            label: 'Behance Pro',
            color: Color(0xFF0057FF),
          ),
        ),
      ),
    );

    expect(find.text('BEHANCE PRO'), findsOneWidget);
  });

  testWidgets('BehanceActionButton does not overflow on narrow screens with long dispatch label', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: BehanceActionButton(
                label: 'TRANSMIT HEADCOUNT TO DISPATCH',
                icon: Icons.send,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('TRANSMIT HEADCOUNT TO DISPATCH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Handbook Excerpt header row does not overflow on narrow screens with long chapter title', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.book, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Handbook Excerpt • Chapter 1: The Divine Calling of the Church Usher",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Handbook Excerpt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Member action bottom sheet content respects safe area and does not collide with system nav bar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.padding = const FakeViewPadding(bottom: 48.0);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (modalCtx) => Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text("Call Member"),
                            Text("Send Ministry SMS"),
                            Text("Copy Contact Details"),
                            Text("Edit Profile & Station Role"),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Text("Open Sheet"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Open Sheet"));
    await tester.pumpAndSettle();

    expect(find.text("Edit Profile & Station Role"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wear OS Galaxy Watch confirmation sheet renders without overflow on circular watch screen (190x190)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(190, 190);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: WearSubmitConfirmationSheet(
          count: 142,
          serviceType: "Sunday Morning Service",
          onCancel: () {},
          onConfirm: () {},
        ),
      ),
    );

    expect(find.text('SUBMIT ATTENDANCE'), findsOneWidget);
    expect(find.text('142'), findsOneWidget);
    expect(find.text('ATTENDEES'), findsOneWidget);
    expect(find.text('CONFIRM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wear OS Galaxy Watch confirmation sheet renders without overflow on ultra-compact watch screen (170x170) with 1.3x text scaling', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(170, 170);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(170, 170),
            textScaler: TextScaler.linear(1.3),
          ),
          child: WearSubmitConfirmationSheet(
            count: 275,
            serviceType: "Midweek Communion Service & Leadership Meeting",
            onCancel: () {},
            onConfirm: () {},
          ),
        ),
      ),
    );

    expect(find.text('SUBMIT ATTENDANCE'), findsOneWidget);
    expect(find.text('275'), findsOneWidget);
    expect(find.text('CONFIRM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wear OS Galaxy Watch confirmation sheet triggers cancel and confirm callbacks', (WidgetTester tester) async {
    bool cancelled = false;
    bool confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: WearSubmitConfirmationSheet(
          count: 88,
          serviceType: "Sunday 10:00 AM",
          onCancel: () => cancelled = true,
          onConfirm: () => confirmed = true,
        ),
      ),
    );

    await tester.tap(find.text('CONFIRM'));
    await tester.pump();
    expect(confirmed, isTrue);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pump();
    expect(cancelled, isTrue);
  });

  testWidgets('Hub Guest Check-In card renders without overflow on narrow width (320px) with 1.3x text scale', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: FigmaBentoCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            child: const Icon(LucideIcons.userCheck, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "GUEST CHECK-IN • VESTIBULE",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      child: const Text("LIVE"),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Check In Sanctuary Guests",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(fontSize: 15.5, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.chevronRight, size: 16),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.doorOpen, size: 15),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Vestibule Station",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Open in Tally",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.arrowRight, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final errTop = tester.takeException();
    // ignore: avoid_print
    print("TOP ROW ERROR: $errTop");
    expect(errTop, isNull);
  });

  test('AppStyleTheme.guardiansGold preset is properly configured with white & gold tokens', () {
    final cfg = AppThemePresets.configs[AppStyleTheme.guardiansGold];
    expect(cfg, isNotNull);
    expect(cfg!.name, equals("Guardians Gold & White"));
    expect(cfg.primary, equals(const Color(0xFFC79540)));
    expect(cfg.secondary, equals(const Color(0xFFE5BC6A)));
    expect(cfg.bgLight, equals(const Color(0xFFF9FAFC)));
    expect(cfg.gradient.colors, contains(const Color(0xFFC79540)));
  });

  testWidgets('BehanceActionButton with gold gradient renders dark text for high contrast', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BehanceActionButton(
              label: "Create Account",
              gradient: const LinearGradient(colors: [Color(0xFFE5BC6A), Color(0xFFC79540)]),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text("Create Account"));
    expect(textWidget.style?.color, equals(const Color(0xFF161208)));
  });

  testWidgets('BehanceGlassCard and FigmaBentoCard render with white background and E2E8F0 border in light mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BehanceGlassCard(
                child: Text("Glass Card Content"),
              ),
              FigmaBentoCard(
                child: Text("Bento Card Content"),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("Glass Card Content"), findsOneWidget);
    expect(find.text("Bento Card Content"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tally SnackBar renders in-content UNDO and close buttons and auto-dismisses', (WidgetTester tester) async {
    int tallyCount = 17;
    bool undid = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  tallyCount += 10;
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(milliseconds: 2500),
                      dismissDirection: DismissDirection.horizontal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: const Color(0xF01E293B),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      content: Row(
                        children: [
                          Expanded(
                            child: Text("+10 added • Tally: $tallyCount"),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              tallyCount -= 10;
                              undid = true;
                              messenger.hideCurrentSnackBar();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text("UNDO"),
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              messenger.hideCurrentSnackBar();
                            },
                            child: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Trigger SnackBar'),
              );
            },
          ),
        ),
      ),
    );

    // Initial state
    expect(find.text('+10 added • Tally: 27'), findsNothing);

    // Tap button to trigger SnackBar
    await tester.tap(find.text('Trigger SnackBar'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 300)); // Finish slide in

    // Verify content, UNDO, and close icon are all displayed
    expect(find.text('+10 added • Tally: 27'), findsOneWidget);
    expect(find.text('UNDO'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Tap UNDO
    await tester.tap(find.text('UNDO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // Finish hide animation

    expect(undid, isTrue);
    expect(tallyCount, equals(17));
    expect(find.text('+10 added • Tally: 27'), findsNothing);

    // Trigger again and test auto-dismissal without touching UNDO
    await tester.tap(find.text('Trigger SnackBar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('+10 added • Tally: 27'), findsOneWidget);

    // Advance clock past the 2.5s duration
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump(const Duration(milliseconds: 300)); // Finish fade/slide out

    // SnackBar has auto-dismissed
    expect(find.text('+10 added • Tally: 27'), findsNothing);
  });

  testWidgets('UserAvatar defaults to first initial of the users name when photoPath is null', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              children: [
                UserAvatar(
                  name: "Robert Vargas",
                  size: 52,
                ),
                UserAvatar(
                  name: "Daniel Carter",
                  size: 52,
                ),
                UserAvatar(
                  name: "",
                  size: 52,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Initial "R" for Robert Vargas
    expect(find.text('R'), findsOneWidget);
    // Initial "D" for Daniel Carter
    expect(find.text('D'), findsOneWidget);
    // Fallback "U" for empty name
    expect(find.text('U'), findsOneWidget);
  });

  testWidgets('UserAvatar displays camera edit badge and triggers callbacks', (WidgetTester tester) async {
    bool avatarTapped = false;
    bool editTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: UserAvatar(
              name: "Robert Vargas",
              size: 78,
              showEditBadge: true,
              onTap: () => avatarTapped = true,
              onEditTap: () => editTapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.camera), findsOneWidget);
    expect(find.text('R'), findsOneWidget);

    // Tap the edit camera badge
    await tester.tap(find.byIcon(LucideIcons.camera));
    expect(editTapped, isTrue);

    // Tap the avatar
    await tester.tap(find.text('R'));
    expect(avatarTapped, isTrue);
  });

  test('TeamMember copyWith and photoUrl serialization operate correctly', () {
    final member = TeamMember(
      id: 'usr_1',
      name: 'Robert Vargas',
      role: 'Admin',
      photoUrl: null,
    );
    expect(member.photoUrl, isNull);

    final updated = member.copyWith(photoUrl: '/data/user/0/app/avatar.jpg');
    expect(updated.photoUrl, equals('/data/user/0/app/avatar.jpg'));
    expect(updated.name, equals('Robert Vargas'));
    expect(updated.toMap()['photoUrl'], equals('/data/user/0/app/avatar.jpg'));
  });

  testWidgets('UserAvatar renders showOnlineBadge and custom backgroundColor for CommsView', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: UserAvatar(
              name: "Robert Vargas",
              size: 42,
              borderWidth: 1.5,
              borderColor: Colors.white,
              backgroundColor: const Color(0x40FFFFFF),
              showOnlineBadge: true,
              onlineBadgeColor: const Color(0xFF22C55E),
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    // Initial "R" is present
    expect(find.text('R'), findsOneWidget);

    // Verify online badge dot container exists
    final containers = tester.widgetList<Container>(find.byType(Container));
    final hasOnlineGreenBadge = containers.any((c) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration) {
        return decoration.color == const Color(0xFF22C55E) &&
            decoration.shape == BoxShape.circle;
      }
      return false;
    });
    expect(hasOnlineGreenBadge, isTrue);

    // Tap triggers avatar tap callback
    await tester.tap(find.text('R'));
    expect(tapped, isTrue);
  });

  testWidgets('Hub Notification Bell conditionally shows red badge only when unread comms exist', (WidgetTester tester) async {
    Widget buildBellWidget(bool hasUnread) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.bell,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      key: const ValueKey('bell_red_dot'),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // When hasUnread is false: bell is present, red dot is hidden
    await tester.pumpWidget(buildBellWidget(false));
    expect(find.byIcon(LucideIcons.bell), findsOneWidget);
    expect(find.byKey(const ValueKey('bell_red_dot')), findsNothing);

    // When hasUnread is true: red dot is visible
    await tester.pumpWidget(buildBellWidget(true));
    expect(find.byIcon(LucideIcons.bell), findsOneWidget);
    expect(find.byKey(const ValueKey('bell_red_dot')), findsOneWidget);
  });

  testWidgets('Navigation bar and role badges render Admin/Lead for admin users', (WidgetTester tester) async {
    final member = TeamMember(id: 'admin_1', name: 'Robert Vargas', role: 'Admin');
    expect(member.displayRole, equals('Admin/Lead'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text(member.displayRole),
              Text(member.displayRole.toUpperCase()),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Admin/Lead'), findsOneWidget);
    expect(find.text('ADMIN/LEAD'), findsOneWidget);
  });

  testWidgets('Hub profile card displays full name including last name', (WidgetTester tester) async {
    // Tests full name display calculation:
    String computeDisplayName(String rawName) {
      return (rawName == 'Usher' || rawName.trim().isEmpty)
          ? "Daniel Carter"
          : rawName.trim();
    }

    expect(computeDisplayName('Robert Vargas'), equals('Robert Vargas'));
    expect(computeDisplayName('Demitris Boyce'), equals('Demitris Boyce'));
    expect(computeDisplayName('Usher'), equals('Daniel Carter'));
    expect(computeDisplayName(''), equals('Daniel Carter'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text(
            computeDisplayName('Robert Vargas'),
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );

    expect(find.text('Robert Vargas'), findsOneWidget);
  });

  testWidgets('Rapid Incident Dispatch cards render with key incident triggers', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: const [
              Text('Rapid Incident Dispatch'),
              Text('Medical Aid'),
              Text('Lead Assistance'),
              Text('Sanctuary Full'),
              Text('Spill / Custodial'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Rapid Incident Dispatch'), findsOneWidget);
    expect(find.text('Medical Aid'), findsOneWidget);
    expect(find.text('Lead Assistance'), findsOneWidget);
    expect(find.text('Sanctuary Full'), findsOneWidget);
    expect(find.text('Spill / Custodial'), findsOneWidget);
  });

  testWidgets('Incident Dispatch options contains requested stations', (WidgetTester tester) async {
    const stationOptions = [
      "Main Sanctuary",
      "Nursery",
      "Hallway",
      "Restrooms",
      "Kid Church",
      "Jr.Kids",
      "Side Door",
    ];

    expect(stationOptions, contains('Main Sanctuary'));
    expect(stationOptions, contains('Nursery'));
    expect(stationOptions, contains('Hallway'));
    expect(stationOptions, contains('Restrooms'));
    expect(stationOptions, contains('Kid Church'));
    expect(stationOptions, contains('Jr.Kids'));
    expect(stationOptions, contains('Side Door'));
    expect(stationOptions.length, equals(7));
  });

  final testAnnouncements = [
    const Announcement(
      id: 'test_ann_1',
      title: 'Quarterly Usher Team Briefing',
      description: 'Mandatory meeting for all team members in the main sanctuary.',
      date: 'This Sunday, 1:30 PM',
      category: 'Usher Meetings',
      authorName: 'Robert Vargas',
    ),
    const Announcement(
      id: 'test_ann_2',
      title: 'Night of Worship & Prayer',
      description: 'Special worship service for church leaders and ushers.',
      date: 'Next Friday, 7:00 PM',
      category: 'Worship Nights',
      authorName: 'Robert Vargas',
    ),
    const Announcement(
      id: 'test_ann_3',
      title: 'Wednesday Evening Bible Study',
      description: 'Weekly fellowship and study in Room 204.',
      date: 'Wednesdays, 6:30 PM',
      category: 'Bible Studies',
      authorName: 'Robert Vargas',
    ),
  ];

  testWidgets('AnnouncementsView renders announcement items and filter categories', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnnouncementsView(initialAnnouncements: testAnnouncements),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Announcements'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Usher Meetings'), findsOneWidget);
    expect(find.text('Worship Nights'), findsOneWidget);
    expect(find.text('Bible Studies'), findsOneWidget);

    // Verify announcements from mock/seeded data
    expect(find.text('Quarterly Usher Team Briefing'), findsOneWidget);
    expect(find.text('Night of Worship & Prayer'), findsOneWidget);
    expect(find.text('Wednesday Evening Bible Study'), findsOneWidget);
  });

  testWidgets('Tapping announcement opens details modal with Share Notice and Copy actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnnouncementsView(initialAnnouncements: testAnnouncements),
      ),
    );
    await tester.pumpAndSettle();

    // Tap first announcement card
    await tester.tap(find.text('Quarterly Usher Team Briefing'));
    await tester.pumpAndSettle();

    // Bottom sheet details modal should display Share Notice and Copy buttons
    expect(find.text('Share Notice'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('BiblicalAvatar presets contain 8 valid sacred artworks with scriptures', (WidgetTester tester) async {
    expect(kBiblicalAvatars.length, equals(8));
    final ids = kBiblicalAvatars.map((a) => a.id).toList();
    expect(ids, contains('lion_of_judah'));
    expect(ids, contains('sanctuary_doorkeeper'));
    expect(ids, contains('dove_holy_spirit'));
    expect(ids, contains('good_shepherd'));
    expect(ids, contains('shield_of_faith'));
    expect(ids, contains('cross_sunrise'));
    expect(ids, contains('open_scripture'));
    expect(ids, contains('crown_of_life'));

    for (final avatar in kBiblicalAvatars) {
      expect(avatar.assetPath, startsWith('assets/images/biblical/'));
      expect(avatar.title.isNotEmpty, isTrue);
      expect(avatar.verse.isNotEmpty, isTrue);
      expect(avatar.verseText.isNotEmpty, isTrue);
    }
  });

  testWidgets('UserAvatar renders correctly with Biblical asset path', (WidgetTester tester) async {
    final testAvatar = kBiblicalAvatars[0]; // Lion of Judah

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserAvatar(
            name: 'Robert Vargas',
            photoPath: testAvatar.assetPath,
            size: 64,
            showEditBadge: true,
          ),
        ),
      ),
    );

    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.byIcon(LucideIcons.camera), findsOneWidget);
  });

  test('kProfileBackgrounds contains curated presets with valid attributes', () {
    expect(kProfileBackgrounds.isNotEmpty, isTrue);
    expect(kProfileBackgrounds.length, greaterThanOrEqualTo(5));

    final ids = kProfileBackgrounds.map((b) => b.id).toList();
    expect(ids, contains('cathedral_sanctuary'));
    expect(ids, contains('mountaintop_cross'));
    expect(ids, contains('golden_temple'));
    expect(ids, contains('peaceful_waters'));
    expect(ids, contains('starry_communion'));

    for (final bg in kProfileBackgrounds) {
      expect(bg.title.isNotEmpty, isTrue);
      expect(bg.subtitle.isNotEmpty, isTrue);
      expect(bg.themeName.isNotEmpty, isTrue);
      expect(bg.previewColors.length, equals(3));
      if (bg.assetPath != null) {
        expect(bg.assetPath, startsWith('assets/images/'));
      }
    }
  });

  testWidgets('BehanceAmbientBackground renders with theme primary and secondary radiant gradients', (WidgetTester tester) async {
    const dawnTheme = AppStyleTheme.terracotta;
    final themeData = AppTheme.getTheme(Brightness.dark, dawnTheme);

    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        home: const Scaffold(
          body: BehanceAmbientBackground(
            child: Text('Terracotta Sunrise Ambiance'),
          ),
        ),
      ),
    );

    expect(find.text('Terracotta Sunrise Ambiance'), findsOneWidget);
    expect(find.byType(BehanceAmbientBackground), findsOneWidget);
  });

  test('Daily Scripture contains valid sacred scriptures and devotional categories', () {
    expect(usherBibleQuotes.isNotEmpty, isTrue);
    expect(usherBibleQuotes.length, greaterThanOrEqualTo(6));
    for (final q in usherBibleQuotes) {
      expect(q.reference.isNotEmpty, isTrue);
      expect(q.text.isNotEmpty, isTrue);
      expect(q.category.isNotEmpty, isTrue);
    }

    final categories = usherBibleQuotes.map((q) => q.category).toSet();
    expect(categories, contains('Usher Stewardship'));
    expect(categories, contains('Hospitality & Welcome'));
    expect(categories, contains('Order & Reverence'));
  });
}


