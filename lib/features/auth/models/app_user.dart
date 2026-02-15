import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool onboardingCompleted;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.onboardingCompleted = false,
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? onboardingCompleted,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  List<Object?> get props =>
      [uid, email, displayName, photoUrl, onboardingCompleted];
}
