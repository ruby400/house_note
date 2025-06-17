// lib/data/repositories/user_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:house_note/data/models/user_model.dart';


class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  // 이 부분이 누락되었을 가능성이 있습니다!
  CollectionReference<UserModel> get _usersCollection =>
      _firestore.collection('users').withConverter<UserModel>(
            fromFirestore: (snapshot, _) =>
                UserModel.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (user, _) => user.toMap(),
          );

  Future<void> createUserProfile(fb_auth.User firebaseUser,
      {String? displayName}) async {
    // 이미 존재하는지 확인
    final doc = await _usersCollection.doc(firebaseUser.uid).get();
    if (doc.exists) {
      return; // 이미 존재하면 생성하지 않음
    }
    
    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: displayName ?? firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      onboardingCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _usersCollection.doc(firebaseUser.uid).set(userModel);
  }

  Stream<UserModel?> getUserProfileStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      return snapshot.data();
    });
  }

  Future<void> updateUserProfile(String uid,
      {String? displayName, String? photoURL}) async {
    final Map<String, dynamic> dataToUpdate = {};
    if (displayName != null) dataToUpdate['displayName'] = displayName;
    if (photoURL != null) dataToUpdate['photoURL'] = photoURL;

    if (dataToUpdate.isNotEmpty) {
      await _usersCollection.doc(uid).update(dataToUpdate);
    }
  }

  Future<void> updateOnboardingStatus(String uid, bool completed) async {
    await _usersCollection.doc(uid).update({'onboardingCompleted': completed});
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }
}
