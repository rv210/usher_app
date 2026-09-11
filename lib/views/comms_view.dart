import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import '../widgets/user_avatar.dart';

class CommsView extends StatefulWidget {
  final GlobalKey? mediaActionsKey;

  const CommsView({
    super.key,
    this.mediaActionsKey,
  });

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).clearSnackBars();
          Provider.of<FirebaseService>(context, listen: false).markCommsAsRead();
        } catch (_) {}
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
    firebaseService.markCommsAsRead();
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

  void _showGifPicker(BuildContext context, FirebaseService firebaseService) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommsGifPickerSheet(
        onSelectGif: (gifUrl) {
          Navigator.pop(ctx);
          _sendMessage(firebaseService, "", gifUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("GIF shared to team comms!"),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
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


  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final canPop = Navigator.canPop(context);
    // Sit snug directly above the floating bottom nav bar (or above keyboard / safe area if standalone)
    final composerBottomPadding = isKeyboardOpen
        ? 6.0
        : (!canPop
            ? (bottomSafeArea > 0 ? (bottomSafeArea + 44.0) : 48.0)
            : (bottomSafeArea > 0 ? (bottomSafeArea + 8.0) : 14.0));
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
                  if (canPop) ...[
                    IconButton(
                      icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: "Back",
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 10),
                  ],
                  UserAvatar(
                    photoPath: firebaseService.userCustomPhotoPath,
                    name: signedInUserName,
                    size: 42,
                    borderWidth: 1.5,
                    borderColor: Colors.white.withValues(alpha: 0.6),
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    showOnlineBadge: true,
                    onTap: () => showPhotoPickerSheet(context, firebaseService),
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
                              Container(
                                key: widget.mediaActionsKey,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                                    const SizedBox(width: 2),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                      icon: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: context.textSecondaryColor.withValues(alpha: 0.6), width: 1.2),
                                        ),
                                        child: Text(
                                          "GIF",
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: context.textSecondaryColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      tooltip: "Send GIF",
                                      onPressed: () => _showGifPicker(context, firebaseService),
                                    ),
                                  ],
                                ),
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

    String? senderPhoto;
    try {
      final fb = Provider.of<FirebaseService>(context, listen: false);
      if (message.authorEmail != null &&
          fb.currentUser?.email != null &&
          message.authorEmail!.toLowerCase() == fb.currentUser!.email!.toLowerCase()) {
        senderPhoto = fb.userCustomPhotoPath;
      } else {
        for (final member in fb.liveRoster) {
          if (message.authorEmail != null &&
              message.authorEmail!.isNotEmpty &&
              member.email != null &&
              member.email!.toLowerCase() == message.authorEmail!.toLowerCase()) {
            if (member.photoUrl != null && member.photoUrl!.isNotEmpty) {
              senderPhoto = member.photoUrl;
              break;
            }
          }
          if (message.authorName != null &&
              message.authorName!.isNotEmpty &&
              member.name != null &&
              member.name!.toLowerCase() == message.authorName!.toLowerCase()) {
            if (member.photoUrl != null && member.photoUrl!.isNotEmpty) {
              senderPhoto = member.photoUrl;
              break;
            }
          }
        }
      }
    } catch (_) {}

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
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: UserAvatar(
                photoPath: senderPhoto,
                name: authorName,
                size: 30,
                borderWidth: 1,
                borderColor: Colors.white.withValues(alpha: 0.35),
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

                    // Attached Photo / GIF Snapshot
                    if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: GestureDetector(
                          onTap: () => _showFullImage(context, message.imageUrl!),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              _buildImageWidget(message.imageUrl!),
                              if (message.imageUrl!.toLowerCase().contains('.gif'))
                                Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "GIF",
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
        height: 185,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 150,
            color: Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 120,
            color: Colors.black26,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.imageOff, color: Colors.white70),
                  SizedBox(height: 4),
                  Text("Image/GIF unavailable", style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          );
        },
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

/// GIF model representation
class _CommsGif {
  final String title;
  final String category;
  final String url;
  final List<String> tags;

  const _CommsGif({
    required this.title,
    required this.category,
    required this.url,
    required this.tags,
  });
}

const List<_CommsGif> _curatedGifs = [
  // Praise & Worship
  _CommsGif(
    title: "Praise & Worship",
    category: "Praise & Amen",
    url: "https://media.giphy.com/media/26gsjCZpPolPr3sBy/200.gif",
    tags: ["praise", "worship", "clap", "church", "service", "glory", "joy"],
  ),
  _CommsGif(
    title: "Amen Preach",
    category: "Praise & Amen",
    url: "https://media.giphy.com/media/doUu2ByZDbPYQ/200.gif",
    tags: ["amen", "preach", "truth", "pastor", "church", "yes"],
  ),
  _CommsGif(
    title: "Hallelujah Prayer",
    category: "Praise & Amen",
    url: "https://media.giphy.com/media/3o7TKoWXm3okO1kgHC/200.gif",
    tags: ["prayer", "hallelujah", "holy", "blessed", "jesus", "amen"],
  ),
  _CommsGif(
    title: "Gospel Choir",
    category: "Praise & Amen",
    url: "https://media.giphy.com/media/l0HlFZ3c4NENSLQRi/200.gif",
    tags: ["choir", "singing", "gospel", "worship", "music", "joy"],
  ),
  _CommsGif(
    title: "Hands in the Air",
    category: "Praise & Amen",
    url: "https://media.giphy.com/media/3o7btPCcdNniyf0ArS/200.gif",
    tags: ["hands up", "praise", "surrender", "worship", "amen"],
  ),
  _CommsGif(
    title: "Preach Pastor",
    category: "Praise & Amen",
    url: "https://media.giphy.com/media/xT5LMHxhOfscxPfIfm/200.gif",
    tags: ["preach", "word", "pastor", "amen", "church", "listening"],
  ),

  // Welcome & Greeters
  _CommsGif(
    title: "Waving Welcome",
    category: "Welcome",
    url: "https://media.giphy.com/media/3oEjI5VtIhHvK37WYo/200.gif",
    tags: ["welcome", "hello", "wave", "greeting", "door", "guest", "usher"],
  ),
  _CommsGif(
    title: "Warm Welcome",
    category: "Welcome",
    url: "https://media.giphy.com/media/icUEIrjnUuFCWDxFpU/200.gif",
    tags: ["welcome", "visitor", "smiling", "friendly", "usher", "hi"],
  ),
  _CommsGif(
    title: "Blessed Day",
    category: "Welcome",
    url: "https://media.giphy.com/media/3ohzdIuqJoo8QdKlnW/200.gif",
    tags: ["blessed", "smile", "morning", "good morning", "sunday", "greeting"],
  ),

  // Clapping & Celebration
  _CommsGif(
    title: "Standing Ovation",
    category: "Clapping & Joy",
    url: "https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/200.gif",
    tags: ["applause", "clapping", "cheering", "standing", "ovation", "bravo"],
  ),
  _CommsGif(
    title: "Clapping Hands",
    category: "Clapping & Joy",
    url: "https://media.giphy.com/media/3o7abKhOpu0NwenH3O/200.gif",
    tags: ["clap", "clapping", "hands", "cheer", "good job", "praise"],
  ),
  _CommsGif(
    title: "Celebration Toast",
    category: "Clapping & Joy",
    url: "https://media.giphy.com/media/g9582DNuQppxC/200.gif",
    tags: ["cheers", "celebrate", "toast", "congrats", "victory"],
  ),
  _CommsGif(
    title: "Victory Dance",
    category: "Clapping & Joy",
    url: "https://media.giphy.com/media/111ebonMs90YLu/200.gif",
    tags: ["dance", "carlton", "happy", "joy", "celebration", "excited"],
  ),
  _CommsGif(
    title: "Bravo & Applause",
    category: "Clapping & Joy",
    url: "https://media.giphy.com/media/artj92V8o75VPL7AeQ/200.gif",
    tags: ["bravo", "applause", "clap", "great job", "well done"],
  ),
  _CommsGif(
    title: "Sunday Rejoicing",
    category: "Clapping & Joy",
    url: "https://media.giphy.com/media/3o6Zt6KHxJTbXCnSvu/200.gif",
    tags: ["rejoice", "celebrate", "happy", "blessed", "sunday", "church"],
  ),

  // Encouragement & Teamwork
  _CommsGif(
    title: "Thumbs Up",
    category: "Encouragement",
    url: "https://media.giphy.com/media/l3q2XhfQ8oCkm1Ts4/200.gif",
    tags: ["thumbs up", "great", "awesome", "good", "approved", "roger"],
  ),
  _CommsGif(
    title: "Fist Bump",
    category: "Encouragement",
    url: "https://media.giphy.com/media/3oEjHV0z8S7WM4MwnK/200.gif",
    tags: ["fist bump", "team", "solid", "brother", "sister", "unity"],
  ),
  _CommsGif(
    title: "High Five",
    category: "Encouragement",
    url: "https://media.giphy.com/media/26FxCOdhlvEQXbeH6/200.gif",
    tags: ["high five", "teamwork", "partner", "great job", "success"],
  ),
  _CommsGif(
    title: "Usher Salute",
    category: "Encouragement",
    url: "https://media.giphy.com/media/3o7TKUM3IgJBX2as9O/200.gif",
    tags: ["salute", "ready", "duty", "station", "watchman", "lead", "roger"],
  ),
  _CommsGif(
    title: "Approved & Excellent",
    category: "Encouragement",
    url: "https://media.giphy.com/media/3oKIPnAiaMCws8nOsE/200.gif",
    tags: ["approved", "excellent", "check", "ready", "100", "lead"],
  ),
  _CommsGif(
    title: "Thank You / Grateful",
    category: "Encouragement",
    url: "https://media.giphy.com/media/xT9IgG50Fb7Mi0prBC/200.gif",
    tags: ["thank you", "thanks", "grateful", "appreciate", "blessings"],
  ),

  // Reactions & Humor
  _CommsGif(
    title: "Steve Harvey Church Nod",
    category: "Reactions",
    url: "https://media.giphy.com/media/3o7aD2saalBwwftBIY/200.gif",
    tags: ["steve harvey", "nod", "church", "reaction", "funny", "preach"],
  ),
  _CommsGif(
    title: "Praise Break",
    category: "Reactions",
    url: "https://media.giphy.com/media/3o7TKMt1VVNkHV2PaE/200.gif",
    tags: ["praise break", "shout", "dancing", "spirit", "hallelujah"],
  ),
  _CommsGif(
    title: "Excited for Service",
    category: "Reactions",
    url: "https://media.giphy.com/media/26u4cqiYI30juCOGY/200.gif",
    tags: ["excited", "ready", "service", "start", "sunday", "energy"],
  ),
];

class _CommsGifPickerSheet extends StatefulWidget {
  final ValueChanged<String> onSelectGif;

  const _CommsGifPickerSheet({required this.onSelectGif});

  @override
  State<_CommsGifPickerSheet> createState() => _CommsGifPickerSheetState();
}

class _CommsGifPickerSheetState extends State<_CommsGifPickerSheet> {
  static const String _defaultGiphyApiKey = 'w6WM8YH0JHpMNcqUspt6WzDB5OzQCnsB';

  String get _giphyApiKey {
    try {
      final envKey = dotenv.env['GIPHY_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) return envKey;
    } catch (_) {}
    return _defaultGiphyApiKey;
  }

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customUrlController = TextEditingController();
  String _selectedCategory = "All";
  String _searchQuery = "";

  List<_CommsGif> _apiGifs = [];
  bool _isLoadingGiphy = false;
  Timer? _debounceTimer;

  final List<String> _categories = [
    "All",
    "Praise & Amen",
    "Welcome",
    "Clapping & Joy",
    "Encouragement",
    "Reactions",
    "Custom URL",
  ];

  @override
  void initState() {
    super.initState();
    _fetchGiphyTrending();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchGiphyTrending() async {
    setState(() => _isLoadingGiphy = true);
    final url = Uri.parse(
      'https://api.giphy.com/v1/gifs/trending?api_key=$_giphyApiKey&limit=30&rating=pg',
    );
    await _performGiphyRequest(url);
  }

  Future<void> _searchGiphy(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (_selectedCategory == "All") {
        _fetchGiphyTrending();
      } else {
        _fetchCategoryGifs(_selectedCategory);
      }
      return;
    }

    setState(() => _isLoadingGiphy = true);
    final encoded = Uri.encodeComponent(q);
    final url = Uri.parse(
      'https://api.giphy.com/v1/gifs/search?api_key=$_giphyApiKey&q=$encoded&limit=30&rating=pg',
    );
    await _performGiphyRequest(url);
  }

  Future<void> _fetchCategoryGifs(String category) async {
    setState(() => _isLoadingGiphy = true);
    String query;
    switch (category) {
      case "Praise & Amen":
        query = "church praise amen worship";
        break;
      case "Welcome":
        query = "welcome greeting waving church";
        break;
      case "Clapping & Joy":
        query = "applause clapping cheering celebration";
        break;
      case "Encouragement":
        query = "thumbs up great job fist bump team";
        break;
      case "Reactions":
        query = "church funny reaction laughing smile";
        break;
      default:
        _fetchGiphyTrending();
        return;
    }
    final encoded = Uri.encodeComponent(query);
    final url = Uri.parse(
      'https://api.giphy.com/v1/gifs/search?api_key=$_giphyApiKey&q=$encoded&limit=30&rating=pg',
    );
    await _performGiphyRequest(url);
  }

  Future<void> _performGiphyRequest(Uri url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 7);
    try {
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode == 200) {
        final rawBody = await response.transform(utf8.decoder).join();
        final jsonMap = jsonDecode(rawBody) as Map<String, dynamic>;
        final data = jsonMap['data'] as List<dynamic>? ?? [];

        final fetchedGifs = <_CommsGif>[];
        for (final item in data) {
          final title = (item['title'] as String? ?? 'GIF')
              .replaceAll(RegExp(r' GIF$', caseSensitive: false), '')
              .trim();
          final images = item['images'] as Map<String, dynamic>?;
          if (images == null) continue;

          final fixedHeight = images['fixed_height'] as Map<String, dynamic>?;
          final downsized = images['downsized'] as Map<String, dynamic>?;
          final original = images['original'] as Map<String, dynamic>?;

          final gifUrl = fixedHeight?['url'] as String? ??
              downsized?['url'] as String? ??
              original?['url'] as String?;

          if (gifUrl != null && gifUrl.isNotEmpty) {
            fetchedGifs.add(_CommsGif(
              title: title.isNotEmpty ? title : 'Reaction',
              category: _selectedCategory,
              url: gifUrl,
              tags: [],
            ));
          }
        }

        if (mounted) {
          setState(() {
            _apiGifs = fetchedGifs;
            _isLoadingGiphy = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingGiphy = false);
      }
    } catch (e) {
      debugPrint("GIPHY API fetch error: $e");
      if (mounted) setState(() => _isLoadingGiphy = false);
    } finally {
      client.close();
    }
  }

  List<_CommsGif> get _displayGifs {
    if (_apiGifs.isNotEmpty) {
      return _apiGifs;
    }
    // Fallback to offline curated GIFs if API is empty or device is offline
    final query = _searchQuery.trim().toLowerCase();
    return _curatedGifs.where((gif) {
      final matchesCategory = _selectedCategory == "All" || gif.category == _selectedCategory;
      if (!matchesCategory) return false;

      if (query.isEmpty) return true;
      final matchesTitle = gif.title.toLowerCase().contains(query);
      final matchesTags = gif.tags.any((t) => t.toLowerCase().contains(query));
      return matchesTitle || matchesTags;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.72;

    return Container(
      height: sheetHeight,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16141D) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Drag Pill
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sheet Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: context.activeGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.film, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Team GIF Reactions",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "GIPHY",
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: const Color(0xFF00E676),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Search Bar
            if (_selectedCategory != "Custom URL") ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF221F2A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(const Duration(milliseconds: 380), () {
                        _searchGiphy(val);
                      });
                    },
                    style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: "Search GIPHY (praise, amen, welcome, clap)...",
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: context.textSecondaryColor.withValues(alpha: 0.7),
                      ),
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.xCircle, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                                _fetchCategoryGifs(_selectedCategory);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Category Chips Row
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategory = cat;
                        _searchController.clear();
                        _searchQuery = "";
                      });
                      if (cat != "Custom URL") {
                        _fetchCategoryGifs(cat);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? context.activeGradient : null,
                        color: isSelected
                            ? null
                            : (isDark ? const Color(0xFF23202C) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : context.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // Thin GIPHY loading indicator
            if (_isLoadingGiphy)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 2.5,
                    child: LinearProgressIndicator(
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 4.5),

            // Content Area: Either Custom URL Form or Grid of Curated GIFs
            Expanded(
              child: _selectedCategory == "Custom URL"
                  ? _buildCustomUrlView(isDark)
                  : _buildGifsGrid(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomUrlView(bool isDark) {
    final customUrl = _customUrlController.text.trim();
    final isValidUrl = customUrl.startsWith('http://') || customUrl.startsWith('https://');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Send Any Online GIF or Image",
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Paste a direct link to any GIF from GIPHY, Tenor, Imgur, or the web:",
            style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondaryColor),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF221F2A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: TextField(
              controller: _customUrlController,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: "https://.../my_favorite.gif",
                hintStyle: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondaryColor),
                prefixIcon: const Icon(LucideIcons.link, size: 18),
                suffixIcon: customUrl.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.xCircle, size: 16),
                        onPressed: () {
                          _customUrlController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Preview
          if (isValidUrl) ...[
            Text(
              "Preview:",
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                color: Colors.black12,
                child: Image.network(
                  customUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.imageOff, color: Colors.grey),
                        SizedBox(height: 4),
                        Text("Could not load image from this URL", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(LucideIcons.send, size: 18),
            label: Text(
              "Send Custom GIF",
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: isValidUrl ? () => widget.onSelectGif(customUrl) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGifsGrid(bool isDark) {
    if (_isLoadingGiphy && _apiGifs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              "Loading GIPHY...",
              style: GoogleFonts.outfit(fontSize: 13, color: context.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    final gifs = _displayGifs;

    if (gifs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX, size: 40, color: context.textSecondaryColor),
            const SizedBox(height: 8),
            Text(
              "No GIFs found for '$_searchQuery'",
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Try searching for 'praise', 'amen', or 'welcome'",
              style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemCount: gifs.length,
      itemBuilder: (context, index) {
        final gif = gifs[index];

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onSelectGif(gif.url);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF221F2A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    gif.url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(LucideIcons.imageOff, color: Colors.grey, size: 24),
                    ),
                  ),

                  // Bottom Gradient Title Overlay
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.78),
                          ],
                        ),
                      ),
                      child: Text(
                        gif.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            const Shadow(blurRadius: 3, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

