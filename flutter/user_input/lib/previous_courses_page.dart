import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'schedule_loading_page.dart';
import 'course_list_page.dart';

class PreviousCoursesPage extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onNext;
  
  const PreviousCoursesPage({
    Key? key, 
    this.isOnboarding = false,
    this.onNext,
  }) : super(key: key);

  @override
  State<PreviousCoursesPage> createState() => _PreviousCoursesPageState();
}

class _PreviousCoursesPageState extends State<PreviousCoursesPage> {
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

  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  int _visibleSemesters = 1; // 처음에는 1학년 1학기만 보이도록
  bool _isSaving = false; // 저장 중 상태를 관리

  // 저장 함수 추가
  Future<bool> saveScheduleLinks() async {
    print('🔥 saveScheduleLinks 함수 진입!');
    print('🔥 현재 _isSaving 상태: $_isSaving');
    
    // _isSaving 상태를 강제로 초기화
    if (_isSaving) {
      print('🔥 _isSaving을 false로 강제 초기화');
      setState(() {
        _isSaving = false;
      });
    }

    print('🔥 _isSaving을 true로 설정');
    setState(() {
      _isSaving = true;
    });

    try {
      print('🔥 저장 시작...');
      print('🔥 _visibleSemesters: $_visibleSemesters');
      
      // 입력된 데이터 수집 및 학기명 변환
      Map<String, String> scheduleLinks = {};
      List<String> validUrls = [];
      
      for (int i = 0; i < _visibleSemesters; i++) {
        String link = _controllers[i].text.trim();
        print('🔥 학기 $i: "$link"');
        if (link.isNotEmpty) {
          // "1학년 1학기" -> "1-1" 변환
          final match = RegExp(r'(\d)학년 (\d)학기').firstMatch(_semesters[i]);
          if (match != null) {
            final year = match.group(1);
            final semester = match.group(2);
            scheduleLinks['$year-$semester'] = link;
            validUrls.add(link);
            print('🔥 링크 추가: $year-$semester = $link');
          } else {
            print('🔥 학기명 매칭 실패: ${_semesters[i]}');
          }
        } else {
          print('🔥 빈 링크: 학기 $i');
        }
      }

      print('🔥 수집된 링크: $scheduleLinks');
      print('🔥 유효한 URL 목록: $validUrls');
      print('🔥 사용자 이메일: ${FirebaseAuth.instance.currentUser?.email}');

      // Firestore에 저장
      print('🔥 Firestore 저장 시도...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.email)
          .set({
        'schedule_links': scheduleLinks,
      }, SetOptions(merge: true));

      print('🔥 Firestore 저장 완료!');
      
      // 로딩 페이지로 이동
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleLoadingPage(
              urls: validUrls,
              semesters: _semesters.take(_visibleSemesters).toList(),
              onNext: widget.onNext,
            ),
          ),
        );
      }
      
      return true; // 저장 성공
    } catch (e) {
      print('🔥 저장 중 에러: $e');
      return false; // 저장 실패
    }
  }

  @override
  void initState() {
    super.initState();
    // 모든 학기에 대한 컨트롤러와 포커스 노드 초기화
    for (int i = 0; i < _semesters.length; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
    
    // 키보드 단축키 지원을 위한 포커스 노드 추가
    _setupKeyboardShortcuts();
    
    // 온보딩이 아닐 때만 기존 저장된 링크들을 불러오기
    if (!widget.isOnboarding) {
      _loadExistingLinks();
    }
  }
  
  void _setupKeyboardShortcuts() {
    // 각 컨트롤러에 키보드 단축키 리스너 추가
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        // 텍스트 변경 시 자동으로 다음 필드로 포커스 이동
        if (_controllers[i].text.isNotEmpty && i < _visibleSemesters - 1) {
          // 다음 필드가 있으면 자동으로 다음으로 이동
        }
      });
      
      // 포커스 노드에 리스너 추가
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          // 포커스가 있을 때 텍스트 전체 선택
          _controllers[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[i].text.length,
          );
        }
      });
    }
  }
  
  String _getSemesterForUrl(int index) {
    // 인덱스에 해당하는 학기를 API 형식으로 변환
    if (index < _visibleSemesters) {
      final match = RegExp(r'(\d)학년 (\d)학기').firstMatch(_semesters[index]);
      if (match != null) {
        final year = match.group(1);
        final semester = match.group(2);
        return '$year-$semester'; // "1-1", "1-2" 형식으로 통일
      }
    }
    return '1-1'; // 기본값
  }



  @override
  void dispose() {
    // 컨트롤러들과 포커스 노드들 해제
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }



  // 기존 저장된 링크들을 불러오는 함수
  Future<void> _loadExistingLinks() async {
    try {
      print('🔥 기존 저장된 링크 불러오기 시작');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없습니다.');
        return;
      }
      
      // Firestore에서 기존 저장된 링크들 가져오기
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        final scheduleLinks = data?['schedule_links'] as Map<String, dynamic>?;
        
        if (scheduleLinks != null) {
          print('🔥 기존 저장된 링크들: $scheduleLinks');
          
          // 각 학기별로 링크 설정
          for (int i = 0; i < _semesters.length; i++) {
            final match = RegExp(r'(\d)학년 (\d)학기').firstMatch(_semesters[i]);
            if (match != null) {
              final year = match.group(1);
              final semester = match.group(2);
              final key = '$year-$semester';
              
              if (scheduleLinks.containsKey(key)) {
                final link = scheduleLinks[key] as String;
                _controllers[i].text = link;
                print('🔥 학기 ${_semesters[i]}에 링크 설정: $link');
              }
            }
          }
          
          // 저장된 링크가 있는 학기 수만큼 visibleSemesters 설정
          int maxVisibleSemester = 1;
          for (int i = 0; i < _semesters.length; i++) {
            final match = RegExp(r'(\d)학년 (\d)학기').firstMatch(_semesters[i]);
            if (match != null) {
              final year = match.group(1);
              final semester = match.group(2);
              final key = '$year-$semester';
              
              if (scheduleLinks.containsKey(key) && scheduleLinks[key].toString().isNotEmpty) {
                maxVisibleSemester = i + 1;
              }
            }
          }
          
          setState(() {
            _visibleSemesters = maxVisibleSemester;
          });
          
          print('🔥 표시할 학기 수: $_visibleSemesters');
        }
      }
      
      print('🔥 기존 저장된 링크 불러오기 완료');
    } catch (e) {
      print('🔥 기존 저장된 링크 불러오기 실패: $e');
    }
  }

  void _addNextSemester() {
    if (_visibleSemesters < _semesters.length) {
      setState(() {
        _visibleSemesters++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '이전학기 수강내역',
          style: TextStyle(
            fontFamily: 'GangwonEdu',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF333333),
              size: 20,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '각 학기별 수강내역 링크를 입력해주세요',
                    style: TextStyle(
                      fontFamily: 'GangwonEdu',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 학기별 입력 필드들
                  ...List.generate(_visibleSemesters, (index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _semesters[index],
                            style: const TextStyle(
                              fontFamily: 'GangwonEdu',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                            child: TextField(
                              controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    enableInteractiveSelection: true,
                                    keyboardType: TextInputType.url,
                                    textInputAction: index < _visibleSemesters - 1 ? TextInputAction.next : TextInputAction.done,
                                    autocorrect: false,
                                    enableSuggestions: false,
                              decoration: const InputDecoration(
                                hintText: '링크를 입력하세요',
                                hintStyle: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  color: Color(0xFF999999),
                                ),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                              ),
                                    onTap: () {
                                      // 텍스트 전체 선택
                                      _controllers[index].selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: _controllers[index].text.length,
                                      );
                                    },
                                  ),
                                ),
                                if (_controllers[index].text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _controllers[index].clear();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.clear,
                                        color: Color(0xFF999999),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // 플러스 버튼 (다음 학기 추가)
                  if (_visibleSemesters < _semesters.length)
                    Center(
                      child: GestureDetector(
                        onTap: _addNextSemester,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF862CF9),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF862CF9).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      // 저장 버튼은 온보딩이 아닐 때만 표시
      bottomNavigationBar: widget.isOnboarding
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () async {
                    setState(() {
                      _isSaving = true;
                    });
                                            try {
                          bool saveSuccess = await saveScheduleLinks();
                          if (mounted) {
                            if (saveSuccess) {
                              // 저장 성공 시 다음 단계로
                              if (widget.onNext != null) {
                                widget.onNext!();
                              } else {
                                Navigator.of(context).pop('next');
                              }
                            } else {
                              // 저장 실패 시 사용자에게 알림
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('저장에 실패했습니다. 다시 시도해주세요.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          print('저장 중 오류: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('저장 중 오류가 발생했습니다: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                            });
                          }
                        }
                  },
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.arrow_forward, color: Colors.white),
                  label: _isSaving
                      ? const Text('저장 중...', style: TextStyle(color: Colors.white, fontSize: 16))
                      : const Text('다음', style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF862CF9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () async {
                    setState(() {
                      _isSaving = true;
                    });
                                            try {
                          bool saveSuccess = await saveScheduleLinks();
                          if (mounted) {
                                                      if (saveSuccess) {
                            // 저장 성공 시 로딩 페이지로 이동 (saveScheduleLinks에서 처리됨)
                          } else {
                              // 저장 실패 시 사용자에게 알림
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('저장에 실패했습니다. 다시 시도해주세요.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          print('저장 중 오류: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('저장 중 오류가 발생했습니다: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                            });
                          }
                        }
                  },
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: _isSaving
                      ? const Text('저장 중...', style: TextStyle(color: Colors.white, fontSize: 16))
                      : const Text('저장', style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF862CF9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
} 