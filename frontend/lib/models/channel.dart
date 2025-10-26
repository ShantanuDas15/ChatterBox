class Channel {
  final String id;
  final String name;
  final List<String> members;
  final String creatorId;
  final List<String> pendingMembers;
  final String? themeColor;

  Channel({
    required this.id,
    required this.name,
    required this.members,
    required this.creatorId,
    required this.pendingMembers,
    this.themeColor,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      members: List<String>.from(json['members']),
      creatorId: json['creatorId'] ?? '',
      pendingMembers: List<String>.from(json['pendingMembers'] ?? []),
      themeColor: json['themeColor'],
    );
  }
}
