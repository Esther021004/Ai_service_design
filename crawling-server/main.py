from fastapi import FastAPI, Request
from pydantic import BaseModel
from utils.crawling import crawl_schedule

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Crawling server is running 🐍"}

class URLRequest(BaseModel):
    url: str

@app.post("/crawl")
def crawl_courses(request: URLRequest):
    try:
        print("📥 요청 URL:", request.url)
        result = crawl_schedule(request.url)
        print("✅ 크롤링 결과:", result)
        return {"courses": result}
    except Exception as e:
        print("❌ 크롤링 오류:", e)
        return {"detail": f"크롤링 중 오류: {e}"}
