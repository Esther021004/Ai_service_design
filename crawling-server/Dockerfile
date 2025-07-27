# Python 3.10 기반
FROM python:3.10-slim

# 기본 설정
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# 필수 패키지 설치
RUN apt-get update && apt-get install -y \
    chromium chromium-driver \
    wget unzip curl gnupg2 ca-certificates \
    fonts-liberation libappindicator3-1 libasound2 \
    libatk-bridge2.0-0 libatk1.0-0 libcups2 libdbus-1-3 \
    libgdk-pixbuf2.0-0 libnspr4 libnss3 libx11-xcb1 \
    libxcomposite1 libxdamage1 libxrandr2 xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# 파이썬 라이브러리 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 코드 복사
COPY . .

EXPOSE 8000
CMD uvicorn main:app --host 0.0.0.0 --port $PORT
RUN echo $(chromedriver --version)
