from fastapi import APIRouter, HTTPException
from models.schema import ScheduleRequest, BaseResponse
from firebase.firebase_client import get_firestore_client

router = APIRouter()
db = get_firestore_client()

@router.delete("/schedule/delete", response_model=BaseResponse)
def delete_schedule(request: ScheduleRequest):
    user_id = request.user_id
    subject = request.과목명
    professor = request.교수명

    doc_ref = db.collection("user_schedules").document(user_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail="사용자 시간표가 존재하지 않습니다.")

    current = doc.to_dict().get("current_schedule", [])
    updated = [lec for lec in current if not (subject in lec['과목명'] and lec['교수명'] == professor)]

    if len(updated) == len(current):
        raise HTTPException(status_code=404, detail="해당 강의는 시간표에 없습니다.")

    doc_ref.set({"current_schedule": updated})
    return {"message": "🗑️ 강의가 삭제되었습니다."}
