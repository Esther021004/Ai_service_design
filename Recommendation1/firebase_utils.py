import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

cred = credentials.Certificate("/etc/secrets/firebase_config")
firebase_admin.initialize_app(cred)
db = firestore.client()

def fetch_user_input(user_id):
    doc = db.collection("users").document(user_id).get()
    return doc.to_dict() if doc.exists else None

def save_recommendations(user_id, recommendations):
    doc_id = datetime.now().isoformat()
    doc_ref = db.collection("users").document(user_id).collection("results").document(doc_id)
    doc_ref.set({
        "createdAt": doc_id,
        "majorRecommendations": recommendations
    })
    return doc_id 

def fetch_previous_courses(user_id):
    courses_ref = db.collection("users").document(user_id).collection("previous_courses")
    docs = courses_ref.stream()
    previous_courses = set()
    for doc in docs:
        data = doc.to_dict()
        course_key = (data.get("과목명"), data.get("교수명"))
        previous_courses.add(course_key)
    return previous_courses
