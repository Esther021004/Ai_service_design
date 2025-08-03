from fastapi import FastAPI
from fastapi import HTTPException
from fastapi.encoders import jsonable_encoder
from pydantic import BaseModel
from recommender import recommend_combined, recommend_career, vectorize_user_input
from firebase_utils import fetch_user_info, save_recommendation_to_firebase, fetch_previous_courses
import math

app = FastAPI()

print("[BOOT] FastAPI 시작됨")

class UserID(BaseModel):
    user_id: str
    doc_id: str

def replace_nan_with_none(obj):
    """NaN → None 재귀 치환 함수"""
    if isinstance(obj, float) and math.isnan(obj):
        return None
    elif isinstance(obj, dict):
        return {k: replace_nan_with_none(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [replace_nan_with_none(v) for v in obj]
    else:
        return obj
        
@app.get("/")
def read_root():
    return {"message": "liberal-career recommender API is live 🚀"}

@app.post("/recommend/liberal-career")
def recommend_courses(user: UserID):
    user_id = user.user_id
    doc_id = user.doc_id
    
    # 사용자 profile + preferences 불러오기
    user_doc = fetch_user_info(user_id)
    if not user_doc:
        raise HTTPException(status_code=404, detail="사용자 정보를 찾을 수 없습니다.")

    profile = user_doc.get("profile", {})
    liberal_pref = user_doc.get("preferences", {}).get("liberal", {})

    if not profile or not liberal_pref:
        raise HTTPException(status_code=400, detail="profile 또는 liberal 선호 정보가 없습니다.")

     # 이전 수강 강의 Firebase에서 불러오기
    previous_courses = [{"과목명": name} for name in fetch_previous_courses(user_id)]

    # 사용자 선호 벡터화
    user_input = {
        "profile": profile,
        "preferences": {
            "liberal": liberal_pref
        }
    }
    user_vector = vectorize_user_input(user_input)

    # 추천 수행 (profile = 단과대학, 전공, 세부전공, 학년 포함)
    liberal_results = recommend_combined(user_input, user_vector, previous_courses)
    career_results = recommend_career(user_input, user_vector, previous_courses)

    # 결과 저장
    save_recommendation_to_firebase(user_id, doc_id, liberal_results, career_results)

    # NaN 제거 후 반환
    safe_liberal = replace_nan_with_none(liberal_results)
    safe_career = replace_nan_with_none(career_results)
    
    return jsonable_encoder({
        "liberal_recommendations": safe_liberal,
        "career_recommendations": safe_career
    })
