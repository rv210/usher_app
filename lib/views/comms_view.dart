import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  void _sendMessage(FirebaseService firebaseService) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    firebaseService.postCommsMessage(text);
    _messageController.clear();
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

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final composerBottomPadding = isKeyboardOpen ? 12.0 : (76.0 + bottomSafeArea + 14.0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("Team Comms Feed")),
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
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
                        child: Text(
                          "No messages yet",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : NotificationListener<ScrollUpdateNotification>(
                        onNotification: (notification) {
                          // Dismiss keyboard on downward drag/scroll
                          if (notification.scrollDelta != null && notification.scrollDelta! < -4) {
                            if (FocusScope.of(context).hasFocus) {
                              FocusScope.of(context).unfocus();
                            }
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                          itemCount: firebaseService.commsMessages.length,
                          itemBuilder: (context, index) {
                          final msg = firebaseService.commsMessages[index];
                          final isMine =
                              msg.authorUid != null &&
                              msg.authorUid == firebaseService.currentUser?.uid;
                          final timestamp = _parseTimestamp(msg.createdAt);
                          final previous = index > 0
                              ? firebaseService.commsMessages[index - 1]
                              : null;
                          final previousTimestamp = _parseTimestamp(
                            previous?.createdAt,
                          );
                          final showDateHeader =
                              timestamp != null &&
                              (previousTimestamp == null ||
                                  !_isSameDay(timestamp, previousTimestamp));
                          final showSenderName =
                              !isMine &&
                              (previous == null ||
                                  previous.authorUid != msg.authorUid ||
                                  showDateHeader);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _formatDateHeader(timestamp),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: context.textSecondaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _ChatBubbleRow(
                                  message: msg,
                                  isMine: isMine,
                                  showSenderName: showSenderName,
                                  timeLabel: timestamp != null
                                      ? DateFormat('h:mm a').format(timestamp)
                                      : null,
                                  onEdit: isMine
                                      ? () => _showEditMessageDialog(
                                          context,
                                          firebaseService,
                                          msg,
                                        )
                                      : null,
                                  onDelete: isMine
                                      ? () => _confirmDeleteMessage(
                                          context,
                                          firebaseService,
                                          msg.id,
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
              ),

              // Message Composer Input Box
              AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.fromLTRB(16, 8, 16, composerBottomPadding),
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta != null && details.primaryDelta! > 5) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: DribbbleGlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(8),
                    blur: 20,
                    child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: 3,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: "Post an update for the team...",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _sendMessage(firebaseService),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: context.activeGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
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
}

class _ChatBubbleRow extends StatelessWidget {
  final CommsMessage message;
  final bool isMine;
  final bool showSenderName;
  final String? timeLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ChatBubbleRow({
    required this.message,
    required this.isMine,
    required this.showSenderName,
    required this.timeLabel,
    this.onEdit,
    this.onDelete,
  });

  void _showActions(BuildContext context) {
    if (onEdit == null && onDelete == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                Theme.of(ctx).cardTheme.color ??
                Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                ListTile(
                  leading: Icon(
                    LucideIcons.edit2,
                    color: Theme.of(ctx).primaryColor,
                  ),
                  title: Text(
                    "Edit Message",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit!();
                  },
                ),
              if (onDelete != null)
                ListTile(
                  leading: const Icon(
                    LucideIcons.trash2,
                    color: AppColors.danger,
                  ),
                  title: Text(
                    "Delete Message",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
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
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );

    final bubble = Container(
      decoration: BoxDecoration(
        gradient: isMine ? context.activeGradient : null,
        color: isMine
            ? null
            : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05)),
        borderRadius: bubbleRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: bubbleRadius,
        child: InkWell(
          borderRadius: bubbleRadius,
          onLongPress: () => _showActions(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.text,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.4,
                    color: isMine ? Colors.white : context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.edited) ...[
                      Text(
                        "Edited · ",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
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
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.75)
                              : context.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final avatar = Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(right: 8),
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
            fontSize: 13,
          ),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: isMine
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMine) avatar,
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSenderName)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      authorName,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                bubble,
              ],
            ),
          ),
        ),
        if (isMine) const SizedBox(width: 4),
      ],
    );
  }
}
