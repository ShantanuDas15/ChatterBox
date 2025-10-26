class ChatMessage {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp; // We'll parse the timestamp string
  final String? senderPhotoUrl; // <-- ADD THIS

  ChatMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.senderPhotoUrl, // <-- ADD THIS
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      channelId: json['channelId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      senderPhotoUrl: json['senderPhotoUrl'], // <-- ADD THIS
    );
  }
}
