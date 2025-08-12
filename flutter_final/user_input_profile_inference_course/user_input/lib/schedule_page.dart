import 'package:flutter/material.dart';
import 'models/course.dart';
import 'services/firebase_service.dart';
import 'services/fastapi_service.dart';
import 'widgets/favorites_list.dart';

class SchedulePage extends StatefulWidget {
  final String userId;
  const SchedulePage({Key? key, required this.userId}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> scheduleData = [];
  bool isLoading = true;

  // 시간표 구성 요소
  List week = ['월', '화', '수', '목', '금'];
  var kColumnLength = 22;
  double kFirstColumnHeight = 20;
  double kBoxSize = 52;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    print('🔥 [SchedulePage] 시간표 로딩 시작 - userId: ${widget.userId}');
    try {
      final data = await FirebaseService.getTimetable(widget.userId);
      print('🔥 [SchedulePage] 시간표 데이터 로드 완료 - ${data.length}개 강의');
      
      // 디버깅: 각 강의 정보 출력
      for (int i = 0; i < data.length; i++) {
        final course = data[i];
        print('🔥 [SchedulePage] 강의 ${i + 1}:');
        print('  - 과목명: ${course['과목명']}');
        print('  - 교수명: ${course['교수명']}');
        print('  - 캠퍼스: ${course['캠퍼스']}');
        print('  - 시간표: ${course['시간표']}');
      }
      
      setState(() {
        scheduleData = data;
        isLoading = false;
      });
      print('🔥 [SchedulePage] UI 상태 업데이트 완료');
    } catch (e) {
      print('🔥 [SchedulePage] 시간표 로딩 중 오류 발생: $e');
      print('🔥 [SchedulePage] 오류 타입: ${e.runtimeType}');
      setState(() {
        isLoading = false;
      });
      print('🔥 [SchedulePage] 로딩 상태 해제 완료');
    }
  }

  Map<String, dynamic>? _getCourseAtTime(int dayIndex, int hour) {
    final day = week[dayIndex];
    for (var course in scheduleData) {
      final timetable = course['시간표'];
      if (timetable is Map<String, dynamic> && timetable.containsKey(day)) {
        final hours = timetable[day];
        if (hours is List && hours.contains(hour)) {
          return course;
        }
      }
    }
    return null;
  }

  void _showScheduleDialog(int dayIndex, int hour, Map<String, dynamic>? course) {
    if (course == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                course['과목명'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(course);
              },
              tooltip: '강의 삭제',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '교수명: ${course['교수명'] ?? ''}',
              style: const TextStyle(
                fontFamily: 'Pretendard',
              ),
            ),
            Text(
              '캠퍼스: ${course['캠퍼스'] ?? ''}',
              style: const TextStyle(
                fontFamily: 'Pretendard',
              ),
            ),
            Text(
              '시간표: ${course['시간표'] ?? ''}',
              style: const TextStyle(
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text(
              '닫기',
              style: TextStyle(
                fontFamily: 'Pretendard',
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          '강의 삭제',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '${course['과목명']} 강의를 시간표에서 삭제하시겠습니까?',
          style: const TextStyle(
            fontFamily: 'Pretendard',
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: 'Pretendard',
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text(
              '삭제', 
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'Pretendard',
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCourseFromSchedule(course);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourseFromSchedule(Map<String, dynamic> course) async {
    try {
      print('🔥 [SchedulePage] 강의 삭제 시작: ${course['과목명']}');
      
      // Firebase에서 해당 강의 삭제
      await FirebaseService.deleteCourseFromSchedule(widget.userId, course);
      
      // 시간표 다시 로드
      await _loadSchedule();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${course['과목명']} 강의가 삭제되었습니다.'),
            backgroundColor: const Color(0xFF862CF9),
          ),
        );
      }
      
      print('🔥 [SchedulePage] 강의 삭제 완료');
    } catch (e) {
      print('🔥 [SchedulePage] 강의 삭제 중 오류 발생: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('강의 삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 시간표 그리드 위젯 (수정된 버전)
  Widget _buildTimeTableGrid() {
    return Column(
      children: [
        // 헤더 행 (요일)
        Row(
          children: [
            // 시간 열 헤더 (빈칸)
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFFF),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            // 요일 헤더들
            for (int i = 0; i < week.length; i++) ...[
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFFF),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      week[i],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
              ),
              // 세로 구분선(요일별) 추가
              if (i < week.length - 1)
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
            ],
          ],
        ),
        // 시간표 셀
        for (int hour = 1; hour <= 18; hour++)
          Row(
            children: [
              // 시간 열
              Container(
                width: 60,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Text(
                    '$hour시',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
              // 요일별 셀 + 세로 구분선
              for (int dayIndex = 0; dayIndex < week.length; dayIndex++) ...[
                                 Expanded(
                   child: GestureDetector(
                     onTap: () {
                       final course = _getCourseAtTime(dayIndex, hour);
                       if (course != null) {
                         _showScheduleDialog(dayIndex, hour, course);
                       }
                     },
                     child: Container(
                       height: 48,
                       decoration: BoxDecoration(
                         border: Border.all(color: Colors.grey.shade300),
                         color: _getCourseAtTime(dayIndex, hour) != null 
                             ? const Color(0xFFF3EFFF) 
                             : Colors.transparent,
                         borderRadius: BorderRadius.zero,
                       ),
                       child: Center(
                         child: _getCourseAtTime(dayIndex, hour) != null
                             ? Text(
                                 _getCourseAtTime(dayIndex, hour)!['과목명'] ?? '',
                                 style: const TextStyle(
                                   fontSize: 12,
                                   fontWeight: FontWeight.bold,
                                 ),
                                 textAlign: TextAlign.center,
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               )
                             : const SizedBox.shrink(),
                       ),
                     ),
                   ),
                 ),
                // 세로 구분선(요일별) 추가
                if (dayIndex < week.length - 1)
                  Container(
                    width: 1,
                    height: 48,
                    color: Colors.grey.shade300,
                  ),
              ],
            ],
          ),
      ],
    );
  }

  // 시간표 초기화 메서드
  Future<void> _resetSchedule() async {
    print('🔥 [SchedulePage] 시간표 초기화 시작 - userId: ${widget.userId}');
    setState(() {
      isLoading = true;
    });
    print('🔥 [SchedulePage] 로딩 상태 활성화');
    
    try {
      print('🔥 [SchedulePage] FastAPI 서비스 호출 중...');
      final response = await FastAPIService.resetSchedule(widget.userId);
      print('🔥 [SchedulePage] 초기화 응답: $response');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['detail'] ?? '시간표가 초기화되었습니다.')),
        );
        print('🔥 [SchedulePage] 스낵바 표시 완료');
      }
      
      print('🔥 [SchedulePage] 시간표 다시 로드 중...');
      await _loadSchedule();
      print('🔥 [SchedulePage] 시간표 초기화 완료');
    } catch (e) {
      print('🔥 [SchedulePage] 시간표 초기화 중 오류 발생: $e');
      print('🔥 [SchedulePage] 오류 타입: ${e.runtimeType}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('초기화 중 오류 발생: $e')),
        );
        print('🔥 [SchedulePage] 오류 스낵바 표시 완료');
      }
      setState(() {
        isLoading = false;
      });
      print('🔥 [SchedulePage] 로딩 상태 해제 완료');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 상단 보라색 Row
                Container(
                  width: double.infinity,
                  height: 60,
                  color: const Color(0xFFB39DDB),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      const Text(
                        '시간표',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          fontFamily: 'Pretendard',
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black),
                        tooltip: '시간표 초기화',
                        onPressed: _resetSchedule,
                      ),
                    ],
                  ),
                ),
                // 시간표 그리드 (Flexible + SingleChildScrollView)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildTimeTableGrid(),
                      ),
                    ),
                  ),
                ),
                // 하단 찜목록 카드 (고정 높이)
                Container(
                  height: 200,
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 카드 헤더
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3EFFF),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite, color: Colors.purple),
                            const SizedBox(width: 8),
                            const Text(
                              '찜해둔 강의',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            const Spacer(),
                                                         FutureBuilder<List<Course>>(
                               future: FirebaseService.getFavorites(widget.userId),
                               builder: (context, snapshot) {
                                 if (snapshot.connectionState == ConnectionState.waiting) {
                                   return const Text(
                                     '로딩중...',
                                     style: TextStyle(
                                       color: Colors.grey,
                                       fontSize: 14,
                                       fontFamily: 'Pretendard',
                                     ),
                                   );
                                 }
                                 
                                 final count = snapshot.data?.length ?? 0;
                                                                    return Text(
                                     '${count}개',
                                     style: const TextStyle(
                                       color: Colors.grey,
                                       fontSize: 14,
                                       fontFamily: 'Pretendard',
                                     ),
                                   );
                               },
                             ),
                          ],
                        ),
                      ),
                      // 찜목록 스크롤 영역
                      Expanded(
                        child: FavoritesList(
                          userId: widget.userId,
                          onCourseAdded: _loadSchedule,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 