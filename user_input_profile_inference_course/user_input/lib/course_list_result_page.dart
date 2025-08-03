import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourseListResultPage extends StatefulWidget {
  final Map<String, dynamic>? recommendations;
  
  const CourseListResultPage({Key? key, this.recommendations}) : super(key: key);

  @override
  State<CourseListResultPage> createState() => _CourseListResultPageState();
}

class _CourseListResultPageState extends State<CourseListResultPage> {
  int _selectedTabIndex = 0; // 0: 전공, 1: 교양
  Set<int> _likedMajorCourses = {}; // 전공 찜한 강의들의 인덱스
  Set<int> _likedLiberalCourses = {}; // 교양 찜한 강의들의 인덱스

  List<Map<String, dynamic>> _majorCourses = [];
  List<Map<String, dynamic>> _liberalCourses = [];

  @override
  void initState() {
    super.initState();
    _processRecommendations();
    _loadFavorites();
  }

  // 기존 찜 목록 로드
  Future<void> _loadFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return;

      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .collection('favorites')
          .get();

      // 현재 선택된 탭에 따라 적절한 강의 목록과 찜 목록 사용
      final currentCourses = _selectedTabIndex == 0 ? _majorCourses : _liberalCourses;
      final currentLikedSet = _selectedTabIndex == 0 ? _likedMajorCourses : _likedLiberalCourses;
      
      // 찜된 강의들의 인덱스 찾기
      Set<int> likedIndices = {};
      for (int i = 0; i < currentCourses.length; i++) {
        final course = currentCourses[i];
        final lectureId = '${course['name']}_${course['professor']}'.replaceAll(' ', '_');
        
        // Firebase에서 해당 강의가 찜 목록에 있는지 확인
        final isLiked = favoritesSnapshot.docs.any((doc) => doc.id == lectureId);
        if (isLiked) {
          likedIndices.add(i);
        }
      }

      setState(() {
        if (_selectedTabIndex == 0) {
          _likedMajorCourses = likedIndices;
        } else {
          _likedLiberalCourses = likedIndices;
        }
      });

      print('🔥 ${_selectedTabIndex == 0 ? "전공" : "교양"} 찜 목록 로드 완료: ${likedIndices.length}개');
    } catch (e) {
      print('🔥 찜 목록 로드 실패: $e');
    }
  }

  void _processRecommendations() async {
    if (widget.recommendations != null) {
      // API 응답에서 강의 데이터 추출
      final recommendations = widget.recommendations!;
      print('🔥 결과 페이지에서 받은 데이터: $recommendations');
      
      // 전공 강의 처리 - API 응답 구조에 맞게 수정
      if (recommendations['recommendations'] != null) {
        final rawCourses = List<Map<String, dynamic>>.from(recommendations['recommendations']);
        _majorCourses = rawCourses.map((course) {
          return {
            'name': course['과목명']?.toString() ?? '강의명 없음',
            'professor': course['교수명']?.toString() ?? '교수명 없음',
            'time': '시간 미정', // API에서 시간 정보가 없음
            'reasons': _parseReasons(course['추천 이유']),
            'department': course['개설학과전공']?.toString() ?? '',
            'area': course['영역']?.toString() ?? '',
          };
        }).toList();
        print('🔥 전공 강의 처리 완료: ${_majorCourses.length}개');
      }
    }
    
    // Firebase에서 교양 강의 데이터 불러오기
    await _loadLiberalCoursesFromFirebase();
  }

  // Firebase에서 교양 강의 데이터 불러오기
  Future<void> _loadLiberalCoursesFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return;

      print('🔥 Firebase에서 교양 강의 데이터 불러오기 시작...');
      
      // results 컬렉션에서 모든 문서 가져오기 (인덱스 오류 방지)
      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .collection('results')
          .get();

      if (resultsSnapshot.docs.isNotEmpty) {
        // 클라이언트에서 최신 문서 찾기 (documentId로 정렬)
        final sortedDocs = resultsSnapshot.docs.toList()
          ..sort((a, b) => b.id.compareTo(a.id));
        
        final latestDoc = sortedDocs.first;
        final docData = latestDoc.data();
        
        print('🔥 Firebase 문서 데이터: $docData');
        
        // liberalRecommendations 배열에서 데이터 추출
        if (docData['liberalRecommendations'] != null) {
          final rawLiberalCourses = List<Map<String, dynamic>>.from(docData['liberalRecommendations']);
          _liberalCourses = rawLiberalCourses.map((course) {
            return {
              'name': course['과목명']?.toString() ?? '강의명 없음',
              'professor': course['교수명']?.toString() ?? '교수명 없음',
              'time': '시간 미정',
              'reasons': _parseReasons(course['추천이유']),
              'department': course['이수구분']?.toString() ?? '',
              'area': course['영역']?.toString() ?? '',
            };
          }).toList();
          
          print('🔥 Firebase에서 교양 강의 처리 완료: ${_liberalCourses.length}개');
          
          // UI 업데이트
          if (mounted) {
            setState(() {});
          }
        } else {
          print('🔥 Firebase에 liberalRecommendations 데이터가 없습니다.');
        }
      } else {
        print('🔥 Firebase에 results 컬렉션이 없습니다.');
      }
    } catch (e) {
      print('🔥 Firebase에서 교양 강의 불러오기 실패: $e');
    }
  }

  List<String> _parseReasons(dynamic reasons) {
    if (reasons == null) {
      return [];
    }
    if (reasons is String) {
      return [reasons];
    }
    if (reasons is List) {
      return List<String>.from(reasons);
    }
    return [];
  }

  void _toggleLike(int index) async {
    final currentCourses = _selectedTabIndex == 0 ? _majorCourses : _liberalCourses;
    final currentLikedSet = _selectedTabIndex == 0 ? _likedMajorCourses : _likedLiberalCourses;
    final course = currentCourses[index];
    
    try {
      if (currentLikedSet.contains(index)) {
        // 찜 해제
        await _removeFromFavorites(course);
        setState(() {
          if (_selectedTabIndex == 0) {
            _likedMajorCourses.remove(index);
          } else {
            _likedLiberalCourses.remove(index);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('찜 목록에서 제거되었습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // 찜 추가
        await _addToFavorites(course);
        setState(() {
          if (_selectedTabIndex == 0) {
            _likedMajorCourses.add(index);
          } else {
            _likedLiberalCourses.add(index);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('찜 목록에 추가되었습니다!'),
            backgroundColor: Color(0xFF862CF9),
          ),
        );
      }
    } catch (e) {
      print('🔥 찜 기능 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Firebase에 찜 강의 추가
  Future<void> _addToFavorites(Map<String, dynamic> course) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return;

      // 강의 ID 생성 (과목명 + 교수명으로 고유 ID 생성)
      final lectureId = '${course['name']}_${course['professor']}'.replaceAll(' ', '_');
      
      // Firebase에 저장할 데이터 구조
      final favoriteData = {
        '과목명': course['name'],
        '교수명': course['professor'],
        '개설학과전공': course['department'] ?? '',
        '영역': course['area'] ?? '',
        '추천 이유': course['reasons'] ?? [],
        'addedAt': DateTime.now().toIso8601String(),
      };

      // favorites 컬렉션에 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .collection('favorites')
          .doc(lectureId)
          .set(favoriteData);

      print('🔥 찜 강의 저장 완료: $lectureId');
    } catch (e) {
      print('🔥 찜 강의 저장 실패: $e');
      rethrow;
    }
  }

  // Firebase에서 찜 강의 제거
  Future<void> _removeFromFavorites(Map<String, dynamic> course) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return;

      // 강의 ID 생성
      final lectureId = '${course['name']}_${course['professor']}'.replaceAll(' ', '_');
      
      // favorites 컬렉션에서 삭제
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .collection('favorites')
          .doc(lectureId)
          .delete();

      print('🔥 찜 강의 제거 완료: $lectureId');
    } catch (e) {
      print('🔥 찜 강의 제거 실패: $e');
      rethrow;
    }
  }

  void _saveCourses() {
    // 저장 기능 구현 (나중에 Firebase 연동)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('강의 리스트가 저장되었습니다!'),
        backgroundColor: Color(0xFF862CF9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCourses = _selectedTabIndex == 0 ? _majorCourses : _liberalCourses;
    final currentLikedSet = _selectedTabIndex == 0 ? _likedMajorCourses : _likedLiberalCourses;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 0;
                  });
                  _loadFavorites(); // 전공 탭으로 변경 시 찜 목록 다시 로드
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 0 
                        ? const Color(0xFF862CF9) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
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
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 1;
                  });
                  _loadFavorites(); // 교양 탭으로 변경 시 찜 목록 다시 로드
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 1 
                        ? const Color(0xFF862CF9) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
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
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: currentCourses.length,
              itemBuilder: (context, index) {
                final course = currentCourses[index];
                final isLiked = currentLikedSet.contains(index);
                
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
                                    course['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Pretendard',
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '교수명: ${course['professor'] as String}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Pretendard',
                                      color: Color(0xFF767676),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                                                     Wrap(
                                     spacing: 8,
                                     runSpacing: 4,
                                     children: [
                                       ...(course['reasons'] as List<String>).map((reason) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF9267FE),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            reason,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Pretendard',
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
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
                child: const Text(
                  '저장',
                  style: TextStyle(
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