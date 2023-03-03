class Validator {
  final String address;
  double stake;
  bool isActive;
  double score;

  Validator({
    required this.address,
    required this.stake,
    required this.isActive,
    this.score = 0,
  });

  void updateScore(double totalStake) {
    final stakePercent = stake / totalStake;
    score = isActive ? stakePercent * 100 : 0;
  }
}
