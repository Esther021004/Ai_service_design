from fastapi import APIRouter, HTTPException
from models.schema import ScheduleRequest, ScheduleResponse
from firebase.firebase_client import get_firestore_client
from utils.parser import (
    load_course_csv,
    parse_timeslot,
    is_overlapping,
    get_random_course_row
)
from uuid import uuid4  # ✅ 각 강의에 고유 ID 부여용

router = APIRouter()
db = get_firestore_client()
df = load_course_csv()

@router.post("/schedule/add", response_model=ScheduleResponse)
def add_schedule(request: ScheduleRequest):
    user_id = request.user_id
    subject = request.과목명
    professor = request.교수명

    # ✅ [NEW] 찜한 강의인지 확인
    favorites_ref = db.collection("users").document(user_id).collection("favorites")
    favorites = [doc.to_dict() for doc in favorites_ref.stream()]
    is_favorited = any(
        fav.get("과목명") == subject and fav.get("교수명") == professor for fav in favorites
    )
    if not is_favorited:
        raise HTTPException(status_code=403, detail="⛔ 해당 강의는 찜한 강의가 아닙니다.")

    
    selected_row, is_divided = get_random_course_row(df, subject, professor)
    if selected_row is None:
        raise HTTPException(status_code=404, detail="해당 강의 정보를 찾을 수 없습니다.")

    timetable_str = selected_row['시간표']
    if timetable_str.strip() == '미정':
        raise HTTPException(status_code=400, detail="아직 시간표가 존재하지 않는 강의예요!")
    
    parsed_time = parse_timeslot(timetable_str)
    if not parsed_time:
        raise HTTPException(status_code=400, detail="시간표 형식이 잘못되었습니다.")

    # ✅ 현재 시간표 불러와서 중복 확인
    timetable_ref = db.collection("users").document(user_id).collection("timetable")
    existing = [doc.to_dict() for doc in timetable_ref.stream()]

    # '시간표' 키가 존재하는 문서만 추출
    existing_times = [lec["시간표"] for lec in existing if "시간표" in lec]

    if is_overlapping(parsed_time, existing_times):
        raise HTTPException(status_code=409, detail="이미 해당 시간에 다른 일정이 있어요!")

    # ✅ 고유 lecture_id 생성 및 개별 문서로 저장
    lecture_id = str(uuid4())
    new_lecture = {
        "과목명": subject + "(분반)" if is_divided else subject,
        "교수명": professor,
        "시간표": parsed_time,
        "캠퍼스": selected_row['캠퍼스']
    }
    
    timetable_ref.document(lecture_id).set(new_lecture)

    return {"message": "✅ 강의가 시간표에 추가되었습니다.", "data": new_lecture}
