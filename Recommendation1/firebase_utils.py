import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("/etc/secrets/firebase_config")
firebase_admin.initialize_app(cred)
db = firestore.client()

def fetch_user_input(user_id):
    doc = db.collection("users").document(user_id).get()
    return doc.to_dict() if doc.exists else None

def save_recommendations(user_id, recommendations):
    db.collection("recommendations").document(user_id).set({"results": recommendations})
