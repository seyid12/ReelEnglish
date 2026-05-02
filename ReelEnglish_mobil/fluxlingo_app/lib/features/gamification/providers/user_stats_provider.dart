import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserStatsState {
  final int currentXP;
  final int userLevel;

  UserStatsState({required this.currentXP, required this.userLevel});

  UserStatsState copyWith({int? currentXP, int? userLevel}) {
    return UserStatsState(
      currentXP: currentXP ?? this.currentXP,
      userLevel: userLevel ?? this.userLevel,
    );
  }
}

class UserStatsNotifier extends Notifier<UserStatsState> {
  @override
  UserStatsState build() {
    return UserStatsState(currentXP: 0, userLevel: 1);
  }

  void addXP(int amount) {
    int newXP = state.currentXP + amount;
    int newLevel = (newXP ~/ 500) + 1; // Her 500 XP'de bir seviye atlar

    state = state.copyWith(
      currentXP: newXP,
      userLevel: newLevel,
    );
  }
}

final userStatsProvider = NotifierProvider<UserStatsNotifier, UserStatsState>(() {
  return UserStatsNotifier();
});
