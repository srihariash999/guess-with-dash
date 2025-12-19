import 'game_state.dart';
import 'player.dart';

class Lobby {
  final String id;
  final List<Player> players;
  final GameState gameState;
  final DateTime createdAt;

  Lobby({
    required this.id,
    required this.players,
    required this.gameState,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'players': players.map((p) => p.toMap()).toList(),
      'gameState': gameState.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Lobby.fromMap(Map<String, dynamic> map) {
    return Lobby(
      id: map['id'] ?? '',
      players: (map['players'] as List<dynamic>?)
              ?.map((p) => Player.fromMap(p))
              .toList() ??
          [],
      gameState: GameState.fromMap(map['gameState'] ?? {}),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
