import pandas as pd
import numpy as np
import ast
import re
import traceback
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import normalize


def vectorize_user_input(user):
    pref = user["preferences"]["major"]
    
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

    수업유형_weighted = [1 if pref['수업유형'] == t else 0 for t in class_types]
    출결 = [1 if pref['출결'] == t else 0 for t in attendance_types]
    시험 = convert_exam_count_scaled(pref['시험']) / 3
    과제 = scale_task_or_team(pref['과제'])
    조모임 = scale_task_or_team(pref['조모임'])
    성적 = [1 if pref['성적'] == g else 0 for g in grade_types]
    강의시간 = 1.0 if pref['강의 시간'] == '풀강' else 0.0
    강의력 = {'좋음': 1.0, '보통': 0.5, '나쁨': 0.0}.get(pref['강의력'], 0.5)
    평점_weighted = rating_bucket(pref['평점']) / 2

    return np.array(수업유형_weighted + 출결 + [시험, 과제, 조모임] + 성적 + [강의시간, 강의력, 평점_weighted])


def feature_map(index, value):
    if 0 <= index <= 2:
        value = value / 3
        return ['블렌디드', '원격', '일반'][index] if value > 0 else None
    elif 3 <= index <= 7:
        return ['전자출결', '직접호명', '모름', '복합적', '반영안함'][index - 3] if value == 1 else None
    elif index == 8:
        if value == 0.2:
            return '시험 없음'
        elif value == 0.4:
            return '시험1번'
        elif value == 0.6:
            return '시험2번'
        elif value == 0.8:
            return '시험3번'
        else:
            return '시험4번이상'
    elif index == 9:
        return '과제많음' if value == 1 else '과제없음' if value == 0 else '과제보통/모름'
    elif index == 10:
        return '조모임많음' if value == 1 else '조모임없음' if value == 0 else '조모임보통/모름'
    elif 11 <= index <= 14:
        return ['너그러움', '보통', '모름', '깐깐함'][index - 11] if value == 1 else None
    elif index == 15:
        return '풀강' if value == 1 else '풀강X' if value == 0 else '모름'
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
     # === 1. 사용자 기본 정보 로드 (profile 맵)
    profile = user_input['profile']
    dept = profile['단과대학']
    major = profile['전공']
    sub = profile.get('세부전공')  # None이면 처리됨
    학년_영역 = str(profile['학년']) + "영역"

    # === 2. 파일 로드
    filename = f"강의_벡터화_{dept}_{major}_{sub}.csv" if sub else f"강의_벡터화_{dept}_{major}.csv"
    df = pd.read_csv(filename, encoding='utf-8-sig')
    df = df[df['영역'].str.contains(학년_영역)].copy()

    # === 3. 과거 수강 과목 제거
    prev_subjects = set([p['과목명'] for p in previous_courses])
    df = df[~df['과목명'].isin(prev_subjects)]

    # === 4. 벡터화 및 유사도 계산
    df['parsed_vector'] = df['전체벡터'].apply(ast.literal_eval)
    lecture_matrix = np.array(df['parsed_vector'].tolist())[:, :18]

    user_vec = vectorize_user_input(user_input).reshape(1, -1)
    sim = cosine_similarity(normalize(user_vec), normalize(lecture_matrix))[0]
    df['유사도'] = sim

    # === 5. 상위 추천 5개 출력
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
