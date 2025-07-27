from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Literal
from firebase.firebase_client import save_courses_to_subcollection, update_course_with_metadata, get_all_courses, save_credit_summary
from utils.crawling import crawl_schedule
from utils.credit_calc import compute_credit_ratios

router = APIRouter()

# 🔹 사용자 요청 모델 정의
class CrawlRequest(BaseModel):
    user_id: str
    schedule_url: str

class CourseUpdate(BaseModel):
    user_id: str
    course_name: str
    professor_name: str
    category: Literal["전공", "교양", "교직"]
    credit: int

class UserID(BaseModel):
    user_id: str

# 🔹 시간표 URL을 통해 과목명/교수명 저장
@router.post("/save-courses")
def save_courses_from_url(request: CrawlRequest):
    try:
        courses = crawl_schedule(request.schedule_url)
        print("✅ 크롤링된 강의:", courses)
        
        save_courses_to_subcollection(request.user_id, courses)
        return {"message": f"{len(courses)}개 강의를 저장했습니다.", "courses": courses}
    except Exception as e:
        print("❌ 저장 중 오류:", e)
        raise HTTPException(status_code=500, detail=f"크롤링 또는 저장 중 오류: {e}")

# 🔹 사용자 입력 기반 이수구분 및 학점 업데이트
@router.post("/update-course-info")
def update_course_info(data: CourseUpdate):
    success = update_course_with_metadata(
        user_id=data.user_id,
        course_name=data.course_name,
        professor_name=data.professor_name,
        category=data.category,
        credit=data.credit
    )
    if success:
        return {"message": "강의 정보가 성공적으로 업데이트되었습니다."}
    else:
        raise HTTPException(status_code=404, detail="해당 강의를 찾을 수 없습니다.")

# 🔹 전체 수강 강의에서 학점 비율 계산
@router.post("/calculate-credit-ratio")
def calculate_credit_ratio(user: UserID):
    all_courses = get_all_courses(user.user_id)
    if not all_courses:
        raise HTTPException(status_code=404, detail="강의 정보가 존재하지 않습니다.")

    # 🔹 학점 비율 계산
    result = compute_credit_ratios(all_courses)
    
     # 🔹 분석 결과 저장
    save_credit_summary(user.user_id, result)
    
    return result
