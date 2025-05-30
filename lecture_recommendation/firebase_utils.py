# === Firebase 연동 유틸리티 (개발용 목업 포함) ===

import firebase_admin
from firebase_admin import credentials, firestore
import os

# ✅ Render에서는 이 경로로 서비스 키가 저장됨
FIREBASE_KEY_PATH = "/etc/secrets/firebase_config.json"

# Firebase 초기화
if not firebase_admin._apps:
    cred = credentials.Certificate(FIREBASE_KEY_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()

def fetch_user_input_from_firebase(user_id: str) -> dict:
    doc_ref = db.collection("user_inputs").document(user_id)
    doc = doc_ref.get()
    if doc.exists:
        return doc.to_dict()
    else:
        raise ValueError("User input not found")


def save_recommendation_to_firebase(user_id: str, result: dict) -> None:
    doc_ref = db.collection("recommendations").document(user_id)
    doc_ref.set(result)
