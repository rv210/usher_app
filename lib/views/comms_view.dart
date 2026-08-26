import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Team Comms Feed"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: firebaseService.commsMessages.isEmpty
                  ? Center(
                      child: Text("No messages yet", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      itemCount: firebaseService.commsMessages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final msg = firebaseService.commsMessages[index];
                        final authorName = msg.authorName ?? "Usher";

                        return DribbbleGlassContainer(
                          borderRadius: 22,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      gradient: context.activeGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              authorName,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: context.textPrimaryColor,
                                              ),
                                            ),
                                            if (msg.edited) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                "(edited)",
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                  color: context.textSecondaryColor,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (msg.createdAt != null)
                                          Text(
                                            msg.createdAt!.contains('T') ? msg.createdAt!.split('T').first : msg.createdAt!,
                                            style: GoogleFonts.inter(fontSize: 11, color: context.textSecondaryColor),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        icon: Icon(LucideIcons.edit2, size: 16, color: Theme.of(context).primaryColor),
                                        tooltip: "Edit Message",
                                        onPressed: () => _showEditMessageDialog(context, firebaseService, msg),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                                        tooltip: "Delete Message",
                                        onPressed: () => _confirmDeleteMessage(context, firebaseService, msg.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                msg.text,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Message Composer Input Box
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMessageDialog(BuildContext context, FirebaseService firebaseService, CommsMessage message) {
    final editController = TextEditingController(text: message.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Edit Comms Message", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Edit your message...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                firebaseService.editCommsMessage(message.id, editController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMessage(BuildContext context, FirebaseService firebaseService, String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Delete Message?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to remove this update from team comms?"),
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
