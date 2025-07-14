from fastapi import APIRouter, HTTPException
from models.schema import UserOnlyRequest, BaseResponse
from firebase.firebase_client import get_firestore_client

router = APIRouter()
db = get_firestore_client()

@router.post("/schedule/reset", response_model=BaseResponse)
def reset_schedule(request: UserOnlyRequest):
    user_id = request.user_id

    doc_ref = db.collection("user_schedules").document(user_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail="사용자 시간표가 존재하지 않습니다.")

    doc_ref.set({"current_schedule": []})
    return {"message": "🧹 시간표가 초기화되었습니다."}
