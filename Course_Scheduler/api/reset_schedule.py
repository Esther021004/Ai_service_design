from fastapi import APIRouter, HTTPException
from models.schema import UserOnlyRequest, BaseResponse
from firebase.firebase_client import get_firestore_client

router = APIRouter()
db = get_firestore_client()

@router.post("/schedule/reset", response_model=BaseResponse)
def reset_schedule(request: UserOnlyRequest):
    user_id = request.user_id

    timetable_ref = db.collection("users").document(user_id).collection("timetable")
    docs = list(timetable_ref.stream())
    
    if not docs:
        raise HTTPException(status_code=404, detail="시간표에 저장된 강의가 없습니다.")

    for doc in docs:
        doc.reference.delete()

    return {"message": "🧹 시간표가 초기화되었습니다."}
