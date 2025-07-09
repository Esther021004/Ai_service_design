import firebase_admin
from firebase_admin import credentials, firestore

# Firebase 초기화
cred = credentials.Certificate("firebase_key.json")  # 서비스 계정 키 json
firebase_admin.initialize_app(cred)
db = firestore.client()

def fetch_user_info(user_id):
    doc = db.collection("users").document(user_id).get()
    return doc.to_dict()

def fetch_user_schedule_urls(user_id):
    doc = db.collection("schedules").document(user_id).get()
    return doc.to_dict()

def save_recommendation_to_firebase(user_id, liberal_results, career_results):
    db.collection("recommendations").document(user_id).set({
        "liberal": liberal_results,
        "career": career_results
    })
