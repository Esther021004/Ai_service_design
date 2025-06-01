import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/start_page.dart';
import 'pages/email_page.dart';
import 'pages/user_basic_info_page.dart';
import 'pages/user_preference_page.dart';
import 'pages/recommendation_history_page.dart';
import 'pages/result_page.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // 웹 플랫폼용 Firebase 초기화
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCpeRPzd5DRt90DTpZq1N-_EOsF2QnbL90",
        authDomain: "sugangyojeong-68ab0.firebaseapp.com",
        projectId: "sugangyojeong-68ab0",
        storageBucket: "sugangyojeong-68ab0.firebasestorage.app",
        messagingSenderId: "791316499376",
        appId: "1:791316499376:web:489e3e61a6791f04c2e475"
      ),
    );
  } else {
    // 모바일 플랫폼용 Firebase 초기화
  await Firebase.initializeApp();
  }
  
  runApp(const SuGangFairyApp());
}

class SuGangFairyApp extends StatelessWidget {
  const SuGangFairyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '수강요정',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartPage(),
        '/email': (context) => const EmailPage(),
        '/basic_info': (context) => const UserBasicInfoPage(),
        '/preference': (context) => const UserPreferencePage(),
        '/preferences': (context) => const UserPreferencePage(),
        '/result': (context) => ResultPage(userId: "test_user_id"),
        // '/result': (context) => const ResultPage(), // 추후 구현
      },
    );
  }
}