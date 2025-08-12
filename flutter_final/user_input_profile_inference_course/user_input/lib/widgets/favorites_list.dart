import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/firebase_service.dart';

class FavoritesList extends StatefulWidget {
  final String userId;
  final VoidCallback onCourseAdded;

  const FavoritesList({
    super.key,
    required this.userId,
    required this.onCourseAdded,
  });

  @override
  State<FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<FavoritesList> {
  List<Course> favoriteCourses = [];

  @override
  void initState() {
    super.initState();
    _loadFavoritesFromFirebase();
  }

  // Firebase에서 찜한 강의 목록 로드
  Future<void> _loadFavoritesFromFirebase() async {
    try {
      print('🔥 [FavoritesList] Firebase에서 찜한 강의 로드 시작 - userId: ${widget.userId}');
      final favorites = await FirebaseService.getFavorites(widget.userId);
      print('🔥 [FavoritesList] Firebase에서 찜한 강의 로드 완료 - ${favorites.length}개');

      // 디버깅: 각 강의 정보 출력
      for (int i = 0; i < favorites.length; i++) {
        final course = favorites[i];
        print('🔥 [FavoritesList] 강의 ${i + 1}:');
        print('  - ID: ${course.id}');
        print('  - 과목명: ${course.subjectName}');
        print('  - 교수명: ${course.professorName}');
        print('  - 학과: ${course.department}');
        print('  - 영역: ${course.category}');
        print('  - 추천이유: ${course.recommendationReason is List ? course.recommendationReason.join(', ') : course.recommendationReason}');
      }

      setState(() {
        favoriteCourses = favorites;
      });
    } catch (e) {
      print('🔥 [FavoritesList] Firebase에서 찜한 강의 로드 실패: $e');
      // 오류 발생 시 빈 목록으로 설정
      setState(() {
        favoriteCourses = [];
      });
    }
  }

  Future<void> _addToSchedule(Course course) async {
    try {
      print('🔥 [FavoritesList] 시간표에 강의 추가 시작: ${course.subjectName}');
      final firebaseService = FirebaseService();
      await firebaseService.addToTimetable(course, userId: widget.userId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${course.subjectName}을(를) 시간표에 추가했습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      widget.onCourseAdded();
    } catch (e) {
      print('🔥 [FavoritesList] 시간표에 강의 추가 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('시간표 추가 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromSchedule(Course course) async {
    try {
      print('🔥 [FavoritesList] 찜 목록에서 강의 삭제 시작: ${course.subjectName}');
      final firebaseService = FirebaseService();
      await firebaseService.removeFromFavorites(course.id, course.subjectName);

      // 로컬 목록에서도 제거
      setState(() {
        favoriteCourses.removeWhere((c) => c.id == course.id);
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${course.subjectName}을(를) 찜 목록에서 삭제했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      widget.onCourseAdded();
    } catch (e) {
      print('🔥 [FavoritesList] 찜 목록에서 강의 삭제 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editCourseName(Course course, String newSubjectName) async {
    try {
      print('🔥 [FavoritesList] 과목명 수정 시작: ${course.subjectName} → $newSubjectName');
      final firebaseService = FirebaseService();

      // Course.id 대신 과목명과 교수명을 사용하여 문서를 찾기
      // 이렇게 하면 Firestore 문서 ID와 상관없이 올바른 문서를 찾을 수 있습니다
      await firebaseService.updateFavoriteCourseName(
          course.id, // courseId (사용되지 않을 수 있음)
          newSubjectName,
          course.subjectName // oldSubjectName
      );

      // 로컬 목록에서도 업데이트
      setState(() {
        final index = favoriteCourses.indexWhere((c) => c.id == course.id);
        if (index != -1) {
          // 기존 id를 유지하여 Firestore 문서 ID와의 연결을 보장
          favoriteCourses[index] = Course(
            id: course.id, // 기존 Firestore 문서 ID 유지
            subjectName: newSubjectName,
            professorName: course.professorName,
            department: course.department,
            category: course.category,
            recommendationReason: course.recommendationReason,
          );
        }
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('과목명이 "${newSubjectName}"으로 수정되었습니다.'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // 시간표 새로고침 (과목명 변경이 시간표에 반영되도록)
      widget.onCourseAdded();
    } catch (e) {
      print('🔥 [FavoritesList] 과목명 수정 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditDialog(Course course) {
    final controller = TextEditingController(text: course.subjectName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('과목명 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '새 과목명'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editCourseName(course, controller.text);
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (favoriteCourses.isEmpty) {
      return const Center(
        child: Text(
          '찜한 강의가 없습니다.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontFamily: 'GangwonEdu',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: favoriteCourses.length,
      itemBuilder: (context, index) {
        final course = favoriteCourses[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.subjectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'GangwonEdu',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => _showEditDialog(course),
                      tooltip: '과목명 수정',
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  course.professorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'GangwonEdu',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  course.department,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'GangwonEdu',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.green),
                onPressed: () => _addToSchedule(course),
                tooltip: '시간표에 추가',
              ),
            ],
          ),
        );
      },
    );
  }
}