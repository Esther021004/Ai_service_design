from pydantic import BaseModel
from typing import Dict, List, Optional

# ✅ 공통 요청 모델 (과목명 + 교수명 + user_id)
class ScheduleRequest(BaseModel):
    user_id: str
    과목명: str
    교수명: str

# ✅ 과목명 수정용 요청 모델
class UpdateRequest(ScheduleRequest):
    새로운_과목명: str

# ✅ 초기화 요청 등 user_id만 필요한 경우
class UserOnlyRequest(BaseModel):
    user_id: str

# ✅ 단순 응답 메시지용
class BaseResponse(BaseModel):
    message: str

# ✅ 강의 정보 (시간표 포함)
class Lecture(BaseModel):
    과목명: str
    교수명: str
    시간표: Dict[str, List[int]]
    캠퍼스: Optional[str] = None

# ✅ 추가 API 응답용 (강의 정보 포함)
class ScheduleResponse(BaseResponse):
    data: Lecture
