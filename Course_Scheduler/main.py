from fastapi import FastAPI
from api import add_schedule, delete_schedule, update_schedule, reset_schedule
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# CORS 허용 설정 (필요 시 수정 가능)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 라우터 등록
app.include_router(add_schedule.router)
app.include_router(delete_schedule.router)
app.include_router(update_schedule.router)
app.include_router(reset_schedule.router)

@app.get("/")
def root():
    return {"message": "✅ 시간표 API 서버가 실행 중입니다."}
