import uvicorn
from fastapi import FastAPI
from pydantic import BaseModel, Field
from recommender import get_recommendations
from firebase_utils import fetch_user_input_from_firebase
from firebase_utils import save_recommendation_to_firebase
from typing import Optional

app = FastAPI()

@app.get("/")
def root():
    return {"message": "강의 추천 API 작동 중"}

class UserInput(BaseModel):
    전공: str
    학년: int
    세부전공: Optional[str] = None
    시험: str
    과제: str
    조모임: str
    출결: str
    성적: str
    강의_시간: str = Field(alias="강의 시간")
    강의력: str
    수업유형: str
    캠퍼스: str
    평점: str


@app.post("/recommend")
def recommend_lectures(user_input: UserInput):
    result = get_recommendations(user_input.dict(by_alias=True))
    return result

# 🔹 Firebase에 저장된 사용자 정보 기반 추천 (user_id 기반)
class UserID(BaseModel):
    user_id: str

@app.post("/recommend/firebase")
def recommend_from_firebase(request: UserID):
    user_data = fetch_user_input_from_firebase(request.user_id)
    result = get_recommendations(user_data)
    save_recommendation_to_firebase(request.user_id, result)
    return result

