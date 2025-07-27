from fastapi import APIRouter, HTTPException
from firebase.firebase_client import get_firestore_client

router = APIRouter()
db = get_firestore_client()

@router.get("/schedule/{user_id}")
def get_schedule(user_id: str):
    try:
        timetable_ref = db.collection("users").document(user_id).collection("timetable")
        docs = timetable_ref.stream()
        schedule = [doc.to_dict() for doc in docs]

        if not schedule:
            return {"message": "시간표에 저장된 강의가 없습니다.", "schedule": []}
        return {"message": "🗓️ 사용자 시간표입니다.", "schedule": schedule}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
