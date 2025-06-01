import 'package:flutter/material.dart';
import '../services/firebase_service.dart'; // FirebaseService import

class ResultPage extends StatelessWidget {
  // Add FirebaseService instance and userId
  final String userId; // Assuming userId is passed to this page
  final FirebaseService _firebaseService = FirebaseService();

  const ResultPage({Key? key, required this.userId}) : super(key: key); // Update constructor to accept userId

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('추천 결과'),
        backgroundColor: Colors.purple,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _firebaseService.getRecommendationResult(userId), // Fetch data from Firebase
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }

          final recommendations = snapshot.data; // Get recommendation data
          if (recommendations == null) {
            return const Center(child: Text('추천 기록이 없습니다.'));
          }

          // Implement TabController and TabBarView
          return DefaultTabController(
            length: 3, // Number of tabs
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: '전공'),
                    Tab(text: '교양'),
                    Tab(text: '진로소양'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Content for '전공' tab
                      _buildCourseList(recommendations['전공'] ?? []),
                      // Content for '교양' tab
                      _buildCourseList(recommendations['교양'] ?? []),
                      // Content for '진로소양' tab
                      _buildCourseList(recommendations['진로소양'] ?? []),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to build a list of courses for a specific category
  Widget _buildCourseList(List<dynamic> courses) {
    if (courses.isEmpty) {
      return const Center(child: Text('해당 카테고리의 추천 강의가 없습니다.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['과목명'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('교수명: ${course['교수명'] ?? ''}'),
                Text('시간: ${course['시간표'] ?? ''}'),
                Text('캠퍼스: ${course['캠퍼스'] ?? ''}'),
                const SizedBox(height: 4),
                Text(
                  '추천 이유: ${course['추천 이유'] ?? ''}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                // Add a button for '선택' if needed, similar to the image
                // ElevatedButton(
                //   onPressed: () {
                //     // TODO: Implement select functionality
                //   },
                //   child: Text('선택'),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
} 