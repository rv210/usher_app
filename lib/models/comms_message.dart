class CommsMessage {
  final String id;
  final String text;
  final String? imageUrl;
  final String? authorEmail;
  final String? authorName;
  final String? authorUid;
  final String? createdAt;
  final bool edited;

  CommsMessage({
    required this.id,
    required this.text,
    this.imageUrl,
    this.authorEmail,
    this.authorName,
    this.authorUid,
    this.createdAt,
    this.edited = false,
  });

  factory CommsMessage.fromMap(Map<String, dynamic> data, String id) {
    return CommsMessage(
      id: id,
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      authorEmail: data['authorEmail'] as String?,
      authorName: data['authorName'] as String? ?? 'Usher',
      authorUid: data['authorUid'] as String?,
      createdAt: data['createdAt'] as String?,
      edited: data['edited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (authorEmail != null) 'authorEmail': authorEmail,
      if (authorName != null) 'authorName': authorName,
      if (authorUid != null) 'authorUid': authorUid,
      if (createdAt != null) 'createdAt': createdAt,
      'edited': edited,
    };
  }
}
