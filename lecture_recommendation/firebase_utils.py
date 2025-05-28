# === Firebase 연동 유틸리티 (개발용 목업 포함) ===

# 추후에 주석 제거하고 사용:
# import firebase_admin
# from firebase_admin import credentials, firestore

# # Firebase 초기화
# cred = credentials.Certificate("firebase_service_account.json")
# firebase_admin.initialize_app(cred)
# db = firestore.client()

def fetch_user_input_from_firebase(user_id: str) -> dict:
    """
    사용자의 전공, 학년, 선호 정보 등을 Firebase Firestore에서 불러오는 함수
    - 추후 서비스 계정 키 연동 후 완성 예정
    """
    # TODO: 추후 Firebase Firestore에서 users/{user_id} 읽기
    # doc = db.collection("users").document(user_id).get()
    # if not doc.exists:
    #     raise ValueError("사용자 정보가 존재하지 않습니다.")
    # return doc.to_dict()

    # 지금은 목업 데이터 변환 (개발 중)
    if user_id == "user1":
        return {
            "전공": "AI융합학부",
            "학년": 1,
            "세부전공": "",
            "시험": "두 번",
            "과제": "있음",
            "조모임": "없음",
            "출결": "전자출결",
            "성적": "보통",
            "강의 시간": "풀강",
            "강의력": "좋음",
            "수업유형": "블렌디드",
            "캠퍼스": "수정",
            "평점": "4.3"
        }
    elif user_id == "user2":
        return {
            "전공": "컴퓨터공학과",
            "학년": 2,
            "세부전공": "",
            "시험": "없음",
            "과제": "없음",
            "조모임": "없음",
            "출결": "직접호명",
            "성적": "깐깐함",
            "강의 시간": "풀강",
            "강의력": "보통",
            "수업유형": "원격",
            "캠퍼스": "운정",
            "평점": "3.2"
        }
    else:
        return {
            "전공": "서비스디자인공학과",
            "학년": 3,
            "세부전공": "",
            "시험": "세 번",
            "과제": "있음",
            "조모임": "있음",
            "출결": "복합적",
            "성적": "너그러움",
            "강의 시간": "풀강",
            "강의력": "좋음",
            "수업유형": "일반",
            "캠퍼스": "수정",
            "평점": "4.7"
        }

def save_recommendation_to_firebase(user_id: str, result: dict) -> None:
    """
    Firebase에 추천 결과를 저장하는 함수
    (현재는 동작하지 않음)
    """
    # TODO: 추후 Firestore에 recommendations/{user_id} 문서로 저장
    # db.collection("recommendations").document(user_id).set(result)
    pass
