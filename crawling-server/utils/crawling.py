# utils/crawling.py

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def get_webdriver():
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # 필요 시 제거
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36")

    # docker 환경용 chromium 경로 지정
    chrome_options.binary_location = "/usr/bin/chromium"

    return webdriver.Chrome(
        service=Service("/usr/bin/chromedriver"),
        options=chrome_options
    )


def crawl_schedule(url: str):
    try:
        driver = get_webdriver()
        driver.get(url)

        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.CLASS_NAME, "tablebody")))
        tablebody = driver.find_element(By.CLASS_NAME, "tablebody")
        subjects = tablebody.find_elements(By.CLASS_NAME, "subject")

        course_set = set()
        for subject in subjects:
            try:
                lecture = subject.find_element(By.TAG_NAME, "h3").text.strip()
                professor = subject.find_element(By.TAG_NAME, "em").text.strip()
                course_set.add((lecture, professor))
            except:
                continue
        driver.quit()
        return list(course_set)
    except Exception as e:
        print("크롤링 오류:", e)
        return []
