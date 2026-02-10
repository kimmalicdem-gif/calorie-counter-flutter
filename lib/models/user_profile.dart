class UserProfile {
  final String nickname;
  final double weight; // in kg
  final double? targetWeight; // in kg

  UserProfile({
    required this.nickname,
    required this.weight,
    this.targetWeight,
  });

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'weight': weight,
      if (targetWeight != null) 'targetWeight': targetWeight,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      nickname: json['nickname'] as String,
      weight: (json['weight'] as num).toDouble(),
      targetWeight: json['targetWeight'] == null ? null : (json['targetWeight'] as num).toDouble(),
    );
  }
}
