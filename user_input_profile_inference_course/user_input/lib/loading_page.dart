import 'package:flutter/material.dart';
import 'dart:async';
import 'course_list_result_page.dart';
import 'api_service.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation.addListener(() {
      setState(() {
        _progress = _progressAnimation.value;
      });
    });

    _progressController.forward();

    // API 호출 및 결과 처리
    _getRecommendations();
  }

  Future<void> _getRecommendations() async {
    try {
      // 5초 후 API 호출
      await Future.delayed(const Duration(seconds: 5));
      
      if (mounted) {
        // 두 API를 동시에 호출
        final majorRecommendations = await ApiService.getCourseRecommendations();
        final liberalRecommendations = await ApiService.getLiberalCourseRecommendations();
        
        // 결과를 합치기
        Map<String, dynamic> combinedRecommendations = {};
        
        if (majorRecommendations != null) {
          combinedRecommendations.addAll(majorRecommendations);
        }
        
        if (liberalRecommendations != null) {
          // 교양 강의 결과를 기존 결과에 추가
          if (combinedRecommendations['liberal_courses'] == null) {
            combinedRecommendations['liberal_courses'] = [];
          }
          
          // 교양 API에서 받은 결과를 기존 교양 강의 목록에 추가
          if (liberalRecommendations['liberal_courses'] != null) {
            List<dynamic> existingLiberal = combinedRecommendations['liberal_courses'] as List<dynamic>;
            List<dynamic> newLiberal = liberalRecommendations['liberal_courses'] as List<dynamic>;
            existingLiberal.addAll(newLiberal);
            combinedRecommendations['liberal_courses'] = existingLiberal;
          }
        }
        
        if (mounted) {
          // API 호출이 실패해도 결과 페이지로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CourseListResultPage(
                recommendations: combinedRecommendations.isNotEmpty ? combinedRecommendations : null,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('🔥 추천 API 호출 실패: $e');
      print('🔥 서버 오류로 인해 기본 데이터로 진행합니다.');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CourseListResultPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3D Character and Environment
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Main Character
                    Center(
                      child: Image.asset(
                        'assets/loading_character_remove.png',
                        width: 350,
                        height: 350,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress Bar
              Container(
                width: 280,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF862CF9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Loading Text
              const Text(
                '강의 리스트 생성중...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '나만의 강의 리스트를 생성중입니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Pretendard',
                  color: Color(0xFF767676),
                ),
              ),
              
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
} 