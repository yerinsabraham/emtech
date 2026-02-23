class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'student', 'lecturer', 'admin'
  final int emcBalance;
  final List<String> enrolledCourses;
  final String? photoUrl;
  final String? session; // Summer, Winter, Spring, Harmatan
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Phase 3: Tokenomics fields
  final double totalEMCEarned; // Lifetime EMC earned
  final double unredeemedEMC; // EMC from grades not yet redeemed
  final double stakedEMC; // Currently staked EMC
  final double availableEMC; // Available for spending (balance - staked)
  final bool kycVerified; // KYC verification status
  final int activeLoanCount; // Number of active loans
  final String? phone; // Phone number
  final String? bio; // Bio/about text

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.role = 'student', // Default role
    this.emcBalance = 0,
    this.enrolledCourses = const [],
    this.photoUrl,
    this.session,
    required this.createdAt,
    required this.updatedAt,
    this.totalEMCEarned = 0.0,
    this.unredeemedEMC = 0.0,
    this.stakedEMC = 0.0,
    this.availableEMC = 0.0,
    this.kycVerified = false,
    this.activeLoanCount = 0,
    this.phone,
    this.bio,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
      totalEMCEarned: (map['totalEMCEarned'] ?? 0).toDouble(),
      unredeemedEMC: (map['unredeemedEMC'] ?? 0).toDouble(),
      stakedEMC: (map['stakedEMC'] ?? 0).toDouble(),
      availableEMC: (map['availableEMC'] ?? map['emcBalance'] ?? 0).toDouble(),
      kycVerified: map['kycVerified'] ?? false,
      activeLoanCount: map['activeLoanCount'] ?? 0,
      emcBalance: map['emcBalance'] ?? 0,
      enrolledCourses: List<String>.from(map['enrolledCourses'] ?? []),
      photoUrl: map['photoUrl'],
      session: map['session'],
      phone: map['phone'],
      bio: map['bio'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'emcBalance': emcBalance,
      'enrolledCourses': enrolledCourses,
      'photoUrl': photoUrl,
      'session': session,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'totalEMCEarned': totalEMCEarned,
      'unredeemedEMC': unredeemedEMC,
      'stakedEMC': stakedEMC,
      'availableEMC': availableEMC,
      'kycVerified': kycVerified,
      'activeLoanCount': activeLoanCount,
      'phone': phone,
      'bio': bio,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    int? emcBalance,
    List<String>? enrolledCourses,
    String? photoUrl,
    String? session,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalEMCEarned,
    double? unredeemedEMC,
    double? stakedEMC,
    double? availableEMC,
    bool? kycVerified,
    int? activeLoanCount,
    String? phone,
    String? bio,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      emcBalance: emcBalance ?? this.emcBalance,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      photoUrl: photoUrl ?? this.photoUrl,
      session: session ?? this.session,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalEMCEarned: totalEMCEarned ?? this.totalEMCEarned,
      unredeemedEMC: unredeemedEMC ?? this.unredeemedEMC,
      stakedEMC: stakedEMC ?? this.stakedEMC,
      availableEMC: availableEMC ?? this.availableEMC,
      kycVerified: kycVerified ?? this.kycVerified,
      activeLoanCount: activeLoanCount ?? this.activeLoanCount,
    );
  }
}
