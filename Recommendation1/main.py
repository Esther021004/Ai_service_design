from fastapi import FastAPI
from pydantic import BaseModel
from firebase_utils import fetch_user_input, save_recommendations
from recommend import crawl_schedule, recommend_major_lectures

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "수강요정 추천시스템 FastAPI입니다!"}
    
class UserRequest(BaseModel):
    user_id: str
    semester_urls: dict  # { "24-1": "https://everytime.kr/...", "24-2": "https://..." }

@app.post("/recommend/")
def recommend(user: UserRequest):
    user_input = fetch_user_input(user.user_id)
    if not user_input:
        return {"error": "사용자 정보 없음"}

    # 수강 내역 수집
    previous_courses = []
    for url in user.semester_urls.values():
        previous_courses.extend(crawl_schedule(url))

    # 추천 실행
    results = recommend_major_lectures(user_input, previous_courses)
    save_recommendations(user.user_id, results)
    return {"user_id": user.user_id, "recommendations": results}
