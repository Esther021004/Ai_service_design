from fastapi import FastAPI
from router import courses

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "이전 수강 강의 API is running 🚀"}

# 강의 저장 및 학점 계산 관련 라우터 등록
app.include_router(courses.router)
