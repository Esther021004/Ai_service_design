from fastapi import APIRouter, HTTPException
from models.schema import ScheduleRequest, ScheduleResponse
from firebase.firebase_client import get_firestore_client
from utils.parser import (
    load_course_csv,
    parse_timeslot,
    is_overlapping,
    get_random_course_row
)

router = APIRouter()
db = get_firestore_client()
df = load_course_csv()

@router.post("/schedule/add", response_model=ScheduleResponse)
def add_schedule(request: ScheduleRequest):
    user_id = request.user_id
    subject = request.과목명
    professor = request.교수명

    selected_row, is_divided = get_random_course_row(df, subject, professor)
    if selected_row is None:
        raise HTTPException(status_code=404, detail="해당 강의 정보를 찾을 수 없습니다.")

    timetable_str = selected_row['시간표']
    if timetable_str.strip() == '미정':
        raise HTTPException(status_code=400, detail="아직 시간표가 존재하지 않는 강의예요!")

    parsed_time = parse_timeslot(timetable_str)
    if not parsed_time:
        raise HTTPException(status_code=400, detail="시간표 형식이 잘못되었습니다.")

    doc_ref = db.collection("user_schedules").document(user_id)
    doc = doc_ref.get()
    current = doc.to_dict().get("current_schedule", []) if doc.exists else []

    if is_overlapping(parsed_time, current):
        raise HTTPException(status_code=409, detail="이미 해당 시간에 다른 일정이 있어요!")

    new_lecture = {
        "과목명": subject + "(분반)" if is_divided else subject,
        "교수명": professor,
        "시간표": parsed_time,
        "캠퍼스": selected_row['캠퍼스']
    }

    updated_schedule = current + [new_lecture]
    doc_ref.set({"current_schedule": updated_schedule})

    return {"message": "✅ 강의가 시간표에 추가되었습니다.", "data": new_lecture}
