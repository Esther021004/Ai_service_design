from fastapi import APIRouter, HTTPException
from models.schema import UpdateRequest, BaseResponse
from firebase.firebase_client import get_firestore_client

router = APIRouter()
db = get_firestore_client()

@router.put("/schedule/update", response_model=BaseResponse)
def update_schedule(request: UpdateRequest):
    user_id = request.user_id
    subject = request.과목명
    professor = request.교수명
    new_subject = request.새로운_과목명

    doc_ref = db.collection("user_schedules").document(user_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail="사용자 시간표가 존재하지 않습니다.")

    current = doc.to_dict().get("current_schedule", [])
    found = False

    for lec in current:
        if subject in lec['과목명'] and lec['교수명'] == professor:
            lec['과목명'] = new_subject
            found = True
            break

    if not found:
        raise HTTPException(status_code=404, detail="해당 강의를 찾을 수 없습니다.")

    doc_ref.set({"current_schedule": current})
    return {"message": "✏️ 과목명이 수정되었습니다."}
