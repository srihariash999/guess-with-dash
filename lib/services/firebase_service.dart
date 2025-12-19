import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/lobby.dart';
import '../models/player.dart';
import '../models/message.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new lobby
  Future<Lobby?> createLobby(String playerName) async {
    try {
      print('Creating lobby for $playerName...');
      String lobbyId = _uuid.v4().substring(0, 6).toUpperCase();
      Player host = Player(
        id: _uuid.v4(),
        name: playerName,
        isHost: true,
        isReady: false,
      );

      Lobby newLobby = Lobby(
        id: lobbyId,
        players: [host],
        gameState: GameState(),
        createdAt: DateTime.now(),
      );

      print('Setting Firestore doc: $lobbyId');
      await _firestore
          .collection(AppConstants.lobbyCollection)
          .doc(lobbyId)
          .set(newLobby.toMap())
          .timeout(const Duration(seconds: 5)); // Fail fast if connection issues
      
      print('Lobby created successfully');
      return newLobby;
    } catch (e) {
      print('Error creating lobby: $e');
      return null;
    }
  }

  // Join an existing lobby
  Future<Player?> joinLobby(String lobbyId, String playerName) async {
    try {
      DocumentReference lobbyRef =
          _firestore.collection(AppConstants.lobbyCollection).doc(lobbyId);

      return _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(lobbyRef);

        if (!snapshot.exists) {
          throw Exception('Lobby not found');
        }

        Lobby lobby = Lobby.fromMap(snapshot.data() as Map<String, dynamic>);

        if (lobby.players.length >= 2) {
          throw Exception('Lobby is full. Only 2 players allowed.');
        }

        Player newPlayer = Player(
          id: _uuid.v4(),
          name: playerName,
          isHost: false,
          isReady: false,
        );

        List<Map<String, dynamic>> updatedPlayers =
            lobby.players.map((p) => p.toMap()).toList();
        updatedPlayers.add(newPlayer.toMap());

        transaction.update(lobbyRef, {'players': updatedPlayers});

        return newPlayer;
      });
    } catch (e) {
      print('Error joining lobby: $e');
      return null;
    }
  }

  // Stream lobby updates
  Stream<Lobby> streamLobby(String lobbyId) {
    return _firestore
        .collection(AppConstants.lobbyCollection)
        .doc(lobbyId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return Lobby.fromMap(snapshot.data() as Map<String, dynamic>);
      } else {
        throw Exception('Lobby not found');
      }
    });
  }

  // Send a message
  Future<void> sendMessage(String lobbyId, ChatMessage message) async {
    try {
      await _firestore
          .collection(AppConstants.lobbyCollection)
          .doc(lobbyId)
          .collection(AppConstants.messagesCollection)
          .doc(message.id)
          .set(message.toMap());
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Stream messages
  Stream<List<ChatMessage>> streamMessages(String lobbyId) {
    return _firestore
        .collection(AppConstants.lobbyCollection)
        .doc(lobbyId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .toList();
    });
  }

  // Start Game
  Future<void> startGame(String lobbyId) async {
    try {
      DocumentReference lobbyRef =
          _firestore.collection(AppConstants.lobbyCollection).doc(lobbyId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(lobbyRef);
        if (!snapshot.exists) return;

        Lobby lobby = Lobby.fromMap(snapshot.data() as Map<String, dynamic>);
        if (lobby.players.length < 2) return;

        // Assign animals
        List<String> shuffledAnimals = List.from(AppConstants.animals)..shuffle();
        Map<String, String> assigned = {
          lobby.players[0].id: shuffledAnimals[0],
          lobby.players[1].id: shuffledAnimals[1],
        };

        // Randomly pick who starts
        String firstPlayerId = lobby.players[
                DateTime.now().millisecond % 2]
            .id;

        GameState newGameState = GameState(
          status: GameStatus.playing,
          currentTurnPlayerId: firstPlayerId,
          turnState: TurnState.asking,
          assignedAnimals: assigned,
        );

        transaction.update(lobbyRef, {'gameState': newGameState.toMap()});
      });
    } catch (e) {
      print('Error starting game: $e');
    }
  }

  // End Game (Win/GiveUp)
  Future<void> endGame(String lobbyId, String winnerId) async {
     try {
       await _firestore
          .collection(AppConstants.lobbyCollection)
          .doc(lobbyId)
          .update({
            'gameState.status': GameStatus.completed.name,
            'gameState.winnerId': winnerId,
          });
     } catch (e) {
       print('Error ending game: $e');
     }
  }

  Future<void> switchTurn(String lobbyId, String currentTurnPlayerId) async {
      try {
        DocumentReference lobbyRef =
            _firestore.collection(AppConstants.lobbyCollection).doc(lobbyId);

        await _firestore.runTransaction((transaction) async {
           DocumentSnapshot snapshot = await transaction.get(lobbyRef);
           Lobby lobby = Lobby.fromMap(snapshot.data() as Map<String, dynamic>);
           
           String nextPlayerId = lobby.players.firstWhere((p) => p.id != currentTurnPlayerId).id;
           
           transaction.update(lobbyRef, {
             'gameState.currentTurnPlayerId': nextPlayerId,
             'gameState.turnState': TurnState.asking.name, // Reset to asking
           });
        });
      } catch (e) {
        print('Error switching turn: $e');
      }
  }
}

