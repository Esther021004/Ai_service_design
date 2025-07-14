import firebase_admin
from firebase_admin import credentials, firestore
import os

# Firebase Admin SDK 인증 키 경로 (환경변수 또는 직접 설정)
FIREBASE_KEY_PATH = "/etc/secrets/serviceAccountKey"

# Firebase 초기화
if not firebase_admin._apps:
    cred = credentials.Certificate(FIREBASE_KEY_PATH)
    firebase_admin.initialize_app(cred)

def get_firestore_client():
    return firestore.client()
