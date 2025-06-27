import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_note/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:house_note/providers/user_providers.dart';
import 'package:house_note/services/firebase_auth_service.dart';

// Firebase Auth 인스턴스 Provider
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// GoogleSignIn 인스턴스 Provider
final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

// FirebaseAuthService Provider
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
  );
});

// 인증 상태 변경 스트림 Provider
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthServiceProvider).authStateChanges;
});

// AuthViewModel Provider
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(
    ref.watch(firebaseAuthServiceProvider),
    ref.watch(userRepositoryProvider),
    ref, // Ref 전달
  );
});
