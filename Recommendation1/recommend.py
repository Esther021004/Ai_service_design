import pandas as pd
import numpy as np
import ast
import re
import traceback
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import normalize


def get_webdriver():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument(
        "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    return webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)


def crawl_schedule(url):
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
        return [{"과목명": lec, "교수명": prof} for lec, prof in sorted(course_set)]
    except Exception:
        return []

def vectorize_user_input(user):
    class_types = ['블렌디드', '원격', '일반']
    attendance_types = ['전자출결', '직접호명', '모름', '복합적', '반영안함']
    grade_types = ['너그러움', '보통', '모름', '깐깐함']

    def convert_exam_count_scaled(value):
        if '없' in value: return 0.2
        if '한' in value: return 0.4
        if '두' in value: return 0.6
        if '세' in value: return 0.8
        if '네' in value or '4' in value: return 1.0
        return 0.4

    def scale_task_or_team(value):
        if '많' in value: return 1.0
        if '없' in value: return 0.0
        return 0.5

    def rating_bucket(score):
        try: score = float(score)
        except: return 0.0
        if 4.0 <= score <= 5.0: return 0.5
        elif 3.0 <= score < 4.0: return 0.4
        elif 2.0 <= score < 3.0: return 0.3
        elif 1.0 <= score < 2.0: return 0.2
        return 0.0

    수업유형_weighted = [1 if user['수업유형'] == t else 0 for t in class_types]
    출결 = [1 if user['출결'] == t else 0 for t in attendance_types]
    시험 = convert_exam_count_scaled(user['시험']) / 3
    과제 = scale_task_or_team(user['과제'])
    조모임 = scale_task_or_team(user['조모임'])
    성적 = [1 if user['성적'] == g else 0 for g in grade_types]
    강의시간 = 1.0 if user['강의 시간'] == '풀강' else 0.0
    강의력 = {'좋음': 1.0, '보통': 0.5, '나쁨': 0.0}.get(user['강의력'], 0.5)
    평점_weighted = rating_bucket(user['평점']) / 2

    return np.array(수업유형_weighted + 출결 + [시험, 과제, 조모임] + 성적 + [강의시간, 강의력, 평점_weighted])


def feature_map(index, value):
    if 0 <= index <= 2:
        value = value / 3
        return ['블렌디드', '원격', '일반'][index] if value > 0 else None
    elif 3 <= index <= 7:
        return ['전자출결', '직접호명', '모름', '복합적', '반영안함'][index - 3] if value == 1 else None
    elif index == 8:
        return ['시험X', '시험1번', '시험2번', '시험3번', '시험4번이상'][int(value * 5 - 1)]
    elif index == 9:
        return '과제많음' if value == 1 else '과제없음' if value == 0 else '과제보통/모름'
    elif index == 10:
        return '조모임많음' if value == 1 else '조모임없음' if value == 0 else '조모임보통/모름'
    elif 11 <= index <= 14:
        return ['너그러움', '보통', '모름', '깐깐함'][index - 11] if value == 1 else None
    elif index == 15:
        return '풀강' if value == 1 else '풀강X'
    elif index == 16:
        return '강의력좋음' if value == 1 else '강의력나쁨' if value == 0 else '강의력보통/모름'
    elif index == 17:
        value = value / 2
        if value <= 0.2: return '평점≤2'
        elif value <= 0.3: return '평점≤3'
        elif value <= 0.4: return '평점≤4'
        else: return '평점≤5'
    return None


def get_top_3_features(user_vec, lecture_vec):
    contributions = user_vec * lecture_vec
    top_indices = np.argsort(contributions)[::-1]
    reasons = []
    for i in top_indices:
        reason = feature_map(i, lecture_vec[i])
        if reason and reason not in reasons:
            reasons.append(reason)
        if len(reasons) == 3:
            break
    return reasons


# ==================== 추천 함수 ====================
def recommend_major_lectures(user_input: dict, previous_courses: list) -> list:
    dept = user_input['단과대학']
    major = user_input['전공']
    sub = user_input['세부전공']
    filename = f"강의_벡터화_{dept}_{major}_{sub}.csv" if sub else f"강의_벡터화_{dept}_{major}.csv"
    df = pd.read_csv(filename, encoding='utf-8-sig')

    학년_영역 = str(user_input['학년']) + "영역"
    df = df[df['영역'].str.contains(학년_영역)].copy()

    # 과목명 기준 중복 제거
    prev_subjects = set([p['과목명'] for p in previous_courses])
    df = df[~df['과목명'].isin(prev_subjects)]

    df['parsed_vector'] = df['전체벡터'].apply(ast.literal_eval)
    lecture_matrix = np.array(df['parsed_vector'].tolist())[:, :18]

    user_vec = vectorize_user_input(user_input).reshape(1, -1)
    sim = cosine_similarity(normalize(user_vec), normalize(lecture_matrix))[0]
    df['유사도'] = sim

    top_df = df.sort_values(by='유사도', ascending=False).drop_duplicates(['과목명']).head(5)

    recommendations = []
    for _, row in top_df.iterrows():
        lecture_vec = np.array(row['parsed_vector'])[:18]
        reasons = get_top_3_features(user_vec.flatten(), lecture_vec)
        recommendations.append({
            '과목명': row['과목명'],
            '교수명': row['교수명'],
            '개설학과전공': row['개설학과전공'],
            '영역': row['영역'],
            '추천 이유': reasons
        })

    return recommendations

# ==================== 실행 ====================
if __name__ == "__main__":
    # ✅ 여러 학기 링크 입력받기
    previous_courses = []
    semester_urls = {}

    print("💬 수강 학기별 에브리타임 링크를 입력하세요. (입력 종료: 없음)")
    while True:
        semester = input("📌 수강 학기 입력 (예: 24-1): ").strip()
        if semester.lower() == '없음':
            break
        url = input(f"🔗 {semester}학기 에브리타임 링크: ").strip()
        courses = crawl_schedule(url)
        semester_urls[semester] = courses
        previous_courses.extend(courses)

    print("\n📚 [이전 수강 내역]")
    for sem, course_list in semester_urls.items():
        print(f"- {sem}: {course_list}")

    user_input = get_user_input()
    recommendations = recommend_major_lectures(user_input, previous_courses)

    print("\n✨ [전공 강의 추천 결과]")
    for r in recommendations:
        print(f"\n📘 {r['과목명']} ({r['교수명']})")
        print(f"개설학과전공: {r['개설학과전공']} | 영역: {r['영역']}")
        print("추천 이유:", ", ".join(r['추천 이유']))
