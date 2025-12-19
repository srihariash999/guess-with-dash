enum GameStatus {
  waiting,
  playing,
  completed,
}

enum TurnState {
  asking,
  guessing,
}

class GameState {
  final GameStatus status;
  final String? currentTurnPlayerId;
  final TurnState turnState;
  final String? winnerId;
  final Map<String, String>? assignedAnimals; // playerId -> animalName

  GameState({
    this.status = GameStatus.waiting,
    this.currentTurnPlayerId,
    this.turnState = TurnState.asking,
    this.winnerId,
    this.assignedAnimals,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'currentTurnPlayerId': currentTurnPlayerId,
      'turnState': turnState.name,
      'winnerId': winnerId,
      'assignedAnimals': assignedAnimals,
    };
  }

  factory GameState.fromMap(Map<String, dynamic> map) {
    return GameState(
      status: GameStatus.values.firstWhere((e) => e.name == map['status'],
          orElse: () => GameStatus.waiting),
      currentTurnPlayerId: map['currentTurnPlayerId'],
      turnState: TurnState.values.firstWhere((e) => e.name == map['turnState'],
          orElse: () => TurnState.asking),
      winnerId: map['winnerId'],
      assignedAnimals: map['assignedAnimals'] != null
          ? Map<String, String>.from(map['assignedAnimals'])
          : null,
    );
  }
}
