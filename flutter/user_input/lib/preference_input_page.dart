import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreferenceInputPage extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onNext;
  
  const PreferenceInputPage({
    Key? key, 
    this.isOnboarding = false,
    this.onNext,
  }) : super(key: key);

  @override
  State<PreferenceInputPage> createState() => _PreferenceInputPageState();
}

class _PreferenceInputPageState extends State<PreferenceInputPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isMajor = true;

  Map<String, String> majorPrefs = {};
  Map<String, String> generalPrefs = {};

  // 저장 함수 추가
  Future<bool> savePreferences() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.email)
          .set({
        'preferences': {
          'major': majorPrefs,
          'liberal': generalPrefs,
        }
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('🔥 Firestore 저장 에러: $e');
      return false;
    }
  }

  final examOptions = ['없음', '두 번', '한 번', '모름', '세 번', '네 번 이상'];
  final assignmentOptions = ['보통', '많음', '모름', '없음'];
  final groupOptions = ['보통', '없음', '많음', '모름'];
  final attendanceOptions = ['복합적', '직접호명', '전자출결', '모름', '반영안함', '지정좌석'];
  final gradeOptions = ['보통', '너그러움', '깐깐함', '모름'];
  final timeOptions = ['풀강', '풀강 아님', '모름'];
  final abilityOptions = ['좋음', '보통', '나쁨', '모름'];
  final typeOptions = ['일반', '일반(블렌디드형)', '원격(녹화콘텐츠)', '원격(블렌디드형)', '원격(온라인형)'];
  final ratingOptions = ['무관', '1점이상', '2점이상', '3점이상', '4점이상'];
  final campusOptions = ['수정', '운정', '무관'];

  final List<List<String>> pageFields = [
    ['시험', '과제', '조모임', '출결', '성적'],
    ['강의시간', '강의력', '수업유형', '평점', '캠퍼스'],
    ['시험', '과제', '조모임', '출결', '성적'],
    ['강의시간', '강의력', '수업유형', '평점', '캠퍼스'],
  ];

  Map<String, List<String>> get fieldOptions => {
        '시험': examOptions,
        '과제': assignmentOptions,
        '조모임': groupOptions,
        '출결': attendanceOptions,
        '성적': gradeOptions,
        '강의시간': timeOptions,
        '강의력': abilityOptions,
        '수업유형': typeOptions,
        '평점': ratingOptions,
        '캠퍼스': campusOptions,
      };

  @override
  Widget build(BuildContext context) {
    final fields = pageFields[_currentPage];
    final prefs = _currentPage < 2 ? majorPrefs : generalPrefs;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.home, color: Color(0xFF862CF9)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          _buildMajorGeneralToggle(),
          const SizedBox(height: 32),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              onPageChanged: (idx) {
                setState(() {
                  _currentPage = idx;
                  _isMajor = idx < 2;
                });
              },
              itemBuilder: (context, idx) {
                final fields = pageFields[idx];
                final prefs = idx < 2 ? majorPrefs : generalPrefs;
                return Center(
                  child: Container(
                    width: 360,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F6F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        ...fields.map((field) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF222222),
                                      fontFamily: 'GangwonEdu',
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: prefs[field],
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFB39DDB)),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF222222),
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Pretendard',
                                        ),
                                        dropdownColor: Colors.white,
                                        items: fieldOptions[field]!
                                            .map((opt) => DropdownMenuItem(
                                                  value: opt,
                                                  child: Text(opt, style: const TextStyle(fontFamily: 'Pretendard')),
                                                ))
                                            .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            prefs[field] = val!;
                                          });
                                        },
                                        hint: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('선택', style: TextStyle(fontFamily: 'Pretendard')),
                                          ),
                                        ),
                                        // 내부 좌우 패딩 추가
                                        selectedItemBuilder: (context) => fieldOptions[field]!
                                            .map((opt) => Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                  child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Text(opt, style: const TextStyle(fontFamily: 'Pretendard'))),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 24),
                        if (idx == 1 || idx == 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF1F3F5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      elevation: 0,
                                    ),
                                    onPressed: _currentPage > 0
                                        ? () {
                                            _pageController.previousPage(
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.ease);
                                            setState(() => _currentPage--);
                                          }
                                        : null,
                                    child: const Icon(Icons.chevron_left, color: Color(0xFF999999)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF862CF9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
    onPressed: () async {
      try {
        // 🔹 Firestore에 저장
        await savePreferences();

        // 🔹 저장 완료 후 처리
        if (!mounted) return;
        
        if (widget.isOnboarding) {
          // Onboarding flow: 저장 완료 후 안내창 표시
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  '저장되었습니다',
                  style: TextStyle(
                    fontFamily: 'GangwonEdu',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // 안내창 닫기
                    },
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontFamily: 'GangwonEdu',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF862CF9),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          // 기존 사용자일 때는 안내창 표시 후 이전 화면으로
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  '저장되었습니다',
                  style: TextStyle(
                    fontFamily: 'GangwonEdu',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // 안내창 닫기
                      Navigator.pop(context); // 이전 화면으로
                    },
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontFamily: 'GangwonEdu',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF862CF9),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        print('🔥 Firestore 저장 에러: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    },
    child: const Text(
      '저장',
      style: TextStyle(
        color: Colors.white,
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
                        // 꺾쇠만 있는 경우(1,3페이지 제외)
                        if (idx != 1 && idx != 3 && idx < 3)
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right, size: 32, color: Color(0xFF862CF9)),
                              onPressed: () {
                                _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.ease);
                                setState(() => _currentPage++);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // 온보딩일 때만 완료 버튼 표시
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
                  onPressed: () {
                    // onNext 콜백이 있으면 호출, 없으면 홈으로 이동
                    if (widget.onNext != null) {
                      widget.onNext!();
                    } else {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('완료', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF862CF9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMajorGeneralToggle() {
    return Container(
      width: 220,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isMajor = true;
                  _pageController.jumpToPage(0);
                  _currentPage = 0;
                });
              },
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isMajor ? const Color(0xFF862CF9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '전공',
                  style: TextStyle(
                    color: _isMajor ? Colors.white : const Color(0xFF999999),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'GangwonEdu',
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isMajor = false;
                  _pageController.jumpToPage(2);
                  _currentPage = 2;
                });
              },
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !_isMajor ? const Color(0xFF862CF9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '교양',
                  style: TextStyle(
                    color: !_isMajor ? Colors.white : const Color(0xFF999999),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'GangwonEdu',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}