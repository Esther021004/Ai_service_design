import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileInputPage extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onNext;
  
  const ProfileInputPage({
    Key? key, 
    this.isOnboarding = false,
    this.onNext,
  }) : super(key: key);

  @override
  State<ProfileInputPage> createState() => _ProfileInputPageState();
}

class _ProfileInputPageState extends State<ProfileInputPage> {
  final TextEditingController _nameController = TextEditingController();

  String? selectedCollege;
  String? selectedDepartment;
  String? selectedMajor;
  String? selectedGrade;

  // 저장 함수 추가
  Future<bool> saveProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.email)
          .set({
            'profile': {
              '이름': _nameController.text,
              '단과대학': selectedCollege,
              '전공': selectedDepartment,
              '세부전공': selectedMajor,
              '학년': selectedGrade != null ? int.tryParse(selectedGrade!.replaceAll(RegExp(r'[^0-9]'), '')) : null,
            }
          }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Firestore 저장 에러: $e');
      return false;
    }
  }

  final Map<String, Map<String, List<String>?>> collegeData = {
    '인문융합예술대학': {
      '국어국문학과': null,
      '영어영문학과': null,
      '독일어문ㆍ문화학과': null,
      '프랑스어문ㆍ문화학과': null,
      '일본어문ㆍ문화학과': null,
      '중국어문ㆍ문화학과': null,
      '사학과': null,
      '문화예술경영학과': null,
      '미디어영상연기학과': null,
      '현대실용음악학과': null,
      '무용예술학과': null,
    },
    '사회과학대학': {
      '정치외교학과': null,
      '심리학과': null,
      '지리학과': null,
      '경제학과': null,
      '경영학과': null,
      '미디어커뮤니케이션학과': null,
      '사회복지학과': null,
    },
    '법과대학': {
      '법학부': null,
    },
    '자연과학대학': {
      '수리통계데이터사이언스학부': ['수학', '통계학', '빅데이터사이언스', '핀테크'],
      '화학ㆍ에너지 융합학부': null,
      '바이오헬스융합학부': ['바이오헬스서비스', '식품영양학'],
    },
    '공과대학': {
      '서비스디자인공학과': null,
      '융합보안공학과': null,
      '컴퓨터공학과': null,
      '청정신소재공학과': null,
      '바이오식품공학과': null,
      '바이오생명공학과': null,
      '바이오신약의과학부': null,
      'AI융합학부': ['AI', '지능형IoT'],
    },
    '생활산업대학': {
      '의류산업학과': null,
      '소비자산업학과': null,
      '뷰티산업학과': null,
      '스포츠과학부': ['스포츠레저', '운동재활'],
    },
    '사법대학': {
      '교약학과': null,
      '사회교육과': null,
      '윤리교육과': null,
      '한문교육과': null,
      '유아교육과': null,
    },
    '미술대학': {
      '동양화과': null,
      '서양화과': null,
      '조소과': null,
      '공예과': null,
      '디자인과': null,
    },
    '음악대학': {
      '성악과': null,
      '기악과': null,
      '작곡과': null,
    },
    '창의융합대학': {},
    '간호대학': {
      '간호학과': null,
    },
  };

  List<String> get collegeList => collegeData.keys.toList();
  List<String> get departmentList =>
      selectedCollege != null ? collegeData[selectedCollege!]!.keys.toList() : [];
  List<String>? get majorList =>
      (selectedCollege != null && selectedDepartment != null)
          ? collegeData[selectedCollege!]![selectedDepartment!]
          : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. 보라색 배경
          Container(
            height: 300,
            color: const Color(0xFF862CF9),
          ),
          // 2. 흰색 둥근 박스 (보라색 위에)
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 140),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(48),
              ),
              child: SingleChildScrollView(  
              child: Column(
                children: [
                  const SizedBox(height: 100), // 프로필 사진 공간 더 확보
                  // 4. 입력 내용
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        fontFamily: 'GangwonEdu',
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '이름',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: '단과대학',
                    value: selectedCollege,
                    items: collegeList,
                    onChanged: (val) {
                      setState(() {
                        selectedCollege = val;
                        selectedDepartment = null;
                        selectedMajor = null;
                      });
                    },
                  ),
                  _buildDropdown(
                    label: '학과',
                    value: selectedDepartment,
                    items: departmentList,
                    onChanged: (val) {
                      setState(() {
                        selectedDepartment = val;
                        selectedMajor = null;
                      });
                    },
                  ),
                  if (majorList != null)
                    _buildDropdown(
                      label: '세부전공',
                      value: selectedMajor,
                      items: majorList!,
                      onChanged: (val) {
                        setState(() {
                          selectedMajor = val;
                        });
                      },
                    ),
                  _buildDropdown(
                    label: '학년',
                    value: selectedGrade,
                    items: ['1학년', '2학년', '3학년', '4학년'],
                    onChanged: (val) {
                      setState(() {
                        selectedGrade = val;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          ),
          // 3. 프로필 사진 (흰색 박스 위에 겹치게)
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Center(
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white,
                child: Image.asset(
                  'assets/mascot_remove.png',
                  width: 150,
                  height: 150,
                ),
              ),
            ),
          ),
          // Your Profile 텍스트
          Positioned(
            left: 24,
            top: 32,
            child: Text(
              'Your Profile',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'GangwonEdu',
              ),
            ),
          ),
        ],
      ),
      // 버튼 설정: 온보딩일 때는 "다음", 기존 사용자일 때는 "저장"
      bottomNavigationBar: widget.isOnboarding
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await saveProfile();
                      if (mounted) {
                        // onNext 콜백이 있으면 호출, 없으면 기본 동작
                        if (widget.onNext != null) {
                          widget.onNext!();
                        } else {
                          Navigator.of(context).pop('next');
                        }
                      }
                    } catch (e) {
                      print('Firestore 저장 에러: $e');
                    }
                  },
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text('다음', style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF862CF9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await saveProfile();
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      print('Firestore 저장 에러: $e');
                    }
                  },
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('저장', style: TextStyle(color: Colors.white, fontSize: 16)),
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontFamily: 'GangwonEdu',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          color: Colors.black,
        ),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontFamily: 'Pretendard')),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
} 