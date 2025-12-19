class Player {
  final String id;
  final String name;
  final bool isReady;
  final bool isHost;

  Player({
    required this.id,
    required this.name,
    this.isReady = false,
    this.isHost = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isReady': isReady,
      'isHost': isHost,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      isReady: map['isReady'] ?? false,
      isHost: map['isHost'] ?? false,
    );
  }
}
