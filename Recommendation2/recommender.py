import pandas as pd
import numpy as np
import ast
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import normalize

# ===== 크롤링 =====
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
                course_set.add({"과목명": lecture, "교수명": professor})
            except:
                continue
        return [{"과목명": lec, "교수명": prof} for lec, prof in sorted(course_set)]
    except Exception:
        return []

# ========== 캠퍼스 인코딩 함수 ==========
def encode_campus(campus):
    if campus == '수정': return [1.0, 0.0]
    elif campus == '운정': return [0.0, 1.0]
    return [0.0, 0.0]  # 상관없음
  
# ===== 사용자 벡터화 =====
def vectorize_user_input(user):
    class_types = ['블렌디드', '원격', '일반']
    attendance_types = ['전자출결', '직접호명', '모름', '복합적', '반영안함']
    grade_types = ['너그러움', '보통', '모름', '깐깐함']
    campus_types = ['수정', '운정']

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
        if score <= 1: return 0.1
        elif score <= 2: return 0.2
        elif score <= 3: return 0.3
        elif score <= 4: return 0.4
        else: return 0.5

    campus_vec = [1 if user['캠퍼스'] == t else 0 for t in campus_types] if user['캠퍼스'] in campus_types else [0, 0]
    class_type_vec = [3 * (1 if user['수업유형'] == t else 0) for t in class_types]
    attendance_vec = [1 if user['출결'] == t else 0 for t in attendance_types]
    성적_vec = [1 if user['성적'] == g else 0 for g in grade_types]
    시험 = convert_exam_count_scaled(user['시험']) / 3
    과제 = scale_task_or_team(user['과제'])
    조모임 = scale_task_or_team(user['조모임'])
    강의시간 = 1.0 if user['강의 시간'] == '풀강' else 0.0
    강의력 = {'좋음': 1.0, '보통': 0.5, '나쁨': 0.0}.get(user['강의력'], 0.5)
    평점 = (rating_bucket(user['평점']) / 2) * 2

    return np.array([시험, 과제, 조모임] + attendance_vec + 성적_vec + [강의시간, 강의력] + class_type_vec + campus_vec + [평점])

# ===== 기여도 해석 =====
def feature_map(index, value):
    if index == 0:
        if value == 0.2: return '시험 없음'
        elif value == 0.4: return '시험 1번'
        elif value == 0.6: return '시험 2번'
        elif value == 0.8: return '시험 3번'
        else: return '시험 4번 이상'
    elif index == 1:
        return '과제 많음' if value == 1 else '과제 없음' if value == 0 else '과제 보통/모름'
    elif index == 2:
        return '조모임 많음' if value == 1 else '조모임 없음' if value == 0 else '조모임 보통/모름'
    elif 3 <= index <= 7:
        return ['전자출결', '직접호명', '모름', '복합적', '반영안함'][index - 3] if value == 1 else None
    elif 8 <= index <= 11:
        return ['너그러움', '보통', '모름', '깐깐함'][index - 8] if value == 1 else None
    elif index == 12:
        return '풀강' if value == 1 else '풀강X' if value == 0 else '모름'
    elif index == 13:
        return '강의력 좋음' if value == 1 else '강의력 나쁨' if value == 0 else '강의력 보통/모름'
    elif 14 <= index <= 16:
        value = value / 3
        return ['블렌디드', '원격', '일반'][index - 14] if value == 1 else None
    elif 17 <= index <= 18:
        return ['수정캠퍼스', '운정캠퍼스'][index - 17] if value == 1 else None
    elif index == 19:
        value = value / 2
        if value <= 0.2: return '평점 ≤ 2'
        elif value <= 0.3: return '평점 ≤ 3'
        elif value <= 0.4: return '평점 ≤ 4'
        else: return '평점 ≤ 5'
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

# ===== 필수추천 불러오기 =====
def load_required_courses(user_major, user_college=None, user_grade=None):
    if user_grade != 1 or user_college == "창의융합학부":
        return pd.DataFrame(columns=['과목명', '교수명', '이수구분', '영역', '추천이유'])

    group1 = ['영어영문학과','일본어문·문화학과','독일어문·문화학과','프랑스어문·문화학과','중국어문·문화학과','법학과','국어국문학과','사학과']
    group2 = ['정치외교학과','지리학과','경영학과','미디어커뮤니케이션학과','심리학과','동양화과','서양화과','조소과','성악과','기악과','작곡과','스포츠과학학부','공예과','디자인과','경제학과']
    group3 = ['사회복지학과','의류산업학과','소비자산업학과','문화예술경영학과','현대실용음악학과','무용예술학과','간호학과','뷰티산업학과','미디어영상연기학과']


    file = None
    if user_major in group1:
        file = '필수추천_1.csv'
    elif user_major in group2:
        file = '필수추천_2.csv'
    elif user_major in group3:
        file = '필수추천_3.csv'
    else:
        file = f'필수추천_{user_major}.csv'

    try:
        df = pd.read_csv(file, encoding='utf-8-sig')

        # 그룹3이면 파이썬 프로그래밍 포함
        if user_major in group3:
            df = df[(df.get('전공명', user_major) == user_major) | (df['과목명'] == '파이썬프로그래밍')]
        # 그룹1, 그룹2는 전공명 기준 필터링
        elif user_major in group1 + group2:
            df = df[df['전공명'] == user_major]
        # 기타 전공은 전공명 컬럼이 없으므로 필터 없이 전체 사용
        else:
            pass  # 필터링 안 함

        # 출력 컬럼 정리
        if '추천이유' not in df.columns:
            df['추천이유'] = '전공 필수 추천'
        return df[['과목명','교수명','이수구분','영역','추천이유']].reset_index(drop=True)
    except:
        return pd.DataFrame(columns=['과목명','교수명','이수구분','영역','추천이유'])

# ===== 교양 추천 =====
def recommend_liberal(user_vec, prev_lectures, 필수과목명, user_grade):
    df = pd.read_csv("강의_벡터화_일반교양.csv", encoding='utf-8-sig')
    df['parsed_vector'] = df['전체 벡터'].apply(ast.literal_eval)

    # 🔹 1학년이 아니면 공통교양 제외
    if user_grade != 1:
        df['이수구분'] = df['이수구분'].astype(str).str.strip().str.replace(r"\s+", "", regex=True)
        df = df[df['이수구분'] != '공통교양']
      
    lecture_matrix = np.array(df['parsed_vector'].tolist())[:, :20]
    sim = cosine_similarity(normalize(user_vec.reshape(1, -1)), normalize(lecture_matrix))[0]
    df['유사도'] = sim

    # 이전 수강한 과목명 + 필수추천 과목명 제외
    prev_titles = set(x['과목명'].strip().lower() for x in prev_lectures)
    필수과목명 = set(c.strip().lower() for c in 필수과목명)
    제외과목명 = prev_titles.union(필수과목명)
  
    df = df[~df['과목명'].str.strip().str.lower().isin(제외과목명)]
    df = df.drop_duplicates(subset=['과목명','교수명'])

    top_df = df.sort_values(by='유사도', ascending=False).head(30)
    
    results = []
    for _, row in top_df.iterrows():
        lecture_vec = np.array(row['parsed_vector'])[:20]
        reasons = get_top_3_features(user_vec.flatten(), lecture_vec)
        results.append({
            '과목명': row['과목명'],
            '교수명': row['교수명'],
            '이수구분': row['이수구분'],
            '영역': row['영역'],
            '추천이유': reasons
        })
    return results

# ===== 통합 교양 추천 =====
def recommend_combined(user_input, user_vec, prev_lectures):
    필수추천 = load_required_courses(
        user_major=user_input['전공'],
        user_college=user_input['단과대학'],
        user_grade=user_input['학년']
    )
  
    필수추천_dict = 필수추천.to_dict('records')

    # 필수 추천 과목명 목록 (소문자 + 공백제거로 통일)
    필수과목명 = set(c.strip().lower() for c in 필수추천['과목명'].tolist())

    # 유사도 기반 추천
    유사도추천 = recommend_liberal(user_vec, prev_lectures, 필수과목명, user_input['학년'])
  
    # 유사도 추천 중 필수추천과 과목명 겹치는 항목 제거
    유사도추천_filtered = [
        r for r in 유사도추천
        if r['과목명'].strip().lower() not in 필수과목명
    ]
    
    # 최종 추천 15개로 제한
    needed = 15 - len(필수추천_dict)
    final_recommend = 필수추천_dict + 유사도추천_filtered[:needed]
    return final_recommend

# ===== 진로소양 추천 =====
def recommend_career(user_input, user_vec, prev_lectures):
    df = pd.read_csv("강의_벡터화_진로소양.csv", encoding='utf-8-sig')
    df['parsed_vector'] = df['전체 벡터'].apply(ast.literal_eval)
  
    lecture_matrix = np.array(df['parsed_vector'].tolist())[:, :20]
    sim = cosine_similarity(normalize(user_vec.reshape(1, -1)), normalize(lecture_matrix))[0]
    df['유사도'] = sim

    # 🔹 이전 수강한 과목명 (소문자 + 공백 제거)
    prev_titles = set(x['과목명'].strip().lower() for x in prev_lectures)
    
    # 🔹 중복 방지를 위한 제외 과목 세트
    제외과목명 = set(prev_titles)
    must_recommend = []

    # ✅ 조건 충족 시 '전공별진로탐색' 무조건 추천
    if user_input['학년'] == 1 and user_input['전공'] not in ['청정신소재공학과', '바이오식품공학과', '뷰티산업학과'] and user_input['단과대학'] != '사범대학':
        탐색_row = df[df['과목명'].str.contains("전공별 진로 탐색", case=False)]
        for _, row in 탐색_row.iterrows():
            title = row['과목명'].strip().lower()
            if title not in 제외과목명:
                lecture_vec = np.array(row['parsed_vector'])[:20]
                reasons = get_top_3_features(user_vec.flatten(), lecture_vec)
                must_recommend.append({
                    '과목명': row['과목명'],
                    '교수명': row['교수명'],
                    '이수구분': row['이수구분'],
                    '영역': row['영역'],
                    '추천이유': reasons
                })
                제외과목명.add(title)
                break

    # ✅ 유사도 기반 추천 (중복 방지)
    df = df.sort_values(by='유사도', ascending=False)
    results = []
    for _, row in df.iterrows():
        title = row['과목명'].strip().lower()
        if title in 제외과목명:
            continue
        lecture_vec = np.array(row['parsed_vector'])[:20]
        reasons = get_top_3_features(user_vec.flatten(), lecture_vec)
        results.append({
            '과목명': row['과목명'],
            '교수명': row['교수명'],
            '이수구분': row['이수구분'],
            '영역': row['영역'],
            '추천이유': reasons
        })
        if len(results) >= (2 - len(must_recommend)):
            break

    return must_recommend + results
