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

    timetable_ref = db.collection("users").document(user_id).collection("timetable")
    docs = timetable_ref.stream()

    target_doc_id = None
    for doc in docs:
        data = doc.to_dict()
        if subject in data.get("과목명", "") and data.get("교수명") == professor:
            target_doc_id = doc.id
            break

    if not target_doc_id:
        raise HTTPException(status_code=404, detail="해당 강의를 찾을 수 없습니다.")

    # 업데이트 실행
    timetable_ref.document(target_doc_id).update({"과목명": new_subject})
    
    return {"message": "✏️ 과목명이 수정되었습니다."}
