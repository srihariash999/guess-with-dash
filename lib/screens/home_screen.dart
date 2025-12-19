import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/lobby.dart';
import '../models/player.dart';
import '../utils/theme.dart';
import 'lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _createNameController = TextEditingController();
  final TextEditingController _joinNameController = TextEditingController(); // Separate name controller
  final TextEditingController _lobbyIdController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.flash_on, size: 64, color: AppTheme.primaryColor), // Placeholder for Dash
              const SizedBox(height: 16),
              Text(
                'Guess With Dash',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Create Section
              const Text('Create a Lobby', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: _createNameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name (Host)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _createLobby(firebaseService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create New Lobby'),
              ),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              
              // Join Section
              const Text('Join a Lobby', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: _joinNameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name (Player)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lobbyIdController,
                decoration: const InputDecoration(
                  labelText: 'Lobby ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isLoading ? null : () => _joinLobby(firebaseService),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Join Lobby'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createLobby(FirebaseService service) async {
    if (_createNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final lobby = await service.createLobby(_createNameController.text.trim());
    setState(() => _isLoading = false);

    if (lobby != null && mounted) {
      final player = lobby.players.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LobbyScreen(
            lobbyId: lobby.id,
            currentPlayerId: player.id,
            isHost: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create lobby')),
      );
    }
  }

  Future<void> _joinLobby(FirebaseService service) async {
    if (_joinNameController.text.trim().isEmpty ||
        _lobbyIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and lobby ID')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final player = await service.joinLobby(
        _lobbyIdController.text.trim().toUpperCase(),
        _joinNameController.text.trim(),
      );
      
      if (player != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LobbyScreen(
              lobbyId: _lobbyIdController.text.trim().toUpperCase(),
              currentPlayerId: player.id,
              isHost: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
