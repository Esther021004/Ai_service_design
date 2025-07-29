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

# 학기별 강의 정보를 previous_courses 맵 필드로 저장
def save_courses_by_semester(user_id, semester, courses):
    user_ref = db.collection("users").document(user_id)
    user_doc = user_ref.get()
    
    previous_data = user_doc.to_dict().get("previous_courses", {}) if user_doc.exists else {}

    # 새 학기 데이터 병합 (중복 제거)
    updated_semester_courses = previous_data.get(semester, {})
    for idx, course in enumerate(courses):
        course_key = f"course{idx+1}"
        updated_semester_courses[course_key] = {
            "과목명": course.get("과목명"),
            "교수명": course.get("교수명")
        }

    previous_data[semester] = updated_semester_courses

    user_ref.set({
        "previous_courses": previous_data
    }, merge=True)
    
    # 또는 문서가 없을 수도 있을 때:
    if not user_ref.get().exists:
        user_ref.set({"previous_courses": previous_data}, merge=True)
    else:
        user_ref.update({"previous_courses": previous_data})


def update_course_metadata_by_semester(user_id, semester, course_name, professor, category, credit):
    user_ref = db.collection("users").document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        return False

    previous_data = user_doc.to_dict().get("previous_courses", {})
    semester_courses = previous_data.get(semester, {})

    found = False
    for key, course in semester_courses.items():
        if course.get("과목명") == course_name and course.get("교수명") == professor:
            course["이수구분"] = category
            course["학점"] = credit
            found = True
            break

    if found:
        previous_data[semester] = semester_courses
        user_ref.update({
            "previous_courses": previous_data
        })
        return True
    return False


# 전체 강의 불러오기 (모든 학기의 course들 평탄화)
def get_all_courses(user_id):
    user_ref = db.collection("users").document(user_id).get()
    if not user_ref.exists:
        return []
    
    all_data = user_ref.to_dict().get("previous_courses", {})
    all_courses = []
    for semester, courses in all_data.items():
        for key in courses:
            all_courses.append(courses[key])
    return all_courses


def save_credit_summary(user_id, summary):
    user_ref = db.collection("users").document(user_id)
    summary_ref = user_ref.collection("credit_summary").document("summary")
    
    # timestamp 필드 추가
    summary["updated_at"] = datetime.utcnow()
    
    summary_ref.set(summary)
