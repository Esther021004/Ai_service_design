import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  static const String _previousCoursesBaseUrl = 'https://previous-courses.onrender.com';
  static const String _crawlingServerBaseUrl = 'https://crawling-server.onrender.com';
  static const String _recommendationBaseUrl = 'https://recommendation1-lrut.onrender.com';
  static const String _liberalRecommendationBaseUrl = 'https://recommendation2-3qsk.onrender.com';

  // 서버 깨우기
  static Future<bool> wakeUpCrawlingServer() async {
    try {
      print('🔥 Crawling server 깨우기 시도...');
      final response = await http.get(
        Uri.parse('$_crawlingServerBaseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15), // 타임아웃 설정
        onTimeout: () {
          print('🔥 Crawling server 깨우기 타임아웃');
          throw Exception('Request timeout');
        },
      );
      
      print('🔥 Crawling server 응답: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('🔥 Crawling server 깨우기 실패: $e');
      return false;
    }
  }

  // 강의 정보 저장
  static Future<Map<String, dynamic>?> saveCourses(String scheduleUrl, String semester) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없습니다.');
        return null;
      }

      print('🔥 강의 정보 저장 시도...');
      print('🔥 사용자: ${user!.email}');
      print('🔥 스케줄 URL: $scheduleUrl');
      print('🔥 학기: $semester');

      final response = await http.post(
        Uri.parse('$_previousCoursesBaseUrl/save-courses-by-semester'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.email,
          'schedule_url': scheduleUrl,
          'semester': semester,
        }),
      );

      print('🔥 저장 응답: ${response.statusCode}');
      print('🔥 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔥 저장 성공: $responseData');
        
        // API 응답을 Firebase에 저장
        await _saveToFirebase(responseData, semester);
        
        // 추출된 강의 데이터 반환
        return responseData;
      } else {
        print('🔥 저장 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('🔥 강의 정보 저장 중 에러: $e');
      return null;
    }
  }
  
  // API 응답을 Firebase에 저장 (서브컬렉션 방식)
  static Future<void> _saveToFirebase(Map<String, dynamic> responseData, String semester) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return;
      
      print('🔥 Firebase에 강의 데이터 저장 시작...');
      print('🔥 학기: $semester');
      
      // 새로운 강의 데이터를 서브컬렉션에 저장
      final courses = responseData['courses'] as List<dynamic>?;
      if (courses != null) {
        // 새로운 강의들을 서브컬렉션에 추가 (기존 강의 삭제하지 않음)
        for (var course in courses) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.email)
              .collection('previous_courses')
              .add({
            '과목명': course['과목명'],
            '교수명': course['교수명'],
            '이수구분': '전공', // 기본값
            '학점': 3, // 기본값
            'semester': semester, // 학기 정보 추가
          });
        }
        
        print('🔥 Firebase에 ${courses.length}개 강의 저장 완료');
      }
    } catch (e) {
      print('🔥 Firebase 저장 실패: $e');
    }
  }
  
  // 강의 정보 업데이트
  static Future<bool> updateCourseInfo(List<Map<String, dynamic>> courses, String semester) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없습니다.');
        return false;
      }

      print('🔥 강의 정보 업데이트 시도...');
      print('🔥 사용자: ${user!.email}');
      print('🔥 학기: $semester');
      print('🔥 강의 목록: $courses');

      // API 요구사항에 맞게 필드명 변환
      List<Map<String, dynamic>> convertedCourses = courses.map((course) {
        return {
          'course_name': course['과목명'],
          'professor_name': course['교수명'],
          'category': course['이수구분'],
          'credit': course['학점'],
        };
      }).toList();

      print('🔥 변환된 강의 목록: $convertedCourses');

      // 각 강의를 개별적으로 업데이트
      bool allSuccess = true;
      
      for (var course in convertedCourses) {
        final response = await http.post(
          Uri.parse('$_previousCoursesBaseUrl/update-course-info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': user.email,
            'semester': semester,
            'course_name': course['course_name'],
            'professor_name': course['professor_name'],
            'category': course['category'],
            'credit': course['credit'],
          }),
        );

        print('🔥 개별 강의 업데이트 응답: ${response.statusCode}');
        print('🔥 응답 내용: ${response.body}');

        if (response.statusCode != 200) {
          print('🔥 개별 강의 업데이트 실패: ${response.statusCode} - ${response.body}');
          allSuccess = false;
        }
      }

      if (allSuccess) {
        print('🔥 모든 강의 업데이트 성공');
        return true;
      } else {
        print('🔥 일부 강의 업데이트 실패');
        return false;
      }
    } catch (e) {
      print('🔥 강의 정보 업데이트 중 에러: $e');
      return false;
    }
  }

  // 학점 비율 계산
  static Future<Map<String, dynamic>?> calculateCreditRatio() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없습니다.');
        return _getDefaultCreditData();
      }

      print('🔥 학점 비율 계산 시도...');
      print('🔥 사용자: ${user!.email}');

      // 타임아웃 설정 (10초)
      final response = await http.post(
        Uri.parse('$_previousCoursesBaseUrl/calculate-credit-ratio'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.email,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('🔥 학점 비율 계산 타임아웃');
          throw Exception('Request timeout');
        },
      );

      print('🔥 계산 응답: ${response.statusCode}');
      print('🔥 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔥 계산 성공: $responseData');
        return responseData;
      } else if (response.statusCode == 500) {
        print('🔥 서버 내부 오류 (500) - 기본값 반환');
        return _getDefaultCreditData();
      } else {
        print('🔥 계산 실패: ${response.statusCode} - ${response.body}');
        return _getDefaultCreditData();
      }
    } catch (e) {
      print('🔥 학점 비율 계산 중 에러: $e');
      return _getDefaultCreditData();
    }
  }

  // 기본 학점 데이터 반환
  static Map<String, dynamic> _getDefaultCreditData() {
    return {
      '전체 학점': 130,
      '전공': 0,
      '교양': 0,
      '교직': 0,
    };
  }

  // 강의 추천 요청
  static Future<Map<String, dynamic>?> getCourseRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없습니다.');
        return null;
      }

      print('🔥 강의 추천 요청 시도...');
      print('🔥 사용자: ${user!.email}');

      // 먼저 서버 상태 확인
      try {
        final healthCheck = await http.get(
          Uri.parse('$_recommendationBaseUrl/'),
          headers: {'Content-Type': 'application/json'},
        );
        print('🔥 서버 상태 확인: ${healthCheck.statusCode}');
      } catch (e) {
        print('🔥 서버 상태 확인 실패: $e');
      }

      // 요청 데이터 로깅
      final requestBody = jsonEncode({
        'user_id': user.email,
      });
      print('🔥 요청 URL: $_recommendationBaseUrl/recommend/');
      print('🔥 요청 데이터: $requestBody');
      
      final response = await http.post(
        Uri.parse('$_recommendationBaseUrl/recommend/'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('🔥 추천 응답: ${response.statusCode}');
      print('🔥 응답 내용: ${response.body}');
      print('🔥 응답 헤더: ${response.headers}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔥 추천 성공: $responseData');
        
        // 실제 추천 데이터가 있는지 확인
        if (responseData.containsKey('recommendations') && responseData['recommendations'] is List) {
          print('🔥 추천 데이터 발견: ${responseData['recommendations'].length}개 강의');
          // 추천 결과를 Firebase에 저장
          await _saveRecommendationsToFirebase(responseData);
          return responseData;
        } else {
          print('🔥 실제 추천 데이터가 없습니다. 헬로 메시지만 받음.');
          return null;
        }
      } else {
        print('🔥 추천 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('🔥 강의 추천 중 에러: $e');
      return null;
    }
  }

  // 추천 결과를 Firebase에 저장
  static Future<void> _saveRecommendationsToFirebase(Map<String, dynamic> responseData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return;
      
      print('🔥 Firebase에 추천 데이터 저장 시작...');
      
      final timestamp = DateTime.now();
      final recommendationId = timestamp.toIso8601String();
      
      // 추천 결과를 Firebase에 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .collection('results')
          .doc(recommendationId)
          .set({
        'createdAt': recommendationId,
        'majorRecommendations': responseData['recommendations'] ?? [],
      });
      
      print('🔥 Firebase에 추천 데이터 저장 완료: $recommendationId');
    } catch (e) {
      print('🔥 Firebase 추천 데이터 저장 실패: $e');
    }
  }

  // 사용자의 추천 내역 가져오기
  static Future<List<Map<String, dynamic>>> getUserRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없습니다.');
        return [];
      }

      print('🔥 사용자 추천 내역 조회 시도...');
      print('🔥 사용자: ${user!.email}');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('results')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> recommendations = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        recommendations.add({
          'id': doc.id,
          'createdAt': data['createdAt'],
          'majorRecommendations': data['majorRecommendations'] ?? [],
        });
      }

      print('🔥 추천 내역 조회 성공: ${recommendations.length}개');
      return recommendations;
    } catch (e) {
      print('🔥 추천 내역 조회 중 에러: $e');
      return [];
    }
  }

  // 교양 강의 추천 요청
  static Future<Map<String, dynamic>?> getLiberalCourseRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없습니다.');
        return null;
      }

      print('🔥 교양 강의 추천 요청 시도...');
      print('🔥 사용자: ${user!.email}');

      // 먼저 서버 상태 확인
      try {
        final healthCheck = await http.get(
          Uri.parse('$_liberalRecommendationBaseUrl/'),
          headers: {'Content-Type': 'application/json'},
        );
        print('🔥 교양 서버 상태 확인: ${healthCheck.statusCode}');
      } catch (e) {
        print('🔥 교양 서버 상태 확인 실패: $e');
      }

      final response = await http.post(
        Uri.parse('$_liberalRecommendationBaseUrl/recommend/liberal-career'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.email,
          'doc_id': 'liberal_career_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      print('🔥 교양 추천 응답: ${response.statusCode}');
      print('🔥 응답 내용: ${response.body}');
      print('🔥 교양 응답 헤더: ${response.headers}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔥 교양 추천 성공: $responseData');
        
        // 실제 추천 데이터가 있는지 확인
        if (responseData.containsKey('liberal_recommendations') || responseData.containsKey('career_recommendations')) {
          // 교양 추천 결과를 Firebase에 저장
          await _saveLiberalRecommendationsToFirebase(responseData);
          return responseData;
        } else {
          print('🔥 실제 교양 추천 데이터가 없습니다. 헬로 메시지만 받음.');
          return null;
        }
      } else {
        print('🔥 교양 추천 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('🔥 교양 강의 추천 중 에러: $e');
      return null;
    }
  }

  // 교양 추천 결과를 Firebase에 저장
  static Future<void> _saveLiberalRecommendationsToFirebase(Map<String, dynamic> responseData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return;
      
      print('🔥 Firebase에 교양 추천 데이터 저장 시작...');
      
      final timestamp = DateTime.now();
      final recommendationId = 'liberal_recommendation_${timestamp.millisecondsSinceEpoch}';
      
      // 교양 추천 결과를 Firebase에 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .collection('liberal_recommendations')
          .doc(recommendationId)
          .set({
        'timestamp': timestamp,
        'recommendations': responseData,
        'status': 'active',
      });
      
      print('🔥 Firebase에 교양 추천 데이터 저장 완료');
    } catch (e) {
      print('🔥 Firebase 교양 추천 데이터 저장 실패: $e');
    }
  }

  // 사용자의 교양 추천 내역 가져오기
  static Future<List<Map<String, dynamic>>> getUserLiberalRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('🔥 사용자 이메일이 없습니다.');
        return [];
      }

      print('🔥 사용자 교양 추천 내역 조회 시도...');
      print('🔥 사용자: ${user!.email}');

      // 인덱스 오류 방지를 위해 orderBy 제거하고 클라이언트에서 정렬
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('liberal_recommendations')
          .where('status', isEqualTo: 'active')
          .get();

      List<Map<String, dynamic>> recommendations = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        // timestamp가 null인 경우 처리
        if (data['timestamp'] != null) {
          recommendations.add({
            'id': doc.id,
            'timestamp': data['timestamp'],
            'recommendations': data['recommendations'],
          });
        }
      }

      // 클라이언트에서 timestamp 기준으로 정렬
      recommendations.sort((a, b) {
        final timestampA = a['timestamp'] as Timestamp;
        final timestampB = b['timestamp'] as Timestamp;
        return timestampB.compareTo(timestampA); // 내림차순 정렬
      });

      print('🔥 교양 추천 내역 조회 성공: ${recommendations.length}개');
      return recommendations;
    } catch (e) {
      print('🔥 교양 추천 내역 조회 중 에러: $e');
      return [];
    }
  }

  // 사용자의 강의 데이터 존재 여부 확인
  static Future<Map<String, dynamic>> checkUserDataStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        return {'error': '사용자 이메일이 없습니다.'};
      }

      print('🔥 사용자 데이터 상태 확인: ${user!.email}');
      
      Map<String, dynamic> status = {};
      
      // 1. 스케줄 링크 확인
      try {
        final scheduleDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .get();
        
        if (scheduleDoc.exists && scheduleDoc.data()!.containsKey('schedule_links')) {
          final scheduleLinks = scheduleDoc.data()!['schedule_links'] as Map<String, dynamic>;
          status['schedule_links'] = {
            'exists': true,
            'count': scheduleLinks.length,
            'semesters': scheduleLinks.keys.toList(),
          };
        } else {
          status['schedule_links'] = {'exists': false};
        }
      } catch (e) {
        status['schedule_links'] = {'exists': false, 'error': e.toString()};
      }
      
      // 2. 이전 강의 데이터 확인
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .get();
        
        if (userDoc.exists && userDoc.data()!.containsKey('previous_courses')) {
          final previousCourses = userDoc.data()!['previous_courses'] as Map<String, dynamic>;
          int totalCourses = 0;
          
          // 모든 학기의 강의 수 계산
          previousCourses.forEach((semester, courses) {
            if (courses is List) {
              totalCourses += courses.length;
            }
          });
          
          status['previous_courses'] = {
            'exists': true,
            'count': totalCourses,
            'semesters': previousCourses.keys.toList(),
          };
        } else {
          status['previous_courses'] = {'exists': false};
        }
      } catch (e) {
        status['previous_courses'] = {'exists': false, 'error': e.toString()};
      }
      
      // 3. API 서버에서 사용자 데이터 확인
      try {
        final response = await http.post(
          Uri.parse('$_previousCoursesBaseUrl/check-user-data'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': user.email}),
        );
        
        if (response.statusCode == 200) {
          status['api_data'] = jsonDecode(response.body);
        } else {
          status['api_data'] = {'error': '${response.statusCode}: ${response.body}'};
        }
      } catch (e) {
        status['api_data'] = {'error': e.toString()};
      }
      
      print('🔥 사용자 데이터 상태: $status');
      return status;
    } catch (e) {
      print('🔥 사용자 데이터 상태 확인 중 에러: $e');
      return {'error': e.toString()};
    }
  }
} 