import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreviousRecommendationsPage extends StatefulWidget {
  const PreviousRecommendationsPage({Key? key}) : super(key: key);

  @override
  State<PreviousRecommendationsPage> createState() => _PreviousRecommendationsPageState();
}

class _PreviousRecommendationsPageState extends State<PreviousRecommendationsPage> {
  int _selectedTabIndex = 0; // 0: 전공, 1: 교양
  Set<int> _likedMajorCourses = {}; // 전공 찜한 강의들의 인덱스
  Set<int> _likedLiberalCourses = {}; // 교양 찜한 강의들의 인덱스
  String _selectedDate = '2025-07-30'; // 선택된 날짜
  bool _isLoading = true;

  List<String> _availableDates = [];
  List<Map<String, dynamic>> _majorCourses = [];
  List<Map<String, dynamic>> _liberalCourses = [];
  List<Map<String, dynamic>> _userRecommendations = [];
  Set<String> _existingFavoriteIds = {}; // 기존 찜 목록 ID들

  @override
  void initState() {
    super.initState();
    _loadUserRecommendations();
    _loadExistingFavorites();
  }

  Future<void> _loadUserRecommendations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없습니다.');
        _loadDefaultData();
        return;
      }

      print('🔥 Firebase에서 추천 내역 직접 조회...');
      
      // results 컬렉션에서 모든 추천 내역 가져오기
      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .collection('results')
          .get();

            // 날짜별로 그룹화하기 위한 Map
      Map<String, Map<String, dynamic>> dateGroupedRecommendations = {};
      
      // 각 문서에서 전공과 교양 데이터 모두 추출
      for (var doc in resultsSnapshot.docs) {
        final data = doc.data();
        print('🔥 문서 데이터: $data');
        
        // 날짜 정보 추출
        Timestamp? timestamp;
        
        if (data['createdAt'] != null) {
          if (data['createdAt'] is String) {
            try {
              final dateTime = DateTime.parse(data['createdAt'] as String);
              timestamp = Timestamp.fromDate(dateTime);
            } catch (e) {
              print('🔥 createdAt 파싱 실패: $e');
            }
          } else if (data['createdAt'] is Timestamp) {
            timestamp = data['createdAt'] as Timestamp;
          }
        }
        
        if (timestamp == null) {
          timestamp = Timestamp.now();
        }
        
        // 날짜를 문자열로 변환 (YYYY-MM-DD 형식)
        final dateString = '${timestamp.toDate().year}-${timestamp.toDate().month.toString().padLeft(2, '0')}-${timestamp.toDate().day.toString().padLeft(2, '0')}';
        
        // 전공 데이터 처리
        List<dynamic> majorCourses = data['majorRecommendations'] ?? [];
        print('🔥 전공 강의 수: ${majorCourses.length}개');
        
        // 교양 데이터 처리 - liberalRecommendations와 careerRecommendations 모두 포함
        List<dynamic> liberalCourses = [];
        List<dynamic> liberalRecs = data['liberalRecommendations'] ?? [];
        List<dynamic> careerRecs = data['careerRecommendations'] ?? [];
        
        // 두 배열을 합치기
        liberalCourses.addAll(liberalRecs);
        liberalCourses.addAll(careerRecs);
        
        print('🔥 교양 강의 수: ${liberalCourses.length}개 (liberal: ${liberalRecs.length}개, career: ${careerRecs.length}개)');
        
        // 같은 날짜의 데이터를 합치기
        if (dateGroupedRecommendations.containsKey(dateString)) {
          // 기존 데이터에 추가
          final existing = dateGroupedRecommendations[dateString]!;
          final existingMajor = existing['majorCourses'] as List<dynamic>;
          final existingLiberal = existing['liberalCourses'] as List<dynamic>;
          
          existingMajor.addAll(majorCourses);
          existingLiberal.addAll(liberalCourses);
          
          print('🔥 기존 날짜에 데이터 추가: $dateString');
        } else {
          // 새로운 날짜 생성
          dateGroupedRecommendations[dateString] = {
            'id': dateString,
            'timestamp': timestamp,
            'majorCourses': majorCourses,
            'liberalCourses': liberalCourses,
          };
          print('🔥 새로운 날짜 생성: $dateString');
        }
      }
      
      // Map을 List로 변환
      List<Map<String, dynamic>> combinedRecommendations = dateGroupedRecommendations.values.toList();

             if (mounted) {
         setState(() {
           _userRecommendations = combinedRecommendations;
           _availableDates = combinedRecommendations.map((rec) {
             final timestamp = rec['timestamp'] as Timestamp;
             return '${timestamp.toDate().year}-${timestamp.toDate().month.toString().padLeft(2, '0')}-${timestamp.toDate().day.toString().padLeft(2, '0')}';
           }).toList();
           
           if (_availableDates.isNotEmpty) {
             // 첫 번째 추천 내역 선택
             _selectedDate = _availableDates.first;
             print('🔥 첫 번째 추천 내역 선택: 인덱스 0');
             _loadRecommendationData(combinedRecommendations.first);
           } else {
             // 데이터가 없으면 기본 데이터 로드
             _loadDefaultData();
           }
           
           _isLoading = false;
         });
       }
    } catch (e) {
      print('🔥 추천 내역 로딩 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // 에러 시 기본 데이터 로드
          _loadDefaultData();
        });
      }
    }
  }

  void _loadRecommendationData(Map<String, dynamic> recommendation) {
    try {
      final majorCourses = recommendation['majorCourses'] as List<dynamic>? ?? [];
      final liberalCourses = recommendation['liberalCourses'] as List<dynamic>? ?? [];
      
      print('🔥 전공 강의 수: ${majorCourses.length}개, 교양 강의 수: ${liberalCourses.length}개');
      
      // 전공 강의 처리
      if (majorCourses.isNotEmpty) {
        print('🔥 전공 강의 원본 데이터: $majorCourses');
        _majorCourses = majorCourses.map((course) {
          final processedCourse = {
            'name': course['과목명']?.toString() ?? '강의명 없음',
            'professor': course['교수명']?.toString() ?? '교수명 없음',
            'department': course['개설학과전공']?.toString() ?? '',
            'area': course['영역']?.toString() ?? '',
            'reasons': _parseReasons(course['추천 이유'] ?? course['추천이유']),
          };
          print('🔥 처리된 전공 강의: $processedCourse');
          return processedCourse;
        }).toList();
        print('🔥 전공 강의 로드 완료: ${_majorCourses.length}개');
      } else {
        _majorCourses = [];
        print('🔥 전공 강의가 없습니다.');
      }
      
      // 교양 강의 처리
      if (liberalCourses.isNotEmpty) {
        print('🔥 교양 강의 원본 데이터: $liberalCourses');
        _liberalCourses = liberalCourses.map((course) {
          // 교양 데이터 구조 처리 (다양한 필드명 지원)
          final processedCourse = {
            'name': course['과목명']?.toString() ?? course['course_name']?.toString() ?? '강의명 없음',
            'professor': course['교수명']?.toString() ?? course['professor_name']?.toString() ?? '교수명 없음',
            'area': course['영역']?.toString() ?? course['area']?.toString() ?? '',
            'creditType': course['이수구분']?.toString() ?? course['credit_type']?.toString() ?? '',
            'reasons': _parseReasons(course['추천이유'] ?? course['추천 이유'] ?? course['recommendation_reasons']),
          };
          print('🔥 처리된 교양 강의: $processedCourse');
          return processedCourse;
        }).toList();
        print('🔥 교양 강의 로드 완료: ${_liberalCourses.length}개');
      } else {
        _liberalCourses = [];
        print('🔥 교양 강의가 없습니다.');
      }
      
      // 강의 데이터가 로드된 후 기존 찜 상태 업데이트
      _updateFavoriteStatus();
    } catch (e) {
      print('🔥 추천 데이터 로드 실패: $e');
      _loadDefaultData();
    }
  }

  // 기존 찜 목록 불러오기
  Future<void> _loadExistingFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없어서 찜 목록을 불러올 수 없습니다.');
        return;
      }

      print('🔥 기존 찜 목록 불러오는 중...');
      
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .collection('favorites')
          .get();

      Set<String> existingFavoriteIds = {};
      
      for (var doc in favoritesSnapshot.docs) {
        final data = doc.data();
        final courseName = data['과목명']?.toString() ?? '';
        final professorName = data['교수명']?.toString() ?? '';
        final courseType = data['courseType']?.toString() ?? '';
        
        if (courseName.isNotEmpty && professorName.isNotEmpty) {
          final favoriteId = '${courseName}_$professorName';
          existingFavoriteIds.add(favoriteId);
          print('🔥 기존 찜 강의: $favoriteId (타입: $courseType)');
        }
      }
      
      // 전역 변수로 저장하여 나중에 사용
      _existingFavoriteIds = existingFavoriteIds;
      print('🔥 총 ${existingFavoriteIds.length}개의 기존 찜 강의 로드 완료');
      
      // 강의 데이터가 이미 로드되어 있다면 찜 상태 업데이트
      if (_majorCourses.isNotEmpty || _liberalCourses.isNotEmpty) {
        _updateFavoriteStatus();
      }
    } catch (e) {
      print('🔥 찜 목록 불러오기 실패: $e');
    }
  }

  // 찜 상태 업데이트
  void _updateFavoriteStatus() {
    if (_existingFavoriteIds.isEmpty) return;
    
    setState(() {
      // 전공 강의 찜 상태 업데이트
      _likedMajorCourses.clear();
      for (int i = 0; i < _majorCourses.length; i++) {
        final course = _majorCourses[i];
        final courseName = course['name']?.toString() ?? '';
        final professorName = course['professor']?.toString() ?? '';
        final favoriteId = '${courseName}_$professorName';
        
        if (_existingFavoriteIds.contains(favoriteId)) {
          _likedMajorCourses.add(i);
          print('🔥 전공 강의 찜 상태 업데이트: $favoriteId');
        }
      }
      
      // 교양 강의 찜 상태 업데이트
      _likedLiberalCourses.clear();
      for (int i = 0; i < _liberalCourses.length; i++) {
        final course = _liberalCourses[i];
        final courseName = course['name']?.toString() ?? '';
        final professorName = course['professor']?.toString() ?? '';
        final favoriteId = '${courseName}_$professorName';
        
        if (_existingFavoriteIds.contains(favoriteId)) {
          _likedLiberalCourses.add(i);
          print('🔥 교양 강의 찜 상태 업데이트: $favoriteId');
        }
      }
    });
  }

  // 추천 이유를 안전하게 List<String>으로 변환
  List<String> _parseReasons(dynamic reasons) {
    if (reasons == null) return ['추천 이유 없음'];
    
    if (reasons is String) {
      // 문자열이 비어있으면 기본값 반환
      if (reasons.trim().isEmpty) return ['추천 이유 없음'];
      return [reasons.trim()];
    } else if (reasons is List) {
      final parsedReasons = reasons.map((reason) {
        if (reason == null) return '알 수 없음';
        final reasonStr = reason.toString().trim();
        return reasonStr.isEmpty ? '알 수 없음' : reasonStr;
      }).toList();
      return parsedReasons.isEmpty ? ['추천 이유 없음'] : parsedReasons;
    } else {
      final reasonStr = reasons.toString().trim();
      return reasonStr.isEmpty ? ['추천 이유 없음'] : [reasonStr];
    }
  }

  // 기본 임시 데이터 (API 응답이 없을 때)
  void _loadDefaultData() {
    _majorCourses = [
      {
        'name': '강의명1',
        'professor': '장재경',
        'time': '월 4-6',
        'difficulty': '강의력 보통',
        'reasons': ['전공필수', '학점취득', '실무연계']
      },
      {
        'name': '강의명2',
        'professor': '김영수',
        'time': '화 2-4',
        'difficulty': '강의력 쉬움',
        'reasons': ['실습중심', '실무능력', '취업준비']
      },
      {
        'name': '강의명3',
        'professor': '이미영',
        'time': '수 1-3',
        'difficulty': '강의력 어려움',
        'reasons': ['최신기술', '심화과정', '연구진출']
      },
      {
        'name': '강의명4',
        'professor': '박철수',
        'time': '목 3-5',
        'difficulty': '강의력 보통',
        'reasons': ['팀프로젝트', '협업능력', '커뮤니케이션']
      },
    ];

    _liberalCourses = [
      {
        'name': '교양강의1',
        'professor': '최민수',
        'time': '월 1-3',
        'difficulty': '강의력 쉬움',
        'reasons': ['인문학', '교양증진', '사고력']
      },
      {
        'name': '교양강의2',
        'professor': '정수진',
        'time': '화 5-7',
        'difficulty': '강의력 보통',
        'reasons': ['토론중심', '창의사고', '발표능력']
      },
      {
        'name': '교양강의3',
        'professor': '한지영',
        'time': '수 4-6',
        'difficulty': '강의력 쉬움',
        'reasons': ['실용지식', '생활적용', '자기계발']
      },
      {
        'name': '교양강의4',
        'professor': '송태호',
        'time': '목 1-3',
        'difficulty': '강의력 보통',
        'reasons': ['글로벌시각', '문화이해', '국제감각']
      },
    ];
  }

  void _toggleLike(int index) {
    setState(() {
      if (_selectedTabIndex == 0) {
        // 전공 탭
        if (_likedMajorCourses.contains(index)) {
          _likedMajorCourses.remove(index);
        } else {
          _likedMajorCourses.add(index);
        }
      } else {
        // 교양 탭
        if (_likedLiberalCourses.contains(index)) {
          _likedLiberalCourses.remove(index);
        } else {
          _likedLiberalCourses.add(index);
        }
      }
    });
  }

  Future<void> _saveCourses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요합니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      int savedCount = 0;

      // 찜한 전공 강의들을 개별 문서로 저장
      for (int index in _likedMajorCourses) {
        if (index < _majorCourses.length) {
          final course = _majorCourses[index];
          final courseName = course['name']?.toString() ?? '강의명 없음';
          final professorName = course['professor']?.toString() ?? '교수명 없음';
          
          // 문서 ID 생성: 강의명_교수명
          final docId = '${courseName}_$professorName';
          
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.email)
              .collection('favorites')
              .doc(docId)
              .set({
            'addedAt': FieldValue.serverTimestamp(),
            '과목명': courseName,
            '교수명': professorName,
            '개설학과전공': course['department']?.toString() ?? '',
            '영역': course['area']?.toString() ?? '',
            '추천 이유': course['reasons'] ?? ['추천 이유 없음'],
            'courseType': 'major', // 전공 강의 구분
          });
          savedCount++;
        }
      }

      // 찜한 교양 강의들을 개별 문서로 저장
      for (int index in _likedLiberalCourses) {
        if (index < _liberalCourses.length) {
          final course = _liberalCourses[index];
          final courseName = course['name']?.toString() ?? '강의명 없음';
          final professorName = course['professor']?.toString() ?? '교수명 없음';
          
          // 문서 ID 생성: 강의명_교수명
          final docId = '${courseName}_$professorName';
          
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.email)
              .collection('favorites')
              .doc(docId)
              .set({
            'addedAt': FieldValue.serverTimestamp(),
            '과목명': courseName,
            '교수명': professorName,
            '개설학과전공': course['department']?.toString() ?? '',
            '영역': course['area']?.toString() ?? '',
            '추천 이유': course['reasons'] ?? ['추천 이유 없음'],
            'courseType': 'liberal', // 교양 강의 구분
          });
          savedCount++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$savedCount개의 강의가 찜 목록에 저장되었습니다.'),
          backgroundColor: const Color(0xFF862CF9),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('🔥 찜 목록 저장 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDatePicker() {
    if (_availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('추천 내역이 없습니다.'),
          backgroundColor: Color(0xFF862CF9),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('날짜 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                final recommendation = _userRecommendations[index];
                final majorCourses = recommendation['majorCourses'] as List<dynamic>? ?? [];
                final liberalCourses = recommendation['liberalCourses'] as List<dynamic>? ?? [];
                final totalCourses = majorCourses.length + liberalCourses.length;
                
                return ListTile(
                  title: Text(_availableDates[index]),
                  subtitle: Text('전공 ${majorCourses.length}개, 교양 ${liberalCourses.length}개'),
                  trailing: const Icon(
                    Icons.school,
                    color: Color(0xFF862CF9),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedDate = _availableDates[index];
                      _loadRecommendationData(recommendation);
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '이전 추천 내역',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
              color: Color(0xFF1A1A1A),
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF862CF9)),
          ),
        ),
      );
    }

    final currentCourses = _selectedTabIndex == 0 ? _majorCourses : _liberalCourses;

    if (_availableDates.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '이전 추천 내역',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
              color: Color(0xFF1A1A1A),
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Color(0xFFCCCCCC),
              ),
              SizedBox(height: 16),
              Text(
                '추천 내역이 없습니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                  color: Color(0xFF666666),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '강의 추천을 받아보세요!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Pretendard',
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '이전 추천 내역',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 날짜 선택 영역
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // 이전 날짜로 이동 (임시)
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF767676)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showDatePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF767676),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // 다음 날짜로 이동 (임시)
                  },
                  icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF767676)),
                ),
              ],
            ),
          ),
          
          // 전공/교양 필터 - 세그먼트 컨트롤 형태
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0 
                              ? const Color(0xFF862CF9) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            '전공',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                              color: _selectedTabIndex == 0 
                                  ? Colors.white 
                                  : const Color(0xFF767676),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 
                              ? const Color(0xFF862CF9) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            '교양',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                              color: _selectedTabIndex == 1 
                                  ? Colors.white 
                                  : const Color(0xFF767676),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 강의 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: currentCourses.length,
                             itemBuilder: (context, index) {
                 final course = currentCourses[index];
                 final isLiked = _selectedTabIndex == 0 
                     ? _likedMajorCourses.contains(index)
                     : _likedLiberalCourses.contains(index);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F6F9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                                                     Text(
                                     course['name']?.toString() ?? '강의명 없음',
                                     style: const TextStyle(
                                       fontSize: 18,
                                       fontWeight: FontWeight.w600,
                                       fontFamily: 'Pretendard',
                                       color: Color(0xFF1A1A1A),
                                     ),
                                   ),
                                   const SizedBox(height: 8),
                                   Text(
                                     '교수명: ${course['professor']?.toString() ?? '교수명 없음'}',
                                     style: const TextStyle(
                                       fontSize: 14,
                                       fontWeight: FontWeight.w400,
                                       fontFamily: 'Pretendard',
                                       color: Color(0xFF767676),
                                     ),
                                   ),
                                   if (_selectedTabIndex == 0 && course['department']?.toString().isNotEmpty == true) ...[
                                     const SizedBox(height: 4),
                                     Text(
                                       '개설학과: ${course['department']}',
                                       style: const TextStyle(
                                         fontSize: 14,
                                         fontWeight: FontWeight.w400,
                                         fontFamily: 'Pretendard',
                                         color: Color(0xFF767676),
                                       ),
                                     ),
                                   ],
                                   if (_selectedTabIndex == 1 && course['creditType']?.toString().isNotEmpty == true) ...[
                                     const SizedBox(height: 4),
                                     Text(
                                       '이수구분: ${course['creditType']}',
                                       style: const TextStyle(
                                         fontSize: 14,
                                         fontWeight: FontWeight.w400,
                                         fontFamily: 'Pretendard',
                                         color: Color(0xFF767676),
                                       ),
                                     ),
                                   ],
                                  const SizedBox(height: 4),
                                  Wrap( // Wrap을 사용하여 여러 개의 이유를 한 줄에 표시
                                    spacing: 8.0, // 각 이유 사이의 간격
                                    runSpacing: 4.0, // 줄 사이의 간격
                                    children: (course['reasons'] as List<dynamic>? ?? ['추천 이유 없음']).map((reason) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF9267FE),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            reason?.toString() ?? '알 수 없음',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Pretendard',
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: () => _toggleLike(index),
                                child: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: const Color(0xFF862CF9),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 저장 버튼
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveCourses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF862CF9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                                 child: Text(
                   '찜 목록에 저장',
                   style: const TextStyle(
                     fontSize: 18,
                     fontWeight: FontWeight.w600,
                     fontFamily: 'Pretendard',
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