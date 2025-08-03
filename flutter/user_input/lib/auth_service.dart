import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.email).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'lastSignIn': DateTime.now(),
        }, SetOptions(merge: true));
      }
      return userCredential;
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }

  // 이메일/비밀번호 회원가입
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Firestore에 사용자 정보 저장
      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.email).set({
          'uid': user.uid,
          'email': user.email,
          'createdAt': DateTime.now(),
        }, SetOptions(merge: true));
      }
      return userCredential;
    } catch (e) {
      print('Email sign-up error: $e');
      return null;
    }
  }

  // 이메일/비밀번호 로그인
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print('Email sign-in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }
} 