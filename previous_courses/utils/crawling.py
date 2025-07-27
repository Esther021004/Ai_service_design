# utils/crawling.py
import os
import requests

CRAWLING_SERVER_URL = os.getenv("CRAWLING_SERVER_URL", "https://crawling-server.onrender.com/crawl")

def crawl_schedule(schedule_url: str):
    try:
        response = requests.post(
            CRAWLING_SERVER_URL,
            json={"url": schedule_url},
            timeout=30  # 10초 제한
        )
        response.raise_for_status()
        data = response.json()
        return data.get("courses", [])
    except Exception as e:
        print("크롤링 서버 호출 실패:", e)
        return []
