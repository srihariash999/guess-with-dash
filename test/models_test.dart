import 'package:flutter_test/flutter_test.dart';
import 'package:guess_with_dash/models/game_state.dart';
import 'package:guess_with_dash/models/player.dart';
import 'package:guess_with_dash/models/lobby.dart';

void main() {
  group('Model Tests', () {
    test('Player serialization', () {
      final player = Player(id: '123', name: 'TestPlayer', isHost: true);
      final map = player.toMap();
      final player2 = Player.fromMap(map);
      
      expect(player2.id, player.id);
      expect(player2.name, player.name);
      expect(player2.isHost, player.isHost);
    });

    test('GameState initialization', () {
      final state = GameState();
      expect(state.status, GameStatus.waiting);
      expect(state.turnState, TurnState.asking);
    });
    
    test('Lobby serialization', () {
      final lobby = Lobby(
        id: 'LOBBY1',
        players: [],
        gameState: GameState(),
        createdAt: DateTime.now(),
      );
      
      final map = lobby.toMap();
      final lobby2 = Lobby.fromMap(map);
      
      expect(lobby2.id, lobby.id);
      expect(lobby2.players.length, 0);
    });
  });
}
