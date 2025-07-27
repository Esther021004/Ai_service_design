from fastapi import FastAPI
from pydantic import BaseModel
from firebase_utils import fetch_user_input, save_recommendations, fetch_previous_courses
from recommend import recommend_major_lectures

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "수강요정 추천시스템 FastAPI입니다!"}
    
class UserRequest(BaseModel):
    user_id: str

@app.post("/recommend/")
def recommend(user: UserRequest):
    # 1. 사용자 기본 정보 로드
    user_doc = fetch_user_input(user.user_id)
    if not user_doc:
        return {"error": "사용자 정보 없음"}

    # 2. profile과 preferences.major 분리
    profile = user_doc.get("profile", {})
    preferences = user_doc.get("preferences", {}).get("major", {})

    # 3. DB에서 이전 수강 강의 불러오기
    previous_courses = fetch_previous_courses(user.user_id)

     # 4. 추천 실행
    user_input = {
        "profile": profile,
        "preferences": {
            "major": preferences
        }
    }
    results = recommend_major_lectures(user_input, previous_courses)

    # 5. 결과 저장
    save_recommendations(user.user_id, results)
    
    return {"user_id": user.user_id, "recommendations": results}
