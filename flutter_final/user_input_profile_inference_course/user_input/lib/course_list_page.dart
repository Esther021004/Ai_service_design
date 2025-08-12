import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'preference_input_page.dart';

class CourseListPage extends StatefulWidget {
  final VoidCallback? onNext;
  final Map<String, List<Map<String, dynamic>>>? extractedCourses;
  
  const CourseListPage({Key? key, this.onNext, this.extractedCourses}) : super(key: key);

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  String _selectedSemester = '1학년 1학기';
  
  @override
  void initState() {
    super.initState();
    
    // 추출된 강의 데이터가 있으면 사용, 없으면 Firebase에서 불러오기
    if (widget.extractedCourses != null && widget.extractedCourses!.isNotEmpty) {
      _loadExtractedCourses();
    } else {
      _loadCoursesFromLink();
    }
  }
  
  final List<String> _semesters = [
    '1학년 1학기',
    '1학년 2학기',
    '2학년 1학기',
    '2학년 2학기',
    '3학년 1학기',
    '3학년 2학기',
    '4학년 1학기',
    '4학년 2학기',
  ];

  final List<String> _categories = ['전공', '교양'];
  final List<String> _credits = ['1', '2', '3'];

  // 강의 데이터 (API에서 불러온 데이터)
  List<Map<String, dynamic>> _courses = [];

  // 추출된 강의 데이터 로드
  void _loadExtractedCourses() {
    if (widget.extractedCourses == null) return;
    
    // 현재 선택된 학기에 해당하는 강의 데이터 찾기
    String semesterKey = _convertSemesterToApiFormat(_selectedSemester);
    List<Map<String, dynamic>>? semesterCourses = widget.extractedCourses![semesterKey];
    
    if (semesterCourses != null) {
      print('🔥 추출된 강의 데이터 사용: $semesterKey - ${semesterCourses.length}개');
      setState(() {
        _courses = semesterCourses;
      });
    } else {
      print('🔥 추출된 강의 데이터에서 $semesterKey 학기 데이터를 찾을 수 없습니다.');
      setState(() {
        _courses = [];
      });
    }
  }

  Future<void> _loadCoursesFromLink() async {
    // 추출된 강의 데이터가 있으면 Firebase에서 읽어오지 않음
    if (widget.extractedCourses != null && widget.extractedCourses!.isNotEmpty) {
      print('🔥 추출된 강의 데이터가 있으므로 Firebase에서 읽어오지 않습니다.');
      return;
    }
    
    try {
      print('🔥 Firebase에서 강의 데이터 불러오기 시작...');
      print('🔥 선택된 학기: $_selectedSemester');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없습니다.');
        return;
      }

      // 선택된 학기를 API 형식으로 변환 (예: "1학년 1학기" -> "1-1")
      String semesterKey = _convertSemesterToApiFormat(_selectedSemester);
      print('🔥 학기 키: $semesterKey');

      // Firebase 맵 필드에서 해당 학기 강의 데이터 가져오기
      print('🔥 Firebase 맵 필드 조회: ${user!.email}/previous_courses');
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final previousCourses = userData?['previous_courses'] as Map<String, dynamic>?;
        
        if (previousCourses != null && previousCourses.containsKey(semesterKey)) {
          final semesterData = previousCourses[semesterKey] as Map<String, dynamic>?;
          
          // 이미지 구조에 따라 course1, course2, course3... 형태로 저장된 강의들을 찾기
          List<Map<String, dynamic>> courses = [];
          
          // course1부터 course20까지 확인 (충분한 범위)
          for (int i = 1; i <= 20; i++) {
            String courseKey = 'course$i';
            if (semesterData!.containsKey(courseKey)) {
              final courseData = semesterData[courseKey] as Map<String, dynamic>?;
              if (courseData != null) {
                print('🔥 강의 데이터 ($courseKey): $courseData');
                
                courses.add({
                  'name': courseData['과목명'] ?? '강의명 없음',
                  'professor': courseData['교수명'] ?? '교수명 없음',
                  'category': courseData['이수구분'] ?? '전공',
                  'credit': courseData['학점']?.toString() ?? '3',
                });
              }
            }
          }
          
          if (courses.isNotEmpty) {
            print('🔥 $semesterKey 학기 강의 데이터: ${courses.length}개');
            
            setState(() {
              _courses = courses;
            });
            
            print('🔥 변환된 강의 목록: $_courses');
          } else {
            print('🔥 Firebase 맵 필드에 $semesterKey 학기의 강의 데이터가 없습니다.');
            setState(() {
              _courses = [];
            });
          }
        } else {
          print('🔥 Firebase 맵 필드에 $semesterKey 학기 데이터가 없습니다.');
          setState(() {
            _courses = [];
          });
        }
      } else {
        print('🔥 Firebase에 사용자 데이터가 없습니다.');
        setState(() {
          _courses = [];
        });
      }
    } catch (e) {
      print('🔥 Firebase에서 강의 데이터 불러오기 실패: $e');
      setState(() {
        _courses = [];
      });
    }
  }
  
  String _convertSemesterToApiFormat(String semester) {
    // "1학년 1학기" -> "1-1" 형식으로 변환 (previous_courses_page와 일치)
    final match = RegExp(r'(\d)학년 (\d)학기').firstMatch(semester);
    if (match != null) {
      final year = match.group(1);
      final semesterNum = match.group(2);
      return '$year-$semesterNum'; // "1-1", "1-2" 형식
    }
    return '1-1'; // 기본값
  }

  // 모든 학기의 강의 정보를 저장하는 함수
  Future<void> _saveAllSemesters() async {
    try {
      print('🔥 모든 학기 강의 정보 저장 시작...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return;
      
      // 학점 비율 계산 요청
      print('🔥 학점 비율 계산 시작...');
      Map<String, dynamic>? creditRatio = await ApiService.calculateCreditRatio();
      
      if (creditRatio != null) {
        print('🔥 학점 비율 계산 성공: $creditRatio');
        
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
                      color: Color(0xFF862CF9),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '저장 완료',
                      style: TextStyle(
                        fontFamily: 'GangwonEdu',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  '모든 학기의 강의 정보가 성공적으로 저장되었습니다!\n학점 비율이 업데이트되었습니다.',
                  style: const TextStyle(
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
                      '확인',
                      style: TextStyle(
                        fontFamily: 'GangwonEdu',
                        color: Color(0xFF862CF9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
        
        // 온보딩 플로우에서 사용 중이면 다음 단계로 이동
        if (widget.onNext != null) {
          widget.onNext!();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('학점 비율 계산에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('🔥 모든 학기 저장 중 에러: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _modifyCourses() async {
    try {
      print('🔥 강의 정보 업데이트 시작...');
      
      // 중복 제거를 위한 Map 사용 (강의명 + 교수명 + 이수구분을 키로 사용)
      Map<String, Map<String, dynamic>> uniqueCourses = {};
      
      for (var course in _courses) {
        String key = '${course['name']}_${course['professor'] ?? ''}_${course['category']}';
        print('🔥 API 전송용 강의 데이터: ${course['name']} - 이수구분: ${course['category']}, 학점: ${course['credit']}');
        
        // 중복된 강의가 있으면 마지막에 처리된 것으로 덮어쓰기
        uniqueCourses[key] = {
          '과목명': course['name'],
          '교수명': course['professor'] ?? '',
          '이수구분': course['category'],
          '학점': int.tryParse(course['credit']) ?? 3,
        };
      }
      
      // 중복 제거된 강의 목록
      List<Map<String, dynamic>> coursesToUpdate = uniqueCourses.values.toList();
      print('🔥 중복 제거 후 강의 수: ${coursesToUpdate.length}개 (원본: ${_courses.length}개)');
      
      print('🔥 업데이트할 강의 목록: $coursesToUpdate');
      
      // 선택된 학기를 API 형식으로 변환 (예: "1학년 1학기" -> "24-1")
      String semester = _convertSemesterToApiFormat(_selectedSemester);
      
      // API 호출
      bool updateSuccess = await ApiService.updateCourseInfo(coursesToUpdate, semester);
      
      if (updateSuccess) {
        print('🔥 강의 정보 업데이트 성공');
        
        // 학점 비율 계산 요청
        print('🔥 학점 비율 계산 시작...');
        Map<String, dynamic>? creditRatio = await ApiService.calculateCreditRatio();
        
        if (creditRatio != null) {
          print('🔥 학점 비율 계산 성공: $creditRatio');
          // TODO: 학점 비율을 화면에 표시하는 로직 추가
        } else {
          print('🔥 학점 비율 계산 실패');
        }
        
        // 성공 메시지 표시
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('강의 정보가 성공적으로 업데이트되었습니다!'),
              backgroundColor: Color(0xFF862CF9),
            ),
          );
        }
      } else {
        print('🔥 강의 정보 업데이트 실패');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('강의 정보 업데이트에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('🔥 강의 정보 업데이트 중 에러: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 24),
          // 뒤로가기 버튼과 제목
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                                 GestureDetector(
                   onTap: () {
                     // 온보딩 플로우가 아닌 경우 홈화면으로 이동
                     if (widget.onNext == null) {
                       Navigator.of(context).pushReplacementNamed('/home');
                     } else {
                       Navigator.pop(context);
                     }
                   },
                   child: Container(
                     width: 40,
                     height: 40,
                     decoration: BoxDecoration(
                       color: const Color(0xFFF1F3F5),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Icon(
                       // 온보딩 플로우가 아닌 경우 홈 아이콘, 온보딩에서는 뒤로가기 아이콘
                       widget.onNext == null ? Icons.home : Icons.arrow_back_ios_new,
                       color: const Color(0xFF333333),
                       size: 20,
                     ),
                   ),
                 ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF862CF9),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '이전 학기 수강 내역',
                          style: TextStyle(
                            fontFamily: 'GangwonEdu',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 학기 선택 드롭다운
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSemester,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF333333)),
                  style: const TextStyle(
                    fontFamily: 'GangwonEdu',
                    fontSize: 16,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                  menuMaxHeight: 300,
                  items: _semesters.map((String semester) {
                    return DropdownMenuItem<String>(
                      value: semester,
                      child: Text(
                        semester,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) async {
                    setState(() {
                      _selectedSemester = newValue!;
                    });
                    
                    // 추출된 강의 데이터가 있으면 사용, 없으면 Firebase에서 불러오기
                    if (widget.extractedCourses != null && widget.extractedCourses!.isNotEmpty) {
                      _loadExtractedCourses();
                    } else {
                      await _loadCoursesFromLink();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 구분선
          Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const SizedBox(height: 16),
          // 테이블 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    '강의명',
                    style: TextStyle(
                      fontFamily: 'GangwonEdu',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '구분',
                    style: TextStyle(
                      fontFamily: 'GangwonEdu',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '학점',
                    style: TextStyle(
                      fontFamily: 'GangwonEdu',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 강의 목록
          Expanded(
            child: _courses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$_selectedSemester 강의 데이터가 없습니다',
                          style: TextStyle(
                            fontFamily: 'GangwonEdu',
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '이전 수강 내역에서 해당 학기 링크를 입력해주세요',
                          style: TextStyle(
                            fontFamily: 'GangwonEdu',
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _courses.length,
                    separatorBuilder: (context, index) => Container(
                      height: 1,
                      color: const Color(0xFFE0E0E0),
                    ),
                    itemBuilder: (context, index) {
                final course = _courses[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course['name'],
                              style: const TextStyle(
                                fontFamily: 'GangwonEdu',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333),
                              ),
                            ),
                            if (course['professor'] != null && course['professor'].isNotEmpty)
                              Text(
                                course['professor'],
                                style: const TextStyle(
                                  fontFamily: 'GangwonEdu',
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: course['category'],
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF333333)),
                              style: const TextStyle(
                                fontFamily: 'GangwonEdu',
                                fontSize: 12,
                                color: Color(0xFF333333),
                              ),
                              menuMaxHeight: 200,
                              items: _categories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  course['category'] = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: course['credit'],
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF333333)),
                              style: const TextStyle(
                                fontFamily: 'GangwonEdu',
                                fontSize: 12,
                                color: Color(0xFF333333),
                              ),
                              menuMaxHeight: 200,
                              items: _credits.map((String credit) {
                                return DropdownMenuItem<String>(
                                  value: credit,
                                  child: Text(
                                    credit,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  course['credit'] = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // 저장 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // 현재 학기 저장 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _courses.isNotEmpty ? _modifyCourses : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF862CF9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFFCCCCCC),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.save,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_selectedSemester 저장',
                          style: const TextStyle(
                            fontFamily: 'GangwonEdu',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 다음 버튼 (온보딩 플로우에서만 표시)
                if (widget.onNext != null)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                                             onPressed: () {
                         // 온보딩 플로우가 dispose된 경우를 대비해 직접 네비게이션
                         Navigator.pushReplacement(
                           context,
                           MaterialPageRoute(
                             builder: (context) => const PreferenceInputPage(isOnboarding: true),
                           ),
                         );
                       },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '다음',
                            style: TextStyle(
                              fontFamily: 'GangwonEdu',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // 안내 텍스트
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF862CF9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '각 학기별로 강의 정보를 수정하고 저장할 수 있습니다.',
                          style: const TextStyle(
                            fontFamily: 'GangwonEdu',
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
} 