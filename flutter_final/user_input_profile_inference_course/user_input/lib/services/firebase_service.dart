import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/fastapi_service.dart'; // FastAPIService 추가

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 찜해둔 강의 목록 가져오기 (userId 파라미터 추가)
  static Future<List<Course>> getFavorites(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();

    return snapshot.docs
        .map((doc) => Course.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // 찜해둔 강의 추가
  Future<void> addToFavorites(Course course) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      // FastAPI와 호환되도록 users/{user_id}/favorites 경로에 저장
      await _firestore
          .collection('users')
          .doc(user!.email)
          .collection('favorites')
          .add(course.toMap());

      print('🔥 [FirebaseService] 찜 강의 추가 완료: ${course.subjectName}');
    } catch (e) {
      print('🔥 [FirebaseService] 찜 강의 추가 실패: $e');
      rethrow;
    }
  }

  // 찜해둔 강의 삭제
  Future<void> removeFromFavorites(String courseId, String subjectName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      await _firestore
          .collection('users')
          .doc(user!.email)
          .collection('favorites')
          .doc(courseId)
          .delete();

      print('🔥 [FirebaseService] favorites 컬렉션에서 삭제 완료');

      // timetable 컬렉션에서도 같은 강의를 삭제
      final timetableQuery = await _firestore
          .collection('timetable')
          .where('subjectName', isEqualTo: subjectName)
          .get();

      for (var doc in timetableQuery.docs) {
        await _firestore.collection('timetable').doc(doc.id).delete();
      }

      print('🔥 [FirebaseService] timetable 컬렉션에서 삭제 완료');
    } catch (e) {
      print('🔥 [FirebaseService] 찜 강의 삭제 실패: $e');
      rethrow;
    }
  }

  // 찜해둔 강의의 과목명 수정
  Future<void> updateFavoriteCourseName(String courseId, String newSubjectName, String oldSubjectName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      print('🔥 [FirebaseService] 과목명 수정 시작');
      print('🔥 [FirebaseService] courseId: $courseId');
      print('🔥 [FirebaseService] oldSubjectName: $oldSubjectName');
      print('🔥 [FirebaseService] newSubjectName: $newSubjectName');
      print('🔥 [FirebaseService] user.email: ${user!.email}');

      // courseId가 실제 문서 ID인지 확인하고, 아니라면 과목명으로 문서를 찾기
      DocumentReference? docRef;

      try {
        // 먼저 courseId로 직접 시도
        docRef = _firestore
            .collection('users')
            .doc(user.email)
            .collection('favorites')
            .doc(courseId);

        final doc = await docRef.get();
        if (doc.exists) {
          print('🔥 [FirebaseService] courseId로 문서 찾음: $courseId');
        } else {
          // courseId로 찾을 수 없으면, 과목명으로 문서를 찾기
          print('🔥 [FirebaseService] courseId로 문서를 찾을 수 없음: $courseId');
          print('🔥 [FirebaseService] 과목명으로 문서 검색 시도: $oldSubjectName');

          // 과목명으로 문서를 찾기
          final querySnapshot = await _firestore
              .collection('users')
              .doc(user.email)
              .collection('favorites')
              .where('과목명', isEqualTo: oldSubjectName)
              .get();

          if (querySnapshot.docs.isEmpty) {
            throw Exception('수정할 강의를 찾을 수 없습니다: $oldSubjectName');
          }

          // 첫 번째 문서 사용
          docRef = querySnapshot.docs.first.reference;
          print('🔥 [FirebaseService] 과목명으로 문서 찾음: ${docRef.id}');
        }
      } catch (e) {
        print('🔥 [FirebaseService] 문서 검색 중 오류: $e');
        rethrow;
      }

      // 문서 업데이트
      await docRef!.update({
        '과목명': newSubjectName,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('🔥 [FirebaseService] favorites 컬렉션 업데이트 완료');

      // 1. Firebase timetable 컬렉션에서도 같은 강의의 과목명을 수정
      final timetableQuery = await _firestore
          .collection('timetable')
          .where('과목명', isEqualTo: oldSubjectName)
          .get();

      for (var doc in timetableQuery.docs) {
        await _firestore
            .collection('timetable')
            .doc(doc.id)
            .update({'과목명': newSubjectName});
      }

      print('🔥 [FirebaseService] Firebase timetable 컬렉션 업데이트 완료');

      // 2. FastAPI 서버에도 과목명 수정 요청 (실제 시간표에 반영)
      try {
        print('🔥 [FirebaseService] FastAPI 서버에 과목명 수정 요청 시작');

        // 교수명 정보 가져오기 (docRef에서 데이터 가져오기)
        final courseData = await docRef!.get();
        final professorName = (courseData.data() as Map<String, dynamic>?)?['교수명'] ?? '';

        print('🔥 [FirebaseService] 교수명: $professorName');

        // FastAPI 서비스의 updateSchedule 메서드 사용
        await FastAPIService.updateSchedule(
          user.email!,        // user_id
          oldSubjectName,     // 과목명 (기존)
          professorName,      // 교수명
          newSubjectName,     // 새로운_과목명
        );

        print('🔥 [FirebaseService] FastAPI 서버 과목명 수정 완료');
      } catch (e) {
        print('🔥 [FirebaseService] FastAPI 서버 과목명 수정 중 오류: $e');
        // FastAPI 실패해도 Firebase는 성공했으므로 경고만 출력
      }

      print('🔥 [FirebaseService] 과목명 수정 완료');
    } catch (e) {
      print('🔥 [FirebaseService] 과목명 수정 실패: $e');
      rethrow;
    }
  }

  // 시간표 데이터 가져오기 (userId 파라미터 추가)
  static Future<List<Map<String, dynamic>>> getTimetable(String userId) async {
    print('🔥 [API] 시간표 데이터 요청 시작 - userId: $userId');
    print('🔥 [API] 요청 URL: https://course-schduler.onrender.com/schedule/$userId');

    try {
      final firestore = FirebaseFirestore.instance;
      print('🔥 [API] HTTP GET 요청 전송 중...');

      // 타임아웃 설정 (10초)
      final client = http.Client();
      final response = await client.get(
        Uri.parse('https://course-schduler.onrender.com/schedule/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('🔥 [API] 요청 타임아웃 (10초)');
          throw Exception('Request timeout after 10 seconds');
        },
      );

      print('🔥 [API] 응답 상태 코드: ${response.statusCode}');
      print('🔥 [API] 응답 헤더: ${response.headers}');
      print('🔥 [API] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // 실제 API 응답에서 'schedule' 필드 사용
        final courses = List<Map<String, dynamic>>.from(data['schedule'] ?? []);
        print('🔥 [API] 시간표 데이터 로드 성공 - ${courses.length}개 강의');
        return courses;
      } else {
        print('🔥 [API] 시간표 데이터 로드 실패 - 상태 코드: ${response.statusCode}');
        throw Exception('Failed to load timetable: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 [API] 시간표 데이터 로드 중 오류 발생: $e');
      print('🔥 [API] 오류 타입: ${e.runtimeType}');
      throw Exception('Failed to connect to server: $e');
    }
  }

  // 시간표에 강의 추가 (FastAPI 서버와 연동)
  Future<void> addToTimetable(Course course, {String? userId}) async {
    print('🔥 [FirebaseService] 시간표에 강의 추가 시작: ${course.subjectName}');

    try {
      // 1. Firebase timetable 컬렉션에 추가
      await _firestore.collection('timetable').add(course.toMap());
      print('🔥 [FirebaseService] Firebase timetable에 추가 완료');

      // 2. FastAPI 서버에도 추가 (userId가 제공된 경우)
      if (userId != null) {
        print('🔥 [FirebaseService] FastAPI 서버에 추가 시도 - userId: $userId');
        final client = http.Client();
        final response = await client.post(
          Uri.parse('https://course-schduler.onrender.com/schedule/add'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': userId,
            '과목명': course.subjectName,
            '교수명': course.professorName,
          }),
        ).timeout(const Duration(seconds: 10));

        print('🔥 [FirebaseService] FastAPI 응답 상태: ${response.statusCode}');
        print('🔥 [FirebaseService] FastAPI 응답: ${response.body}');

        if (response.statusCode == 200) {
          print('🔥 [FirebaseService] FastAPI 서버에 추가 완료');
        } else {
          print('🔥 [FirebaseService] FastAPI 서버 추가 실패: ${response.statusCode}');
        }
      }

      print('🔥 [FirebaseService] 시간표에 강의 추가 완료: ${course.subjectName}');
    } catch (e) {
      print('🔥 [FirebaseService] 시간표에 강의 추가 실패: $e');
      throw Exception('Failed to add course to timetable: $e');
    }
  }

  // 시간표에서 강의 삭제
  Future<void> removeFromTimetable(String courseId) async {
    await _firestore.collection('timetable').doc(courseId).delete();
  }

  // 시간표에서 특정 강의 삭제 (과목명과 교수명으로 식별)
  static Future<void> deleteCourseFromSchedule(String userId, Map<String, dynamic> course) async {
    print('🔥 [FirebaseService] 시간표에서 강의 삭제 시작: ${course['과목명']}');

    try {
      // FastAPI 서버에 삭제 요청
      final client = http.Client();
      final response = await client.delete(
        Uri.parse('https://course-schduler.onrender.com/schedule/delete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          '과목명': course['과목명'],
          '교수명': course['교수명'],
        }),
      ).timeout(const Duration(seconds: 10));

      print('🔥 [FirebaseService] FastAPI 삭제 응답 상태: ${response.statusCode}');
      print('🔥 [FirebaseService] FastAPI 삭제 응답: ${response.body}');

      if (response.statusCode == 200) {
        print('🔥 [FirebaseService] FastAPI 서버에서 강의 삭제 완료');
      } else {
        print('🔥 [FirebaseService] FastAPI 서버 삭제 실패: ${response.statusCode}');
        throw Exception('Failed to delete course from server: ${response.statusCode}');
      }

      print('🔥 [FirebaseService] 시간표에서 강의 삭제 완료: ${course['과목명']}');
    } catch (e) {
      print('🔥 [FirebaseService] 시간표에서 강의 삭제 실패: $e');
      throw Exception('Failed to delete course from schedule: $e');
    }
  }

  // 시간표 초기화 (모든 강의 삭제)
  Future<void> resetTimetable() async {
    final timetableQuery = await _firestore.collection('timetable').get();

    for (var doc in timetableQuery.docs) {
      await _firestore.collection('timetable').doc(doc.id).delete();
    }
  }

  // Firebase 클라이언트 접근자
  FirebaseFirestore get firestore => _firestore;
} 