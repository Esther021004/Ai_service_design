from fastapi import FastAPI
from fastapi import HTTPException
from pydantic import BaseModel
from recommender import recommend_combined, recommend_career, vectorize_user_input
from firebase_utils import fetch_user_info, fetch_user_schedule_urls, save_recommendation_to_firebase
from recommender import crawl_schedule

app = FastAPI()

class UserID(BaseModel):
    user_id: str

@app.get("/")
def read_root():
    return {"message": "liberal-career recommender API is live 🚀"}

@app.post("/recommend/liberal-career")
def recommend_courses(user: UserID):
    user_id = user.user_id
    
    # 사용자 정보 및 에브리타임 링크 가져오기
    user_input = fetch_user_info(user_id)
    url_dict = fetch_user_schedule_urls(user_id)

    if not user_input or not url_dict:
        raise HTTPException(status_code=404, detail="사용자 정보 또는 시간표 링크가 없습니다.")

    all_semester_courses = []
    for semester, url in url_dict.items():
        try:
            courses = crawl_schedule(url)
            all_semester_courses.extend(courses)
        except Exception as e:
            print(f"⚠️ {semester} 링크에서 오류 발생: {e}")

    # 사용자 벡터화
    user_vector = vectorize_user_input(user_input)

    # 추천 수행
    liberal_results = recommend_combined(user_input, user_vector, all_semester_courses)
    career_results = recommend_career(user_input, user_vector, all_semester_courses)

    # 결과 저장
    save_recommendation_to_firebase(user_id, liberal_results, career_results)

    return {
        "liberal_recommendations": liberal_results,
        "career_recommendations": career_results
    }
