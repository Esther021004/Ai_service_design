import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
            icon: const Icon(Icons.delete_forever, color: Color(0xFFFF4444)),
            onPressed: () {
              _showDeleteAccountDialog(context);
            },
          ),
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Profile Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileInputPage(isOnboarding: false)),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Color(0xFFE9DDFB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          'assets/mascot_remove.png',
                          width: 60,
                          height: 60,
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            '프로필',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              fontFamily: 'GangwonEdu',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Progress Graph
              CreditProgressWidget(),
              const SizedBox(height: 20),
              // Previous Courses & Preference
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PreviousCoursesPage(isOnboarding: false)),
                        );
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Color(0xFFF3EFFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            '이전학기\n수강내역',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: 'GangwonEdu',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PreferenceInputPage(isOnboarding: false)),
                        );
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Color(0xFFEAF1F4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            '사용자\n선호도',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: 'GangwonEdu',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Previous Recommended Courses
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PreviousRecommendationsPage()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      '이전 추천 강의 내역',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'GangwonEdu',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Notice
              Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  color: Color(0xFFFCEEFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    '공지사항',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'GangwonEdu',
                    ),
                  ),
                ),
              ),
            ],
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
    // 최대 높이를 100으로 설정하고, 전체 학점 대비 비율로 계산
    int totalCredit = _creditData?['전체 학점'] as int? ?? 130;
    double maxHeight = 100.0;
    return (credit / totalCredit) * maxHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      const Text(
                        '학점 진행률',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'GangwonEdu',
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 전체 학점 표시
                      Text(
                        '전체 학점: ${_creditData!['전체 학점']}학점',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'GangwonEdu',
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 25),
                      // 그래프와 수치 정보를 나란히 배치
                      Row(
                        children: [
                          // 세로 막대 그래프
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: _getBarHeight(_creditData!['전공'] as int),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF2196F3), // 파란색
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '전공',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'GangwonEdu',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: _getBarHeight(_creditData!['교양'] as int),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF44336), // 빨간색
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '교양',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'GangwonEdu',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: _getBarHeight(_creditData!['교직'] as int),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF4CAF50), // 초록색
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '교직',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'GangwonEdu',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // 상세 정보 (우측)
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '전공학점: ${_creditData!['전공']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'GangwonEdu',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '교양학점: ${_creditData!['교양']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'GangwonEdu',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '교직학점: ${_creditData!['교직']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'GangwonEdu',
                                    fontWeight: FontWeight.bold,
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
    );
  }
} 