import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/lobby.dart';
import '../models/player.dart';
import '../models/game_state.dart'; // Import GameState logic
import '../utils/theme.dart';
import 'game_screen.dart';

class LobbyScreen extends StatelessWidget {
  final String lobbyId;
  final String currentPlayerId;
  final bool isHost;

  const LobbyScreen({
    super.key,
    required this.lobbyId,
    required this.currentPlayerId,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    return StreamBuilder<Lobby>(
      stream: firebaseService.streamLobby(lobbyId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final lobby = snapshot.data!;

        // Navigate to game if status changes (basic check)
        if (lobby.gameState.status == GameStatus.playing) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             Navigator.pushReplacement(
               context,
               MaterialPageRoute(
                 builder: (_) => GameScreen(
                   lobbyId: lobbyId,
                   playerId: currentPlayerId,
                 ),
               ),
             );
           });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lobby'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Lobby Code Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('LOBBY CODE', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lobby.id,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: lobby.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                      const Text('Share this code with your friend!', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Players List
                Expanded(
                  child: ListView.builder(
                    itemCount: lobby.players.length,
                    itemBuilder: (context, index) {
                      final player = lobby.players[index];
                      final isMe = player.id == currentPlayerId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: player.isHost ? AppTheme.primaryColor : Colors.grey,
                            child: Icon(player.isHost ? Icons.star : Icons.person),
                          ),
                          title: Text(
                            player.name + (isMe ? ' (You)' : ''),
                            style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                          ),
                          subtitle: Text(player.isHost ? 'Host' : 'Player'),
                          trailing: player.isReady
                              ? const Icon(Icons.check_circle, color: AppTheme.secondaryColor)
                              : const Icon(Icons.hourglass_empty, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),

                // Start Game Button (Host only) or Waiting Status
                if (isHost) ...[
                   ElevatedButton(

                    onPressed: lobby.players.length == 2
                        ? () {
                            firebaseService.startGame(lobbyId);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(lobby.players.length == 2 ? 'START GAME' : 'WAITING FOR PLAYER...'),
                  ),
                ] else ...[
                   const Text('Waiting for host to start...', style: TextStyle(color: Colors.white54)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
