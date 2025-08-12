import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_screen.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  int currentPage = 0;
  final int totalPages = 6;

  // 튜토리얼 페이지 데이터
  final List<Map<String, dynamic>> tutorialPages = [
    {
      'title': '나만의 수강 정보, 한눈에!',
      'description': '프로필, 학점 진행률, 사용자 선호도, 이전 학기 수강 내역,\n추천 내역, 수강 신청 공지를 홈에서 모두 확인하세요.',
      'image': 'assets/tutorial_page/tutorial_homepage.png',
    },
    {
      'title': '나를 나타내는 프로필 설정!',
      'description': '단과대학, 학과, 세부전공, 학년 정보를 입력해 나에게\n꼭 맞는 강의 추천을 받아보세요.',
      'image': 'assets/tutorial_page/프로필페이지_튜토리얼.png',
    },
    {
      'title': '내 강의 스타일 설정!',
      'description': '시험 횟수, 과제량, 조모임 여부, 출결 방식, 강의 유형 등의\n선호도를 선택해 원하는 강의 조건을 설정하세요.',
      'image': 'assets/tutorial_page/선호도페이지_튜토리얼.png',
    },
    {
      'title': '이전 학기 수강 내역 관리!',
      'description': '학기별 시간표 링크를 입력하고 직접 강의 정보를 수정해,\n이전 학기 수강 내역을 한곳에 정리하세요.',
      'image': 'assets/tutorial_page/이전수강내역페이지_튜토리얼.png',
    },
    {
      'title': '추천 강의 한눈에!',
      'description': '전공·교양별 추천 강의와 추천 이유를 확인하고, 마음에\n드는 강의는 하트를 눌러 관심 목록에 저장하세요.',
      'image': 'assets/tutorial_page/추천페이지_튜토리얼.png',
    },
    {
      'title': '이전 추천 다시 보기!',
      'description': '날짜별로 받은 추천 강의를 확인하고, 마음에 드는 강의는\n하트를 눌러 저장하세요.',
      'image': 'assets/tutorial_page/이전추천내역페이지_튜토리얼.png',
    },
  ];

  void nextPage() {
    if (currentPage < tutorialPages.length - 1) {
      setState(() {
        currentPage++;
      });
    } else {
      // 마지막 페이지에서 다음 버튼을 누르면 로그인 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPageData = tutorialPages[currentPage];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F9),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 진행률 바
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (currentPage + 1) / totalPages,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B46C1), // 보라색
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // X 버튼
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    },
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF666666),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // 메인 콘텐츠
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                                         // 제목
                     Text(
                       currentPageData['title'],
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontFamily: 'Pretendard',
                         fontWeight: FontWeight.w700,
                         fontSize: 24,
                         color: const Color(0xFF000000),
                         height: 1.3,
                       ),
                     ),
                     
                     const SizedBox(height: 20),
                     
                     // 설명 텍스트
                     Text(
                       currentPageData['description'],
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontFamily: 'Pretendard',
                         fontWeight: FontWeight.w500,
                         fontSize: 13,
                         color: const Color(0xFF444444),
                         height: 1.5,
                       ),
                     ),
                    
                    const SizedBox(height: 60),
                    
                    // 이미지
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          currentPageData['image'],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 하단 버튼 영역
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 건너뛰기 버튼
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      '건너뛰기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                  
                  // 이전/다음 버튼
                  Row(
                    children: [
                      // 이전 버튼 (첫 페이지가 아닐 때만 표시)
                      if (currentPage > 0)
                        TextButton(
                          onPressed: previousPage,
                          child: Text(
                            '이전',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ),
                      
                      const SizedBox(width: 16),
                      
                      // 다음 버튼
                      ElevatedButton(
                        onPressed: nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          currentPage == tutorialPages.length - 1 ? '시작하기' : '다음',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 