import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/course.dart';

class FastAPIService {
  // FastAPI 서버의 기본 URL (실제 서버 주소로 변경 필요)
  static const String baseUrl = 'https://course-schduler.onrender.com'; // 또는 실제 서버 주소

  // HTTP 헤더
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // 사용자 시간표 가져오기
  static Future<Map<String, dynamic>> getSchedule(String userId) async {
    print('🔥 [FastAPI] 시간표 스케줄 요청 시작 - userId: $userId');
    print('🔥 [FastAPI] 요청 URL: $baseUrl/schedule/$userId');
    
    try {
      print('🔥 [FastAPI] HTTP GET 요청 전송 중...');
      final response = await http.get(
        Uri.parse('$baseUrl/schedule/$userId'),
        headers: headers,
      );

      print('🔥 [FastAPI] 응답 상태 코드: ${response.statusCode}');
      print('🔥 [FastAPI] 응답 헤더: ${response.headers}');
      print('🔥 [FastAPI] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔥 [FastAPI] 시간표 스케줄 로드 성공');
        return data;
      } else {
        print('🔥 [FastAPI] 시간표 스케줄 로드 실패 - 상태 코드: ${response.statusCode}');
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 [FastAPI] 시간표 스케줄 로드 중 오류 발생: $e');
      print('🔥 [FastAPI] 오류 타입: ${e.runtimeType}');
      throw Exception('Failed to connect to server: $e');
    }
  }

  // 시간표에 강의 추가
  static Future<Map<String, dynamic>> addSchedule(String userId, String subject, String professor) async {
    print('🔥 [FastAPI] 시간표 강의 추가 요청 시작');
    print('🔥 [FastAPI] 요청 URL: $baseUrl/schedule/add');
    print('🔥 [FastAPI] 요청 데이터: {"user_id": "$userId", "과목명": "$subject", "교수명": "$professor"}');
    
    try {
        print('🔥 [FastAPI] HTTP POST 요청 전송 중...');
        final response = await http.post(
        Uri.parse('$baseUrl/schedule/add'),
        headers: headers,
        body: json.encode({
            'user_id': userId,
            '과목명': subject,
            '교수명': professor,
        }),
    );

        print('🔥 [FastAPI] 응답 상태 코드: ${response.statusCode}');
        print('🔥 [FastAPI] 응답 본문: ${response.body}');
        final responseData = json.decode(response.body);

        if (response.statusCode == 200) {
            print('🔥 [FastAPI] 시간표 강의 추가 성공');
            return responseData;
        } else {
            print('🔥 [FastAPI] 시간표 강의 추가 실패 - 상태 코드: ${response.statusCode}');
            return responseData;
        }
    } catch (e) {
        print('🔥 [FastAPI] 시간표 강의 추가 중 오류 발생: $e');
        print('🔥 [FastAPI] 오류 타입: ${e.runtimeType}');
        return {'detail': '서버 연결 실패: $e'};
    }
  }

  // 시간표에서 강의 삭제
  static Future<Map<String, dynamic>> deleteSchedule(String userId, String subject, String professor) async {
    print('🔥 [FastAPI] 시간표 강의 삭제 요청 시작');
    print('🔥 [FastAPI] 요청 URL: $baseUrl/schedule/delete');
    print('🔥 [FastAPI] 요청 데이터: {"user_id": "$userId", "과목명": "$subject", "교수명": "$professor"}');
    
    try {
      print('🔥 [FastAPI] HTTP DELETE 요청 전송 중...');
      final response = await http.delete(
        Uri.parse('$baseUrl/schedule/delete'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
          '과목명': subject,
          '교수명': professor,
        }),
      );

      print('🔥 [FastAPI] 응답 상태 코드: ${response.statusCode}');
      print('🔥 [FastAPI] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔥 [FastAPI] 시간표 강의 삭제 성공');
        return data;
      } else {
        final errorData = json.decode(response.body);
        print('🔥 [FastAPI] 시간표 강의 삭제 실패 - 상태 코드: ${response.statusCode}');
        throw Exception(errorData['detail'] ?? 'Failed to delete schedule');
      }
    } catch (e) {
      print('🔥 [FastAPI] 시간표 강의 삭제 중 오류 발생: $e');
      print('🔥 [FastAPI] 오류 타입: ${e.runtimeType}');
      throw Exception('Failed to connect to server: $e');
    }
  }

  // 시간표에서 과목명 수정
  static Future<Map<String, dynamic>> updateSchedule(
    String userId, 
    String subject, 
    String professor, 
    String newSubject
  ) async {
    print('🔥 [FastAPI] 시간표 과목명 수정 요청 시작');
    print('🔥 [FastAPI] 요청 URL: $baseUrl/schedule/update');
    print('🔥 [FastAPI] 요청 데이터: {"user_id": "$userId", "과목명": "$subject", "교수명": "$professor", "새로운_과목명": "$newSubject"}');
    
    try {
      print('🔥 [FastAPI] HTTP PUT 요청 전송 중...');
      final response = await http.put(
        Uri.parse('$baseUrl/schedule/update'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
          '과목명': subject,
          '교수명': professor,
          '새로운_과목명': newSubject,
        }),
      );

      print('🔥 [FastAPI] 응답 상태 코드: ${response.statusCode}');
      print('🔥 [FastAPI] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔥 [FastAPI] 시간표 과목명 수정 성공');
        return data;
      } else {
        final errorData = json.decode(response.body);
        print('🔥 [FastAPI] 시간표 과목명 수정 실패 - 상태 코드: ${response.statusCode}');
        throw Exception(errorData['detail'] ?? 'Failed to update schedule');
      }
    } catch (e) {
      print('🔥 [FastAPI] 시간표 과목명 수정 중 오류 발생: $e');
      print('🔥 [FastAPI] 오류 타입: ${e.runtimeType}');
      throw Exception('Failed to connect to server: $e');
    }
  }

  // 시간표 초기화
  static Future<Map<String, dynamic>> resetSchedule(String userId) async {
    print('🔥 [FastAPI] 시간표 초기화 요청 시작');
    print('🔥 [FastAPI] 요청 URL: $baseUrl/schedule/reset');
    print('🔥 [FastAPI] 요청 데이터: {"user_id": "$userId"}');
    
    try {
      print('🔥 [FastAPI] HTTP POST 요청 전송 중...');
      final response = await http.post(
        Uri.parse('$baseUrl/schedule/reset'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
        }),
      );

      print('🔥 [FastAPI] 응답 상태 코드: ${response.statusCode}');
      print('🔥 [FastAPI] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔥 [FastAPI] 시간표 초기화 성공');
        return data;
      } else {
        final errorData = json.decode(response.body);
        print('🔥 [FastAPI] 시간표 초기화 실패 - 상태 코드: ${response.statusCode}');
        throw Exception(errorData['detail'] ?? 'Failed to reset schedule');
      }
    } catch (e) {
      print('🔥 [FastAPI] 시간표 초기화 중 오류 발생: $e');
      print('🔥 [FastAPI] 오류 타입: ${e.runtimeType}');
      throw Exception('Failed to connect to server: $e');
    }
  }
} 