import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'login_screen.dart';
import 'profile_input_page.dart';
import 'preference_input_page.dart';
import 'previous_courses_page.dart';
import 'course_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '수강 요정',
      theme: ThemeData(
        fontFamily: 'GangwonEdu',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF862CF9)),
      ),
      home: const AuthWrapper(), // 임시로 로그인 화면 강제 표시
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
        '/email-login': (context) => const EmailLoginScreen(),
        '/profile': (context) => const ProfileInputPage(isOnboarding: false),
        '/preferences': (context) => const PreferenceInputPage(isOnboarding: false),
        '/previous-courses': (context) => const PreviousCoursesPage(isOnboarding: false),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('🔥 AuthWrapper - connectionState: ${snapshot.connectionState}');
        print('🔥 AuthWrapper - hasData: ${snapshot.hasData}');
        print('🔥 AuthWrapper - currentUser: ${snapshot.data?.email}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('🔥 AuthWrapper - 로딩 중...');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          print('🔥 AuthWrapper - 로그인된 사용자: ${snapshot.data!.email}');
          // 로그인된 사용자
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.email)
                .get(),
            builder: (context, userSnapshot) {
              print('🔥 AuthWrapper - Firestore 데이터 확인 중...');
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                print('🔥 AuthWrapper - Firestore 데이터 존재: $userData');
                
                // 프로필 정보가 있는지 확인
                final hasProfile = userData != null && userData.containsKey('profile');
                final hasPreferences = userData != null && userData.containsKey('preferences');
                final hasScheduleLinks = userData != null && userData.containsKey('schedule_links');

                print('🔥 AuthWrapper - hasProfile: $hasProfile, hasPreferences: $hasPreferences, hasScheduleLinks: $hasScheduleLinks');

                // 모든 필수 필드가 존재하고 비어있지 않은지 확인
                final profileData = userData?['profile'] as Map<String, dynamic>?;
                final preferencesData = userData?['preferences'] as Map<String, dynamic>?;
                final scheduleLinksData = userData?['schedule_links'] as Map<String, dynamic>?;

                final hasValidProfile = profileData != null && profileData.isNotEmpty;
                final hasValidPreferences = preferencesData != null && preferencesData.isNotEmpty;
                final hasValidScheduleLinks = scheduleLinksData != null && scheduleLinksData.isNotEmpty;

                print('🔥 AuthWrapper - hasValidProfile: $hasValidProfile, hasValidPreferences: $hasValidPreferences, hasValidScheduleLinks: $hasValidScheduleLinks');

                if (hasValidProfile && hasValidPreferences && hasValidScheduleLinks) {
                  print('🔥 AuthWrapper - 기존 사용자: HomePage로 이동');
                  // 모든 정보가 완성된 기존 사용자
                  return const HomePage();
                } else {
                  print('🔥 AuthWrapper - 신규 사용자: OnboardingFlow로 이동');
                  // 프로필이나 선호사항이 없는 사용자
                  return const OnboardingFlow();
                }
              } else {
                print('🔥 AuthWrapper - Firestore 데이터 없음: OnboardingFlow로 이동');
                // Firestore에 사용자 데이터가 없는 경우
                return const OnboardingFlow();
              }
            },
          );
        } else {
          print('🔥 AuthWrapper - 로그인되지 않음: LoginScreen으로 이동');
          // 로그인되지 않은 사용자
          return const LoginScreen();
        }
      },
    );
  }
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;
  
  final List<Widget> _steps = [
    const ProfileInputPage(isOnboarding: true),
    const PreviousCoursesPage(isOnboarding: true),
    const CourseListPage(onNext: null),
    const PreferenceInputPage(isOnboarding: true),
  ];

  void _goToNextStep() {
    // mounted 체크 추가
    if (!mounted) {
      print('🔥 OnboardingFlow가 이미 dispose되었습니다.');
      return;
    }
    
    try {
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        // 모든 단계 완료
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('🔥 OnboardingFlow _goToNextStep 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentStep,
        children: [
          ProfileInputPage(
            isOnboarding: true,
            onNext: _goToNextStep,
          ),
          PreviousCoursesPage(
            isOnboarding: true,
            onNext: _goToNextStep,
          ),
          CourseListPage(
            onNext: _goToNextStep,
          ),
          PreferenceInputPage(
            isOnboarding: true,
            onNext: _goToNextStep,
          ),
        ],
      ),
    );
  }
}