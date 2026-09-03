import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/comms_message.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class CommsView extends StatefulWidget {
  const CommsView({super.key});

  @override
  State<CommsView> createState() => _CommsViewState();
}

class _CommsViewState extends State<CommsView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final isComp = _messageController.text.trim().isNotEmpty;
      if (isComp != _isComposing) {
        setState(() => _isComposing = isComp);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(FirebaseService firebaseService, [String? customText, String? imageUrl]) {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty && (imageUrl == null || imageUrl.isEmpty)) return;

    firebaseService.postCommsMessage(text, imageUrl: imageUrl);
    if (customText == null) {
      _messageController.clear();
    }
    _scrollToBottom();
  }

  DateTime? _parseTimestamp(String? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    if (diff < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMMM d, yyyy').format(date);
  }

  void _showAlertTypeSelector(BuildContext context, FirebaseService firebaseService) {
    final alertTypes = [
      {
        'title': 'Medical Emergency',
        'subtitle': 'Immediate first aid & 3-usher response',
        'icon': LucideIcons.heartPulse,
        'color': const Color(0xFFEF4444),
        'message': '🚨 [MEDICAL ALERT]: Immediate medical assistance needed at my station.',
      },
      {
        'title': 'Security / Disturbance',
        'subtitle': 'Discreet lead usher / security presence',
        'icon': LucideIcons.shieldAlert,
        'color': const Color(0xFFF97316),
        'message': '🛡️ [SECURITY ALERT]: Lead usher / security presence requested at station.',
      },
      {
        'title': 'Sanctuary Full / Overflow',
        'subtitle': 'Main seating at capacity · open overflow',
        'icon': LucideIcons.users,
        'color': const Color(0xFFEAB308),
        'message': '⚠️ [SEATING ALERT]: Main sanctuary reaching full capacity. Please open overflow.',
      },
      {
        'title': 'Station Relief / Sub-In',
        'subtitle': 'Temporary coverage needed at post',
        'icon': LucideIcons.userCheck,
        'color': const Color(0xFF3B82F6),
        'message': '📍 [STATION RELIEF]: Requesting temporary relief / coverage at station.',
      },
      {
        'title': 'Doors Held / In Progress',
        'subtitle': 'Hold doors for corporate prayer / sermon',
        'icon': LucideIcons.doorClosed,
        'color': const Color(0xFF8B5CF6),
        'message': '🚪 [DOOR PROTOCOL]: Sanctuary doors closed for prayer / sermon.',
      },
      {
        'title': 'Facility / Spill Cleanup',
        'subtitle': 'Aisle maintenance / spill attention',
        'icon': LucideIcons.sparkles,
        'color': const Color(0xFF14B8A6),
        'message': '🧹 [FACILITY ALERT]: Cleanup / spill assistance needed in sanctuary.',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.88,
        builder: (_, scrollCtl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.alertOctagon, color: Color(0xFFEF4444), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Alert Type",
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Instant broadcast to all active ushers",
                          style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: alertTypes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = alertTypes[idx];
                    final color = item['color'] as Color;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: color.withValues(alpha: 0.25), width: 1.2),
                      ),
                      tileColor: color.withValues(alpha: 0.07),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'] as IconData, color: color, size: 22),
                      ),
                      title: Text(
                        item['title'] as String,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        item['subtitle'] as String,
                        style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Send",
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendMessage(firebaseService, item['message'] as String);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${item['title']} broadcasted to team"),
                            backgroundColor: color,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCameraPrompt(BuildContext context, FirebaseService firebaseService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Station Photo Snapshot",
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Capture live status or upload photo from gallery",
                style: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor),
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.camera, color: Theme.of(context).primaryColor, size: 24),
                ),
                title: Text("Take Photo with Camera", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                subtitle: const Text("Open device camera for instant capture"),
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  _capturePhoto(context, firebaseService, ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: context.textSecondaryColor.withValues(alpha: 0.08),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.textSecondaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.image, color: context.textPrimaryColor, size: 24),
                ),
                title: Text("Choose from Gallery", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                subtitle: const Text("Select saved sanctuary or station photo"),
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  _capturePhoto(context, firebaseService, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capturePhoto(
    BuildContext context,
    FirebaseService firebaseService,
    ImageSource source,
  ) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (!context.mounted) return;
      _showPhotoConfirmDialog(context, firebaseService, bytes, base64String);
    } catch (e) {
      debugPrint("Photo capture error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Camera error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPhotoConfirmDialog(
    BuildContext context,
    FirebaseService firebaseService,
    Uint8List bytes,
    String base64String,
  ) {
    final captionController = TextEditingController(text: "📸 Station Status Snapshot");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Send Station Snapshot",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      bytes,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: captionController,
                    decoration: InputDecoration(
                      hintText: "Add a caption / station note...",
                      prefixIcon: const Icon(LucideIcons.messageSquare, size: 18),
                      filled: true,
                      fillColor: Theme.of(ctx).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(LucideIcons.sendHorizontal, size: 20),
                    label: Text(
                      "Send Snapshot to Team",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _sendMessage(
                        firebaseService,
                        captionController.text.trim(),
                        base64String,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditMessageDialog(
    BuildContext context,
    FirebaseService firebaseService,
    CommsMessage message,
  ) {
    final editController = TextEditingController(text: message.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Edit Comms Message",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: editController,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Edit your message..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                firebaseService.editCommsMessage(
                  message.id,
                  editController.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMessage(
    BuildContext context,
    FirebaseService firebaseService,
    String messageId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Delete Message?",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to remove this update from team comms?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              firebaseService.deleteCommsMessage(messageId);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllMessages(
    BuildContext context,
    FirebaseService firebaseService,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Clear All Messages?",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to permanently clear all messages from the team comms feed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              firebaseService.clearAllCommsMessages();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("All comms messages cleared!"),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    // Sit snug directly above the floating bottom nav bar (or above keyboard)
    final composerBottomPadding = isKeyboardOpen
        ? 6.0
        : (bottomSafeArea > 0 ? (bottomSafeArea + 44.0) : 48.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = firebaseService.userProfile;
    final signedInUserName = (profile?.name != null && profile!.name!.trim().isNotEmpty && profile.name != 'Usher')
        ? profile.name!.trim()
        : (firebaseService.currentUser?.displayName != null && firebaseService.currentUser!.displayName!.trim().isNotEmpty)
            ? firebaseService.currentUser!.displayName!.trim()
            : (firebaseService.currentUser?.email != null && firebaseService.currentUser!.email!.isNotEmpty)
                ? firebaseService.currentUser!.email!.split('@').first
                : (firebaseService.dashboardLeadName.isNotEmpty ? firebaseService.dashboardLeadName : "Guardians Comms");

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF0F0E13) : const Color(0xFFF1F5F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            gradient: context.activeGradient,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.25),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            signedInUserName.isNotEmpty ? signedInUserName[0].toUpperCase() : 'U',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signedInUserName,
                          style: GoogleFonts.outfit(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Online",
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF86EFAC),
                                ),
                              ),
                              TextSpan(
                                text: " • team live channel",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  if (firebaseService.commsMessages.isNotEmpty)
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                      tooltip: "Clear All Messages",
                      onPressed: () => _confirmClearAllMessages(context, firebaseService),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Canvas Wallpaper
          Positioned.fill(
            child: CustomPaint(
              painter: _ChatWallpaperPatternPainter(
                color: isDark ? Colors.white.withValues(alpha: 0.025) : Colors.black.withValues(alpha: 0.035),
              ),
            ),
          ),

          // Main Message Feed & Composer
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! > 6) {
                FocusScope.of(context).unfocus();
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                // Messages List
                Expanded(
                  child: firebaseService.commsMessages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.messageSquare, size: 36, color: Theme.of(context).primaryColor),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Guardians Team Feed",
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Send the first message to update the usher team",
                                style: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor),
                              ),
                            ],
                          ),
                        )
                      : NotificationListener<ScrollUpdateNotification>(
                          onNotification: (notification) {
                            if (notification.scrollDelta != null && notification.scrollDelta! < -4) {
                              if (FocusScope.of(context).hasFocus) {
                                FocusScope.of(context).unfocus();
                              }
                            }
                            return false;
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                            itemCount: firebaseService.commsMessages.length,
                            itemBuilder: (context, index) {
                              final msg = firebaseService.commsMessages[index];
                              final currentUid = firebaseService.currentUser?.uid;
                              final currentEmail = firebaseService.currentUser?.email?.toLowerCase().trim();
                              final currentProfileEmail = firebaseService.userProfile?.email?.toLowerCase().trim();
                              final currentProfileName = firebaseService.userProfile?.name?.trim().toLowerCase();

                              final isAuthor = (currentUid != null && currentUid.isNotEmpty && msg.authorUid == currentUid) ||
                                               (currentEmail != null && currentEmail.isNotEmpty && msg.authorEmail != null && msg.authorEmail!.toLowerCase().trim() == currentEmail) ||
                                               (currentProfileEmail != null && currentProfileEmail.isNotEmpty && msg.authorEmail != null && msg.authorEmail!.toLowerCase().trim() == currentProfileEmail) ||
                                               (currentProfileName != null && currentProfileName.isNotEmpty && msg.authorName != null && msg.authorName!.trim().toLowerCase() == currentProfileName);

                              final roleLower = (firebaseService.userProfile?.role ?? '').toLowerCase();
                              final isAdminUser = roleLower.contains('admin') || roleLower.contains('lead') || roleLower.contains('head');

                              final isMine = isAuthor;
                              final canEdit = isAuthor;
                              final canDelete = isAuthor || isAdminUser;
                              final timestamp = _parseTimestamp(msg.createdAt);
                              final previous = index > 0 ? firebaseService.commsMessages[index - 1] : null;
                              final previousTimestamp = _parseTimestamp(previous?.createdAt);
                              final showDateHeader = timestamp != null && (previousTimestamp == null || !_isSameDay(timestamp, previousTimestamp));
                              final showSenderName = !isMine && (previous == null || previous.authorUid != msg.authorUid || showDateHeader);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showDateHeader)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E1D24) : const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _formatDateHeader(timestamp),
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: context.textSecondaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: _ModernMessengerBubble(
                                      message: msg,
                                      isMine: isMine,
                                      showSenderName: showSenderName,
                                      timeLabel: timestamp != null ? DateFormat('h:mm a').format(timestamp) : null,
                                      onEdit: canEdit ? () => _showEditMessageDialog(context, firebaseService, msg) : null,
                                      onDelete: canDelete ? () => _confirmDeleteMessage(context, firebaseService, msg.id) : null,
                                      onReact: (emoji) {
                                        _sendMessage(firebaseService, "$emoji to: \"${msg.text}\"");
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),

                // Bottom Modern Floating Pill Composer
                AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.fromLTRB(10, 6, 10, composerBottomPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Input Pill Container
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1D24) : Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  maxLines: 4,
                                  minLines: 1,
                                  style: GoogleFonts.inter(fontSize: 15, color: context.textPrimaryColor),
                                  decoration: InputDecoration(
                                    hintText: "Type a message...",
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      color: context.textSecondaryColor.withValues(alpha: 0.65),
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                                icon: const Icon(LucideIcons.alertOctagon, size: 20, color: Color(0xFFEF4444)),
                                tooltip: "Select Alert Type",
                                onPressed: () => _showAlertTypeSelector(context, firebaseService),
                              ),
                              const SizedBox(width: 2),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                                icon: Icon(LucideIcons.camera, size: 20, color: context.textSecondaryColor),
                                tooltip: "Camera snapshot",
                                onPressed: () => _showCameraPrompt(context, firebaseService),
                              ),
                              const SizedBox(width: 6),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Circular Send Button
                      GestureDetector(
                        onTap: () {
                          if (_isComposing) {
                            _sendMessage(firebaseService);
                          }
                        },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _isComposing ? 1.0 : 0.45,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: context.activeGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withValues(alpha: _isComposing ? 0.4 : 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.sendHorizontal,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern Messenger Bubble with Tail, Double Checkmarks, and Emoji Support
class _ModernMessengerBubble extends StatelessWidget {
  final CommsMessage message;
  final bool isMine;
  final bool showSenderName;
  final String? timeLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onReact;

  const _ModernMessengerBubble({
    required this.message,
    required this.isMine,
    required this.showSenderName,
    required this.timeLabel,
    this.onEdit,
    this.onDelete,
    this.onReact,
  });

  bool get _isPureEmoji {
    final t = message.text.trim();
    if (t.isEmpty) return false;
    final emojiRegex = RegExp(
      r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff]){1,4}$',
    );
    return emojiRegex.hasMatch(t);
  }

  void _showReactionAndActionsMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1D24) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji Reactions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ["👍", "❤️", "🙏", "🛡️", "🔥", "😂"].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onReact?.call(emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action Options
              ListTile(
                dense: true,
                leading: const Icon(LucideIcons.copy, size: 20),
                title: Text("Copy Text", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Message copied to clipboard"), duration: Duration(seconds: 1)),
                  );
                },
              ),
              if (onEdit != null)
                ListTile(
                  dense: true,
                  leading: Icon(LucideIcons.edit2, size: 20, color: Theme.of(context).primaryColor),
                  title: Text("Edit Message", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit!();
                  },
                ),
              if (onDelete != null)
                ListTile(
                  dense: true,
                  leading: const Icon(LucideIcons.trash2, size: 20, color: Colors.red),
                  title: Text("Delete Message", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete!();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authorName = message.authorName ?? "Usher";
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // Sent: Vibrant Blue / Primary color matching the mockup
    final sentColor = isMine ? primaryColor : (isDark ? const Color(0xFF26242E) : Colors.white);

    return GestureDetector(
      onTap: () => _showReactionAndActionsMenu(context),
      onLongPress: () => _showReactionAndActionsMenu(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left Sender Avatar
          if (!isMine)
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                gradient: context.activeGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),

          // Left Speech Bubble Tail
          if (!isMine)
            CustomPaint(
              size: const Size(6, 12),
              painter: _ChatBubbleTailPainter(color: sentColor, isMine: false),
            ),

          // Main Bubble Container
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: sentColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMine ? 16 : 2),
                    bottomRight: Radius.circular(isMine ? 2 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMine
                          ? primaryColor.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: _isPureEmoji
                    ? const EdgeInsets.fromLTRB(14, 10, 14, 8)
                    : const EdgeInsets.fromLTRB(14, 9, 14, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sender Name (Incoming group feed)
                    if (showSenderName)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          authorName,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),

                    // Attached Photo Snapshot
                    if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () => _showFullImage(context, message.imageUrl!),
                          child: _buildImageWidget(message.imageUrl!),
                        ),
                      ),
                      if (message.text.isNotEmpty) const SizedBox(height: 6),
                    ],

                    // Message Content
                    if (message.text.isNotEmpty) ...[
                      if (_isPureEmoji)
                        Text(
                          message.text,
                          style: const TextStyle(fontSize: 34),
                        )
                      else
                        Text(
                          message.text,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.35,
                            color: isMine ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ),
                    ],

                    const SizedBox(height: 3),

                    // Timestamp & Read Receipts Row
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        if (message.edited) ...[
                          Text(
                            "edited • ",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: isMine
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : context.textSecondaryColor,
                            ),
                          ),
                        ],
                        if (timeLabel != null)
                          Text(
                            timeLabel!,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isMine
                                  ? Colors.white.withValues(alpha: 0.82)
                                  : context.textSecondaryColor,
                            ),
                          ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.checkCheck,
                            size: 13.5,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),

          // Right Speech Bubble Tail
          if (isMine)
            CustomPaint(
              size: const Size(6, 12),
              painter: _ChatBubbleTailPainter(color: sentColor, isMine: true),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Data = commaIdx != -1 ? imageUrl.substring(commaIdx + 1) : imageUrl;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
        );
      } catch (e) {
        return Container(
          height: 120,
          color: Colors.black26,
          child: const Center(child: Icon(LucideIcons.imageOff, color: Colors.white70)),
        );
      }
    } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
      );
    } else {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
      );
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.88),
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageUrl.startsWith('data:image')
                      ? Image.memory(base64Decode(imageUrl.split(',').last))
                      : imageUrl.startsWith('http')
                          ? Image.network(imageUrl)
                          : Image.file(File(imageUrl)),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter for Speech Bubble Tails matching the mockup
class _ChatBubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isMine;

  _ChatBubbleTailPainter({required this.color, required this.isMine});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isMine) {
      // Right tail
      path.moveTo(0, 0);
      path.quadraticBezierTo(size.width * 0.1, size.height * 0.85, size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else {
      // Left tail
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(size.width * 0.9, size.height * 0.85, 0, size.height);
      path.lineTo(size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChatBubbleTailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isMine != isMine;
}

/// Background doodle/dot wallpaper painter for the chat canvas
class _ChatWallpaperPatternPainter extends CustomPainter {
  final Color color;

  _ChatWallpaperPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacingX = 44.0;
    const spacingY = 44.0;

    for (double x = 16; x < size.width; x += spacingX) {
      for (double y = 16; y < size.height; y += spacingY) {
        final row = (y / spacingY).round();
        final col = (x / spacingX).round();

        if ((row + col) % 3 == 0) {
          canvas.drawCircle(Offset(x, y), 1.4, dotPaint);
        } else if ((row + col) % 3 == 1) {
          canvas.drawLine(Offset(x - 2, y), Offset(x + 2, y), paint);
          canvas.drawLine(Offset(x, y - 2), Offset(x, y + 2), paint);
        } else {
          canvas.drawLine(Offset(x - 1.5, y - 1.5), Offset(x + 1.5, y + 1.5), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChatWallpaperPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
