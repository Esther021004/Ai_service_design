import firebase_admin
from firebase_admin import credentials, firestore

# Firebase 초기화
cred = credentials.Certificate("firebase_key.json")  # 서비스 계정 키 json
firebase_admin.initialize_app(cred)
db = firestore.client()

# 사용자 정보 불러오기 (profile + preferences 포함)
def fetch_user_info(user_id):
    doc = db.collection("users").document(user_id).get()
    if doc.exists:
        return doc.to_dict()
    return None


# 추천 결과 저장 (liberal + career 추천 결과)
def save_recommendation_to_firebase(user_id, doc_id, liberal_results, career_results):
    result_ref = db.collection("users").document(user_id).collection("results").document(doc_id)
    result_ref.set({
        "liberalRecommendations": liberal_results,
        "careerRecommendations": career_results
    }, merge=True)


# 이전 수강 강의 불러오기
def fetch_previous_courses(user_id):
    courses_ref = db.collection("users").document(user_id).collection("previous_courses")
    docs = courses_ref.stream()
    previous_courses = set()
    for doc in docs:
        data = doc.to_dict()
        course_key = data.get("과목명")
        if course_key:
            previous_courses.add(course_key)
    return previous_courses
