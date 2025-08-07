import 'package:flutter/material.dart';
import 'api_service.dart';
import 'course_list_page.dart';

class ScheduleLoadingPage extends StatefulWidget {
  final List<String> urls;
  final List<String> semesters;
  final VoidCallback? onNext;
  
  const ScheduleLoadingPage({
    Key? key,
    required this.urls,
    required this.semesters,
    this.onNext,
  }) : super(key: key);

  @override
  State<ScheduleLoadingPage> createState() => _ScheduleLoadingPageState();
}

class _ScheduleLoadingPageState extends State<ScheduleLoadingPage> {
  int _currentStep = 0;
  int _totalSteps = 0;
  String _currentUrl = '';
  String _currentSemester = '';
  bool _isProcessing = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _totalSteps = widget.urls.length;
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    // 이미 처리 중이면 중복 실행 방지
    if (_isProcessing) {
      print('🔥 이미 처리 중입니다. 중복 실행 방지.');
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });

    print('🔥 ScheduleLoadingPage 처리 시작 - 총 ${widget.urls.length}개 URL');
    
    // 각 URL에 대해 순차적으로 처리
    for (int i = 0; i < widget.urls.length; i++) {
      setState(() {
        _currentStep = i + 1;
        _currentUrl = widget.urls[i];
        _currentSemester = widget.semesters[i];
      });

      print('🔥 API 호출 시작: ${widget.urls[i]} (${i + 1}/${widget.urls.length})');
      
      try {
        // 1. 먼저 crawling-server 깨우기 (타임아웃 설정)
        print('🔥 Crawling server 깨우기 시도...');
        bool crawlingServerWoken = await ApiService.wakeUpCrawlingServer().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('🔥 Crawling server 깨우기 타임아웃');
            return false;
          },
        );
        
        if (crawlingServerWoken) {
          print('🔥 Crawling server 깨우기 성공!');
        } else {
          print('🔥 Crawling server 깨우기 실패, 그래도 진행...');
        }
        
        // 2. 더 긴 대기 시간 (Cold Start 고려)
        print('🔥 서버 준비 대기 중... (5초)');
        await Future.delayed(const Duration(seconds: 5));
        
        // 3. 실제 API 호출 - 완료될 때까지 대기 (타임아웃 포함)
        String semester = _getSemesterForUrl(i);
        print('🔥 Previous-courses API 호출 시작...');
        await ApiService.saveCourses(widget.urls[i], semester).timeout(
          const Duration(seconds: 60), // 타임아웃 시간 증가
          onTimeout: () {
            print('🔥 API 호출 타임아웃: ${widget.urls[i]}');
            return null;
          },
        );
        
        print('🔥 URL 저장 완료: ${widget.urls[i]}');
      } catch (e) {
        print('🔥 URL 저장 중 오류: ${widget.urls[i]} - $e');
      }

      print('🔥 API 호출 완료: ${widget.urls[i]} (${i + 1}/${widget.urls.length})');
      
      // 각 URL 처리 후 잠시 대기
      await Future.delayed(const Duration(seconds: 1));
    }

    // 모든 처리가 완료되면 완료 상태로 변경
    print('🔥 모든 API 호출 완료!');
    setState(() {
      _isCompleted = true;
    });

    // 2초 후 다음 페이지로 이동
    print('🔥 2초 후 CourseListPage로 이동...');
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      print('🔥 CourseListPage로 이동 시작');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CourseListPage(onNext: widget.onNext),
        ),
      );
    }
  }

  String _getSemesterForUrl(int index) {
    // 인덱스에 해당하는 학기를 API 형식으로 변환
    if (index < widget.semesters.length) {
      final match = RegExp(r'(\d)학년 (\d)학기').firstMatch(widget.semesters[index]);
      if (match != null) {
        final year = match.group(1);
        final semester = match.group(2);
        return '$year-$semester'; // "1-1", "1-2" 형식으로 통일
      }
    }
    return '1-1'; // 기본값
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로딩 애니메이션
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF862CF9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Center(
                  child: _isCompleted
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF862CF9),
                          size: 60,
                        )
                      : const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF862CF9)),
                          strokeWidth: 3,
                        ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 제목
              Text(
                _isCompleted ? '저장 완료!' : '강의 정보 저장 중',
                style: const TextStyle(
                  fontFamily: 'GangwonEdu',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 설명
              Text(
                _isCompleted 
                    ? '모든 강의 정보가 성공적으로 저장되었습니다.'
                    : '에브리타임 링크에서 강의 정보를 가져와서\nFirebase에 저장하고 있습니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'GangwonEdu',
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 진행 상황
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  children: [
                    // 진행률 표시
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isCompleted ? '처리 완료' : '진행 상황',
                          style: const TextStyle(
                            fontFamily: 'GangwonEdu',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          '$_currentStep / $_totalSteps',
                          style: const TextStyle(
                            fontFamily: 'GangwonEdu',
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 진행률 바
                    LinearProgressIndicator(
                      value: _totalSteps > 0 ? _currentStep / _totalSteps : 0,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF862CF9)),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 현재 처리 중인 정보
                    if (_isProcessing && _currentUrl.isNotEmpty)
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isCompleted ? Icons.check_circle : Icons.school,
                                color: _isCompleted ? Colors.green : const Color(0xFF862CF9),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isCompleted 
                                      ? '$_currentSemester 저장 완료'
                                      : '$_currentSemester 처리 중...',
                                  style: TextStyle(
                                    fontFamily: 'GangwonEdu',
                                    fontSize: 14,
                                    color: _isCompleted ? Colors.green : const Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.link,
                                  color: Color(0xFF666666),
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _currentUrl,
                                    style: const TextStyle(
                                      fontFamily: 'GangwonEdu',
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
              
              const SizedBox(height: 40),
              
              // 안내 메시지
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCompleted 
                      ? const Color(0xFFE8F5E8)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isCompleted 
                        ? Colors.green
                        : const Color(0xFFFF9800),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isCompleted ? Icons.check_circle : Icons.info_outline,
                      color: _isCompleted ? Colors.green : const Color(0xFFFF9800),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isCompleted
                            ? '이제 이전 수강 내역 페이지로 이동합니다.'
                            : '잠시만 기다려주세요. 네트워크 상태에 따라\n처리 시간이 달라질 수 있습니다.',
                        style: TextStyle(
                          fontFamily: 'GangwonEdu',
                          fontSize: 14,
                          color: _isCompleted 
                              ? Colors.green
                              : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 