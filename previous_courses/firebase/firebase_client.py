# firebase/firebase_client.py

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Firebase 초기화 (이미 초기화된 경우 생략 방지)
if not firebase_admin._apps:
    cred = credentials.Certificate("/etc/secrets/firebase_key.json")  # Render 배포 시 Secret으로 처리됨
    firebase_admin.initialize_app(cred)

db = firestore.client()

# 사용자의 schedule_links 전체 불러오기
def fetch_schedule_links(user_id):
    user_doc = db.collection("users").document(user_id).get()
    if user_doc.exists:
        return user_doc.to_dict().get("schedule_links", {})
    return {}

# 특정 사용자에 대해 강의 정보를 서브컬렉션(previous_courses)에 저장하기
def save_courses_to_subcollection(user_id, courses):
    user_ref = db.collection("users").document(user_id)
    subcol_ref = user_ref.collection("previous_courses")

    # 중복 저장 방지를 위해 기존 course (과목명+교수명 기준) 먼저 조회
    existing_courses = [(doc.to_dict().get("과목명"), doc.to_dict().get("교수명")) for doc in subcol_ref.stream()]
    
    for course in courses:
        # 리스트 또는 튜플 형식인 경우 처리
        if isinstance(course, (list, tuple)) and len(course) >= 2:
            course_name, professor = course[0], course[1]
        # 딕셔너리 형식인 경우 처리
        elif isinstance(course, dict):
            course_name = course.get("과목명")
            professor = course.get("교수명")
        else:
            print("❌ 예상치 못한 형식:", course)
            continue

        if (course_name, professor) not in existing_courses:
            subcol_ref.add({
                "과목명": course_name,
                "교수명": professor
            })


# 🔹 특정 강의(과목명 + 교수명 일치)에 대해 이수구분 및 학점 업데이트
def update_course_with_metadata(user_id, course_name, professor_name, category, credit):
    subcol_ref = db.collection("users").document(user_id).collection("previous_courses")
    docs = subcol_ref.stream()
    
    for doc in docs:
        data = doc.to_dict()
        if data.get("과목명") == course_name and data.get("교수명") == professor_name:
            subcol_ref.document(doc.id).update({
                "이수구분": category,
                "학점": credit
            })
            return True  # 업데이트 성공
    return False  # 해당 강의 없음

# 전체 강의 불러오기 (이수구분, 학점 계산용)
def get_all_courses(user_id):
    subcol_ref = db.collection("users").document(user_id).collection("previous_courses")
    return [doc.to_dict() for doc in subcol_ref.stream()]


def save_credit_summary(user_id, summary):
    user_ref = db.collection("users").document(user_id)
    summary_ref = user_ref.collection("credit_summary").document("summary")
    
    # timestamp 필드 추가
    summary["updated_at"] = datetime.utcnow()
    
    summary_ref.set(summary)
