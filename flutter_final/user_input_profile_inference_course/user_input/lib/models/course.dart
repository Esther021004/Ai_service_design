import 'package:flutter/material.dart';

class Course {
  final String id;
  final String subjectName;
  final String professorName;
  final String department;
  final String? category;
  final dynamic recommendationReason; // List<dynamic> 또는 String 지원

  Course({
    required this.id,
    required this.subjectName,
    required this.professorName,
    required this.department,
    this.category,
    this.recommendationReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      '과목명': subjectName,
      '교수명': professorName,
      '개설학과전공': department,
      '영역': category,
      '추천 이유': recommendationReason,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] ?? '',
      // Firebase에서 가져온 한국어 필드명과 영어 필드명 모두 지원
      subjectName: map['과목명'] ?? map['subjectName'] ?? '',
      professorName: map['교수명'] ?? map['professorName'] ?? '',
      department: map['개설학과전공'] ?? map['department'] ?? '',
      category: map['영역'] ?? map['category'],
      recommendationReason: map['추천 이유'] ?? map['recommendationReason'],
    );
  }

  // 테스트용 샘플 데이터
  static List<Course> getTestCourses() {
    return [
      Course(
        id: '1',
        subjectName: '프로그래밍 기초',
        professorName: '김교수',
        department: '컴퓨터공학과',
        category: '전공필수',
        recommendationReason: '프로그래밍 입문자에게 추천',
      ),
      Course(
        id: '2',
        subjectName: '데이터구조',
        professorName: '이교수',
        department: '컴퓨터공학과',
        category: '전공필수',
        recommendationReason: '알고리즘 학습의 기초',
      ),
      Course(
        id: '3',
        subjectName: '웹프로그래밍',
        professorName: '박교수',
        department: '소프트웨어학과',
        category: '전공선택',
        recommendationReason: '실무에 바로 적용 가능',
      ),
    ];
  }
} 