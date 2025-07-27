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

    timetable_ref = db.collection("users").document(user_id).collection("timetable")
    docs = timetable_ref.stream()

    target_doc_id = None
    for doc in docs:
        data = doc.to_dict()
        if subject in data.get("과목명", "") and data.get("교수명") == professor:
            target_doc_id = doc.id
            break

    if not target_doc_id:
        raise HTTPException(status_code=404, detail="해당 강의는 시간표에 없습니다.")

    timetable_ref.document(target_doc_id).delete()

    return {"message": "🗑️ 강의가 삭제되었습니다."}
