import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../models/lobby.dart';
import '../models/game_state.dart';
import '../models/message.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class GameScreen extends StatefulWidget {
  final String lobbyId;
  final String playerId;

  const GameScreen({
    super.key,
    required this.lobbyId,
    required this.playerId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      body: StreamBuilder<Lobby>(
        stream: firebaseService.streamLobby(widget.lobbyId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final lobby = snapshot.data!;
          final gameState = lobby.gameState;
          
          if (gameState.status == GameStatus.completed) {
            return _buildGameOverView(context, lobby, firebaseService);
          }

          final myAnimal = gameState.assignedAnimals?[widget.playerId] ?? 'Unknown';
          final isMyTurn = gameState.currentTurnPlayerId == widget.playerId;
          final opponent = lobby.players.firstWhere((p) => p.id != widget.playerId);

          return Row(
            children: [
              // Main Game Area
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Dash Area
                    Expanded(
                      flex: 2,
                      child: _buildDashHost(context, isMyTurn, opponent.name),
                    ),
                    
                    // Controls Area
                    Container(
                      padding: const EdgeInsets.all(24),
                      color: AppTheme.surfaceColor,
                      child: Column(
                        children: [
                          Text(
                            isMyTurn ? "It's your turn to ask/guess!" : "Waiting for ${opponent.name}...",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Your Card (Hidden/Revealed logic can be added here)
                              _buildPlayerCard(myAnimal),
                              const SizedBox(width: 32),
                              // Controls
                              if (isMyTurn) ...[
                                ElevatedButton.icon(
                                  onPressed: () => _handleTurnEnd(firebaseService, lobby),
                                  icon: const Icon(Icons.check),
                                  label: const Text('End Turn'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor, foregroundColor: Colors.black),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _handleGuessCorrectly(firebaseService, lobby),
                                  icon: const Icon(Icons.star),
                                  label: const Text('I Guessed Correctly!'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                                ),
                              ],
                              const SizedBox(width: 16),
                              OutlinedButton(
                                onPressed: () => _handleGiveUp(firebaseService, lobby, opponent.id),
                                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor),
                                child: const Text('Give Up'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chat Area
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
                    color: Colors.black26,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: AppTheme.surfaceColor,
                        width: double.infinity,
                        child: const Text('Game Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: StreamBuilder<List<ChatMessage>>(
                          stream: firebaseService.streamMessages(widget.lobbyId),
                          builder: (context, chatSnapshot) {
                            if (!chatSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                            final messages = chatSnapshot.data!;
                            
                            return ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isMe = msg.senderId == widget.playerId;
                                return Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isMe ? AppTheme.primaryColor.withOpacity(0.8) : Colors.grey[800],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(msg.senderName, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                        Text(msg.text),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Ask or Answer...',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _sendMessage(firebaseService),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () => _sendMessage(firebaseService),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashHost(BuildContext context, bool isMyTurn, String opponentName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Speech Bubble
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.zero,
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
            ),
            child: Text(
              isMyTurn 
                  ? "It's your turn! Ask a question or guess ${opponentName}'s animal!"
                  : "$opponentName is thinking...",
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          ).animate().fade().scale(),
          
          // Dash Avatar Placeholder
          const Icon(Icons.flutter_dash, size: 120, color: Colors.blueAccent)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(begin: 0, end: -10, duration: 1000.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String animalName) {
    return Container(
      width: 150,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.amber[200],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('YOUR CARD', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Icon(Icons.pets, size: 48, color: Colors.black87),
          const SizedBox(height: 16),
          Text(
            animalName,
            style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverView(BuildContext context, Lobby lobby, FirebaseService service) {
    final iWon = lobby.gameState.winnerId == widget.playerId;
    final myAnimal = lobby.gameState.assignedAnimals?[widget.playerId];
    final opponent = lobby.players.firstWhere((p) => p.id != widget.playerId);
    final opponentAnimal = lobby.gameState.assignedAnimals?[opponent.id];

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.emoji_events, size: 100, color: iWon ? Colors.amber : Colors.grey),
             const SizedBox(height: 24),
             Text(
               iWon ? 'YOU WON!' : 'GAME OVER',
               style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
             ).animate().scale(duration: 500.ms),
             const SizedBox(height: 16),
             Text(
               iWon ? 'Great guessing!' : '${opponent.name} won this round.',
               style: const TextStyle(fontSize: 20, color: Colors.white70),
             ),
             const SizedBox(height: 48),
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 _buildRevealCard(lobby.players.firstWhere((p) => p.id == widget.playerId).name, myAnimal!),
                 const SizedBox(width: 32),
                 _buildRevealCard(opponent.name, opponentAnimal!),
               ],
             ),
             const SizedBox(height: 48),
             ElevatedButton(
               onPressed: () {
                 Navigator.pop(context); // Go back to lobby (or could restart)
               },
               child: const Text('Back to Lobby'),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildRevealCard(String playerName, String animal) {
    return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: AppTheme.surfaceColor,
         borderRadius: BorderRadius.circular(12),
       ),
       child: Column(
         children: [
           Text(playerName, style: const TextStyle(color: Colors.white54)),
           const SizedBox(height: 8),
           Text(animal, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
         ],
       ),
    );
  }

  void _sendMessage(FirebaseService service) {
    if (_messageController.text.trim().isEmpty) return;
    
    // Only allow dash to speak? No, chat is open.
    // Turn restrictions? "both players will have button... while other person is guessing"
    // Chat is likely open always to ask/answer.

    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.playerId,
      senderName: 'Player', // Fetch real name if needed or store locally
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    service.sendMessage(widget.lobbyId, msg);
    _messageController.clear();
  }

  void _handleTurnEnd(FirebaseService service, Lobby lobby) {
    // Just switch turn
    service.switchTurn(widget.lobbyId, widget.playerId);
  }

  void _handleGuessCorrectly(FirebaseService service, Lobby lobby) {
    // I guessed correctly, meaning I WON.
    service.endGame(widget.lobbyId, widget.playerId);
  }

  void _handleGiveUp(FirebaseService service, Lobby lobby, String opponentId) {
    // I give up, Opponent WINS.
    service.endGame(widget.lobbyId, opponentId);
  }
}
