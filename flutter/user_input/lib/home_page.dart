import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_input_page.dart';
import 'preference_input_page.dart';
import 'previous_courses_page.dart';
import 'course_list_page.dart';
import 'course_recommendation_page.dart';
import 'previous_recommendations_page.dart';
import 'schedule_page.dart';
import 'api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;

  final List<Widget> _pages = [
    const CourseRecommendationPage(),
    _MainHomeBody(),
    SchedulePage(userId: FirebaseAuth.instance.currentUser?.email ?? ''),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 계정 삭제 확인 다이얼로그
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning,
                color: Color(0xFFFF4444),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '계정 삭제',
                style: TextStyle(
                  fontFamily: 'GangwonEdu',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF4444),
                ),
              ),
            ],
          ),
          content: const Text(
            '정말로 계정을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 모든 데이터가 영구적으로 삭제됩니다.',
            style: TextStyle(
              fontFamily: 'GangwonEdu',
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'GangwonEdu',
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text(
                '삭제',
                style: TextStyle(
                  fontFamily: 'GangwonEdu',
                  color: Color(0xFFFF4444),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 로그아웃 확인 다이얼로그
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.logout,
                color: Color(0xFF862CF9),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '로그아웃',
                style: TextStyle(
                  fontFamily: 'GangwonEdu',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF862CF9),
                ),
              ),
            ],
          ),
          content: const Text(
            '로그아웃 방식을 선택해주세요.',
            style: TextStyle(
              fontFamily: 'GangwonEdu',
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'GangwonEdu',
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _simpleLogout();
              },
              child: const Text(
                '일반 로그아웃',
                style: TextStyle(
                  fontFamily: 'GangwonEdu',
                  color: Color(0xFF862CF9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeLogout();
              },
              child: const Text(
                '완전 로그아웃',
                style: TextStyle(
                  fontFamily: 'GangwonEdu',
                  color: Color(0xFFFF4444),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 일반 로그아웃 (데이터 유지)
  Future<void> _simpleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('🔥 일반 로그아웃 중 오류: $e');
    }
  }

  // 완전 로그아웃 (모든 데이터 삭제)
  Future<void> _completeLogout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email != null) {
        print('🔥 완전 로그아웃 시작: ${user!.email}');

        // Firebase Firestore에서 사용자 데이터 삭제
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .delete();

        print('🔥 Firestore 데이터 삭제 완료');
      }

      // Firebase Auth에서 로그아웃
      await FirebaseAuth.instance.signOut();

      print('🔥 Firebase Auth 로그아웃 완료');

      // 성공 메시지 표시
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '완전 로그아웃 완료',
                    style: TextStyle(
                      fontFamily: 'GangwonEdu',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              content: const Text(
                '모든 데이터가 삭제되었습니다.\n\n다음에 앱을 실행할 때는 새로운 계정으로 로그인해야 합니다.',
                style: TextStyle(
                  fontFamily: 'GangwonEdu',
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 로그인 페이지로 이동
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontFamily: 'GangwonEdu',
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }

    } catch (e) {
      print('🔥 완전 로그아웃 중 오류: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 계정 삭제 함수
  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없습니다.');
        return;
      }

      print('🔥 계정 삭제 시작: ${user!.email}');

      // Firebase Firestore에서 사용자 데이터 삭제
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .delete();

      print('🔥 Firestore 데이터 삭제 완료');

      // Google 계정 연결 해제 시도
      try {
        for (var provider in user.providerData) {
          if (provider.providerId == 'google.com') {
            print('🔥 Google 계정 연결 해제 시도');
            // Google 계정 연결 해제는 사용자가 직접 해야 함
          }
        }
      } catch (e) {
        print('🔥 Google 계정 연결 해제 실패: $e');
      }

      // Firebase Auth에서 계정 삭제
      await user.delete();

      print('🔥 Firebase Auth 계정 삭제 완료');

      // 성공 메시지 표시
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '계정 삭제 완료',
                    style: TextStyle(
                      fontFamily: 'GangwonEdu',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              content: const Text(
                '계정이 성공적으로 삭제되었습니다.\n\n만약 Google 계정 선택 화면이 계속 나타난다면, 기기 설정에서 해당 Google 계정을 제거해주세요.',
                style: TextStyle(
                  fontFamily: 'GangwonEdu',
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 로그인 페이지로 이동
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontFamily: 'GangwonEdu',
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }

    } catch (e) {
      print('🔥 계정 삭제 중 오류: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계정 삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF862CF9)),
            onPressed: () async {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '',
          ),
        ],
        selectedItemColor: Color(0xFF862CF9),
        unselectedItemColor: Color(0xFF999999),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}

class _MainHomeBody extends StatelessWidget {
  const _MainHomeBody({Key? key}) : super(key: key);

  Future<void> _launchURL(BuildContext context) async {
    const url = 'https://portal.sungshin.ac.kr/portal/ssu/menu/notice/ssuboard02?boardId=ssuboard02';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('링크를 열 수 없습니다.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Profile Section
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileInputPage(isOnboarding: false)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                                         decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.1),
                           blurRadius: 15,
                           offset: const Offset(0, 8),
                         ),
                       ],
                     ),
                    child: Row(
                    children: [
                      // Profile Image
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/mascot.png',
                            width: 60,
                            height: 60,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                                             // Profile Info
                       Expanded(
                         child: StreamBuilder<DocumentSnapshot>(
                           stream: FirebaseFirestore.instance
                               .collection('users')
                               .doc(FirebaseAuth.instance.currentUser?.email)
                               .snapshots(),
                           builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                                                     Text(
                                     '로딩 중...',
                                     style: TextStyle(
                                       fontSize: 24,
                                       fontWeight: FontWeight.bold,
                                       fontFamily: 'Pretendard',
                                       color: Colors.black,
                                     ),
                                   ),
                                   SizedBox(height: 4),
                                   Text(
                                     '정보를 불러오는 중입니다',
                                     style: TextStyle(
                                       fontSize: 16,
                                       fontWeight: FontWeight.w500,
                                       fontFamily: 'Pretendard',
                                       color: Colors.black54,
                                     ),
                                   ),
                                ],
                              );
                            }

                            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                              return const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                                                     Text(
                                     '사용자',
                                     style: TextStyle(
                                       fontSize: 24,
                                       fontWeight: FontWeight.bold,
                                       fontFamily: 'Pretendard',
                                       color: Colors.black,
                                     ),
                                   ),
                                   SizedBox(height: 4),
                                   Text(
                                     '프로필 정보를 설정해주세요',
                                     style: TextStyle(
                                       fontSize: 16,
                                       fontWeight: FontWeight.w500,
                                       fontFamily: 'Pretendard',
                                       color: Colors.black54,
                                     ),
                                   ),
                                ],
                              );
                            }

                                                         final userData = snapshot.data!.data() as Map<String, dynamic>?;
                             
                             // 디버그: 실제 데이터 확인
                             print('🔥 Firebase 데이터: $userData');
                             
                             // profile 객체에서 데이터 가져오기
                             final profileData = userData?['profile'] as Map<String, dynamic>?;
                             
                             final name = profileData?['이름'] as String? ?? '사용자';
                             final major = profileData?['전공'] as String? ?? '학과 미설정';
                             
                             // grade가 숫자인지 문자열인지 확인
                             dynamic gradeValue = profileData?['학년'];
                             String gradeText;
                             if (gradeValue is int) {
                               gradeText = '${gradeValue}학년';
                             } else if (gradeValue is String) {
                               gradeText = gradeValue;
                             } else {
                               gradeText = '학년 미설정';
                             }
                             
                             print('🔥 파싱된 데이터 - 이름: $name, 전공: $major, 학년: $gradeText');

                             return Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                                                   Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Pretendard',
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '학과 : $major / 학년 : $gradeText',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Pretendard',
                                      color: Colors.black54,
                                    ),
                                  ),
                               ],
                             );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 24),
                
                // Credit Progress Section
                CreditProgressWidget(),
                const SizedBox(height: 24),
                
                // Content Cards Section
                Row(
                  children: [
                    // Left Card - User Preferences
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PreferenceInputPage(isOnboarding: false)),
                          );
                        },
                        child: Container(
                          height: 260,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Transform.scale(
                                  scale: 1.2,
                                  child: Image.asset(
                                    'assets/사용자 선호도.png',
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 15,
                                child: Text(
                                  '사용자 선호도',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: '강원교육튼튼',
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right Cards Column
                    Expanded(
                      child: Column(
                        children: [
                          // Top Right Card - Previous Courses
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PreviousCoursesPage(isOnboarding: false)),
                              );
                            },
                            child: Container(
                              height: 170,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Transform.scale(
                                      scale: 1.1,
                                      child: Image.asset(
                                        'assets/이전학기수강내역.png',
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Text(
                                      '이전학기\n수강내역',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: '강원교육튼튼',
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                            color: Colors.black.withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Bottom Right Card - Previous Recommendations
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PreviousRecommendationsPage()),
                              );
                            },
                            child: Container(
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Transform.scale(
                                      scale: 1.1,
                                      child: Image.asset(
                                        'assets/이전추천내역.png',
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Text(
                                      '이전 추천 내역',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: '강원교육튼튼',
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                            color: Colors.black.withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Course Registration Banner
                GestureDetector(
                  onTap: () => _launchURL(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFFE3D9F8),
                          Color(0xFFFFFFFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '2025 - 1학기 수강신청',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Pretendard',
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '관심강좌 신청: 2025. 2. 3.(월) 10:00 ~ 2. 10.(월) 17:00',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Pretendard',
                                  color: Color(0xFF767676),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '수강신청: 2025. 2. 17.(월) 10:00 ~ 2. 19.(수) 17:00',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Pretendard',
                                  color: Color(0xFF767676),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF1A1A1A),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreditProgressWidget extends StatefulWidget {
  const CreditProgressWidget({Key? key}) : super(key: key);

  @override
  State<CreditProgressWidget> createState() => _CreditProgressWidgetState();
}

class _CreditProgressWidgetState extends State<CreditProgressWidget> {
  Map<String, dynamic>? _creditData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCreditData();
  }

  Future<void> _loadCreditData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final creditData = await ApiService.calculateCreditRatio();
      if (mounted) {
        setState(() {
          _creditData = creditData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🔥 학점 데이터 로딩 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 막대 높이 계산 함수
  double _getBarHeight(int credit) {
    // 최대 높이를 50으로 설정하고, 전체 학점 대비 비율로 계산
    int totalCredit = _creditData?['전체 학점'] as int? ?? 130;
    double maxHeight = 50.0;
    return (credit / totalCredit) * maxHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF7FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF862CF9)),
              ),
            )
          : _creditData == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF666666),
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '학점 데이터를 불러오는 중...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'GangwonEdu',
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '학점 진행률',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Pretendard',
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '전체 학점 : ${_creditData!['전체 학점']}학점',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard',
                            color: Color(0xFF767676),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Bar Chart
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Container(
                                          height: _getBarHeight(_creditData!['전공'] as int),
                                          width: 30,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF862CF9),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          '전공',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Pretendard',
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Container(
                                          height: _getBarHeight(_creditData!['교양'] as int),
                                          width: 25,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFAD6BFC),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          '교양',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Pretendard',
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Container(
                                          height: _getBarHeight(_creditData!['교직'] as int),
                                          width: 20,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4F86F2),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          '교직',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Pretendard',
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Credit Details
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '전공 학점 : ${_creditData!['전공']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Pretendard',
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '교양 학점 : ${_creditData!['교양']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Pretendard',
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '교직 학점 : ${_creditData!['교직']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Pretendard',
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
} 