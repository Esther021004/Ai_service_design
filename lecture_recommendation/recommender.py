import pandas as pd
import ast
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import normalize

# === 사용자 벡터화 함수들 ===
def convert_exam_count_scaled(value):
    if '없' in value: return 0.2
    if '한' in value: return 0.4
    if '두' in value: return 0.6
    if '세' in value: return 0.8
    if '네' in value or '4' in value: return 1.0
    return 0.4

def rating_to_custom_bucket(score):
    try: score = float(score)
    except: return 0.0
    if score <= 1: return 0.1
    elif score <= 2: return 0.2
    elif score <= 3: return 0.3
    elif score <= 4: return 0.4
    else: return 0.5

def encode_attendance(value, types): return [1 if value == t else 0 for t in types]
def encode_grade(value, types): return [1 if value == g else 0 for g in types]
def encode_class_time(value): return 1 if value == '풀강' else 0
def encode_lecture_quality(value): return {'좋음': 1.0, '보통': 0.5, '나쁘다': 0.0}.get(value, 0.5)

def vectorize_user_input(user_input, class_types, campuses, attendance_types, grade_types):
    vec = [
        convert_exam_count_scaled(user_input['시험']),
        1 if user_input['과제'] == '있음' else 0,
        1 if user_input['조모임'] == '있음' else 0,
        *encode_attendance(user_input['출결'], attendance_types),
        *encode_grade(user_input['성적'], grade_types),
        encode_class_time(user_input['강의 시간']),
        encode_lecture_quality(user_input['강의력']),
    ]
    vec += [1 if user_input['수업유형'] == ct else 0 for ct in class_types]
    vec[-3:] = [x * 3 for x in vec[-3:]]  # 수업유형 가중치
    vec += [1 if user_input['캠퍼스'] == cp else 0 for cp in campuses]
    vec.append(rating_to_custom_bucket(user_input['평점']) * 2)  # 평점 가중치
    return vec

# === 추천 로직 함수들 ===
# (생략: recommend_top_n, get_top_3_features_flexible, feature_map 등 포함)
def recommend_top_n(df, user_vector, top_n):
    if df.empty:
        return pd.DataFrame(columns=['과목명', '교수명', '시간표', '개설학과전공', '영역'])

    df = df.copy()

    def try_parse_vector(x):
        try: return ast.literal_eval(x) if isinstance(x, str) else x
        except: return None

    df['전체 벡터'] = df['전체 벡터'].apply(try_parse_vector)
    df = df[df['전체 벡터'].apply(lambda x: isinstance(x, list) and all(isinstance(i, (int, float)) for i in x))]
    if df.empty:
        return pd.DataFrame(columns=['과목명', '교수명', '시간표', '개설학과전공', '영역'])

    lecture_vectors = normalize(df['전체 벡터'].tolist())
    user_vector = normalize([user_vector])[0]
    df['유사도'] = cosine_similarity([user_vector], lecture_vectors)[0]
    return df.sort_values(by='유사도', ascending=False)[['과목명', '교수명', '시간표', '개설학과전공', '영역']].head(top_n)

# === 기여도 기반 피처 추천 이유 추출 ===
def get_top_3_features_flexible(user_vector, lecture_vector):
    contributions = [1 - abs(u - l) for u, l in zip(user_vector, lecture_vector)]
    sorted_indices = sorted(range(len(contributions)), key=lambda i: contributions[i], reverse=True)
    reasons = []
    for i in sorted_indices:
        reason = feature_map(i, lecture_vector[i])
        if reason and reason not in reasons:
            reasons.append(reason)
        if len(reasons) == 3:
            break
    return reasons

# === 피처 인덱스를 텍스트로 변환 ===
def reverse_exam_score(value):
    if value == 0.2: return '시험X'
    elif value == 0.4: return '시험1번'
    elif value == 0.6: return '시험2번'
    elif value == 0.8: return '시험3번'
    else: return '시험4번이상'

def reverse_rating(value):
    if value == 0.2: return '평점≤1'
    elif value == 0.4: return '평점≤2'
    elif value == 0.6: return '평점≤3'
    elif value == 0.8: return '평점≤4'
    else: return '평점≤5'

def feature_map(index, value):
    if index == 0:
        return reverse_exam_score(value)
    elif index == 1:
        return "과제O" if value == 1 else "과제X"
    elif index == 2:
        return "조모임O" if value == 1 else "조모임X"
    elif 3 <= index <= 7:
        labels = ['전자출결', '직접호명', '모름', '복합적', '반영안함']
        return f"{labels[index - 3]}" if value == 1 else None
    elif 8 <= index <= 11:
        labels = ['너그러움', '보통', '모름', '깐깐함']
        return f"{labels[index - 8]}" if value == 1 else None
    elif index == 12:
        return "풀강" if value == 1 else "풀강X"
    elif index == 13:
        if value >= 0.9: return "강의력좋음"
        elif value >= 0.4: return "강의력보통"
        else: return "강의력나쁨"
    elif 14 <= index <= 16:
        labels = ['블렌디드', '원격', '일반']
        if value > 0: return f"{labels[index - 14]}"
    elif 17 <= index <= 18:
        labels = ['수정', '운정']
        if round(value) == 1:
            return f"{labels[index - 17]}"
    elif index == 19:
        return reverse_rating(value)
    return None

# === 추천 이유 포함 추천 함수 ===
def recommend_top_n_with_reasons(df, user_vector, top_n, required_subjects=None):
    df = df.copy()
    df['전체 벡터'] = df['전체 벡터'].apply(lambda x: ast.literal_eval(x) if isinstance(x, str) else x)
    df = df[df['전체 벡터'].apply(lambda x: isinstance(x, list) and all(isinstance(i, (int, float)) for i in x))]
    if df.empty:
        return pd.DataFrame(columns=['과목명', '교수명', '시간표', '캠퍼스', '추천 이유'])

    lecture_vectors = normalize(df['전체 벡터'].tolist())
    user_vector = normalize([user_vector])[0]
    df['유사도'] = cosine_similarity([user_vector], lecture_vectors)[0]

    top_df = df.sort_values(by='유사도', ascending=False).head(top_n * 2).copy()
    reasons_list = []

    for _, row in top_df.iterrows():
        vec = row['전체 벡터']
        if required_subjects and row['과목명'] in required_subjects:
            reasons_list.append("학년별 필수 수강 과목")
        else:
            reasons = get_top_3_features_flexible(user_vector, vec)
            reasons_list.append(", ".join(reasons))

    top_df['추천 이유'] = reasons_list
    return top_df[['과목명', '교수명', '시간표', '캠퍼스', '추천 이유']]

# === 필수 강의 포함 최종 추천 리스트 생성 ===
def append_required_lectures(required_list, recommended_df, top_n):
    required_df = pd.DataFrame(required_list, columns=['과목명', '교수명', '시간표', '개설학과전공', '영역', '캠퍼스']) if required_list else pd.DataFrame()
    if not required_df.empty:
        required_df['추천 이유'] = '학년별 필수 수강 과목'
        merged = pd.concat([required_df[['과목명', '교수명', '시간표', '캠퍼스', '추천 이유']], recommended_df])
        return merged.drop_duplicates(subset=['과목명', '교수명', '시간표']).head(top_n)
    else:
        return recommended_df.head(top_n)

# === 추천 실행 함수 ===
def get_recommendations(user_input: dict) -> dict:
    major = user_input.get("전공")
    grade = int(user_input.get("학년"))
    sub_major = user_input.get("세부전공") or None

    # === 카테고리 정의 ===
    class_types = ['블렌디드', '원격', '일반']
    campuses = ['수정', '운정']
    attendance_types = ['전자출결', '직접호명', '모름', '복합적', '반영안함']
    grade_types = ['너그러움', '보통', '모름', '깐깐함']

    user_vector = vectorize_user_input(user_input, class_types, campuses, attendance_types, grade_types)

    # === CSV 파일 로드 ===
    df_major = pd.read_csv("data/vector_major.csv", encoding="utf-8")
    df_gyoyang = pd.read_csv("data/vector_gyoyang.csv", encoding="cp949")
    df_jinro = pd.read_csv("data/vector_jinro.csv", encoding="utf-8")

    # === 필터링 ===
    valid_majors = ['공과대학', major] + ([sub_major] if sub_major else [])
    df_major_filtered = df_major[df_major['개설학과전공'].isin(valid_majors) & df_major['영역'].astype(str).str.contains(f"{grade}영역")]
    df_jinro_filtered = df_jinro[df_jinro['학년'] == grade].copy()

    # === 필수 과목 리스트 ===
    required_jinro_list = [
        ['전공별 진로 탐색', '이정은', '금/8', '공통', '도전과실천', '없음']
    ] if grade == 1 else []

    required_major_lectures = {
        'AI융합학부': [
            ['파이썬프로그래밍', '장재경', '월/4-6', 'AI융합학부', 'SW문해', '수정'],
            ['파이썬프로그래밍', '정영범', '월/4-6', 'AI융합학부', 'SW문해', '수정'],
            ['파이썬프로그래밍', '차영화', '화/1-3', '공통', 'SW문해', '운정'],
            ['파이썬프로그래밍', '이두열', '목/1-3', '공통', 'SW문해', '운정'],
            ['파이썬프로그래밍', '유정화', '목/4-6', '공통', 'SW문해', '운정'],
            ['기초 통계학', '원형묵', '수/4-6', 'AI융합학부', '경험적수리적추리', '수정'],
            ['기초 통계학', '김계완', '수/4-6', 'AI융합학부', '경험적수리적추리', '수정'],
            ['기초 통계학', '문준서', '금/4-6', 'AI융합학부', '경험적수리적추리', '수정'],
            ['비판적 사고와 토론', ' ', '금/3-4', 'AI융합학부', '영역없음', '수정']
        ],
        '컴퓨터공학과': [
            ['파이썬프로그래밍', '심광섭', '목/1-3', '컴퓨터공학과', 'SW문해', '수정'],
            ['파이썬프로그래밍', '차영화', '화/1-3', '공통', 'SW문해', '운정'],
            ['파이썬프로그래밍', '이두열', '목/1-3', '공통', 'SW문해', '운정'],
            ['파이썬프로그래밍', '유정화', '목/4-6', '공통', 'SW문해', '운정'],
            ['기초 통계학', '원형묵', '수/4-6', '컴퓨터공학과', '경험적수리적추리', '수정'],
            ['기초 통계학', '김계완', '수/4-6', '컴퓨터공학과', '경험적수리적추리', '수정'],
            ['기초 통계학', '문준서', '금/4-6', '컴퓨터공학과', '경험적수리적추리', '수정'],
            ['비판적 사고와 토론', ' ', '수/3-4', '컴퓨터공학과', '영역없음', '수정']
        ],
        '융합보안공학과': [
            ['파이썬프로그래밍', '김경진', '목/4-6', '융합보안공학과', 'SW문해', '수정'],
            ['파이썬프로그래밍', '차영화', '화/1-3', '공통', 'SW문해', '운정'],
            ['파이썬프로그래밍', '이두열', '목/1-3', '공통', 'SW문해', '운정'],
            ['파이썬프로그래밍', '유정화', '목/4-6', '공통', 'SW문해', '운정'],
            ['기초 통계학', '원형묵', '수/4-6', '융합보안공학과', '경험적수리적추리', '수정'],
            ['기초 통계학', '김계완', '수/4-6', '융합보안공학과', '경험적수리적추리', '수정'],
            ['기초 통계학', '문준서', '금/4-6', '융합보안공학과', '경험적수리적추리', '수정'],
            ['비판적 사고와 토론', ' ', '월/3-4', '융합보안공학과', '영역없음', '수정']
        ],
        '서비스디자인공학과': [
            ['파이썬프로그래밍', '김대영', '월/4-6', '서비스디자인공학과', 'SW문해', '수정'],
            ['파이썬프로그래밍', '정영희', '목/7-9', '서비스디자인공학과', 'SW문해', '수정'],
            ['파이썬프로그래밍', '차영화', '화/1-3', '공통', 'SW문해', '운정'],
            ['파이썬프로그래밍', '이두열', '목/1-3', '공통', 'SW문해', '운정'],
            ['파이썬프로그래밍', '유정화', '목/4-6', '공통', 'SW문해', '운정'],
            ['기초 통계학', '원형묵', '수/4-6', '서비스디자인공학과', '경험적수리적추리', '수정'],
            ['기초 통계학', '김계완', '수/4-6', '서비스디자인공학과', '경험적수리적추리', '수정'],
            ['기초 통계학', '문준서', '금/4-6', '서비스디자인공학과', '경험적수리적추리', '수정'],
            ['비판적 사고와 토론', ' ', '금/3-4', '서비스디자인공학과', '영역없음', '수정']
        ],
        '바이오생명공학과': [
            ['일반생물학 I', '윤진호', '월/1-3', '바이오생명공학과', '자연의설명', '운정'],
            ['비판적 사고와 토론', ' ', '금/1-2', '바이오생명공학과', '영역없음', '운정']
        ],
        '바이오신약의과학부': [
            ['일반생물학 I', '현경아', '월/1-3', '바이오신약의과학부', '자연의설명', '운정'],
            ['일반생물학 I', '현경아', '수/1-3', '바이오신약의과학부', '자연의설명', '운정'],
            ['미적분과 벡터해석 기초', '조명원', '목/7-9', '바이오신약의과학부', '경험적수리적추리', '운정'],
            ['비판적 사고와 토론', ' ', '금/1-2', '바이오신약의과학부', '영역없음', '운정']
        ],
        '바이오식품공학과': [
            ['일반생물학 I', '권혜경', '월/1-3', '바이오식품공학과', '자연의설명', '운정'],
            ['미적분과 벡터해석 기초', '안소영', '목/1-3', '바이오식품공학과', '경험적수리적추리', '운정'],
            ['비판적 사고와 토론', ' ', '금/3-4', '바이오식품공학과', '영역없음', '운정']
        ],
        '화학에너지융합학부': [
            ['미적분과 벡터해석 기초', '최현옥', '화/7-9', '화학에너지융합학부', '경험적수리적추리', '운정']
        ]
    }
    required_gyo_list = required_major_lectures.get(major, []) if grade == 1 else []

    # === 교양 추천 처리
    top_gyo_raw = recommend_top_n(df_gyoyang, user_vector, 20)
    top_gyo_result = []
    added_subjects = set()

    # 1학년인 경우 필수 강의 먼저 추가 (캠퍼스 무관)
    if grade == 1 and major in required_major_lectures:
        df_required = pd.DataFrame(required_major_lectures[major],
                                   columns=['과목명', '교수명', '시간표', '개설학과전공', '영역', '캠퍼스']
                                   )
        for _, row in df_required.iterrows():
            if row['과목명'] not in added_subjects:
                top_gyo_result.append(row.to_dict())
                added_subjects.add(row['과목명'])

    # 유사도 기반 추천 중 중복되지 않은 과목만 추가
    for _, row in top_gyo_raw.iterrows():
        if row['과목명'] not in added_subjects:
            top_gyo_result.append(row)
            added_subjects.add(row['과목명'])
        if len(top_gyo_result) >= 14:
            break

    # === 전공
    top_major = recommend_top_n_with_reasons(df_major_filtered, user_vector, 5)

    # === 교양
    recommended_gyo = recommend_top_n_with_reasons(df_gyoyang, user_vector, 20, required_subjects=[r[0] for r in required_gyo_list])
    final_gyo = append_required_lectures(required_gyo_list, recommended_gyo, 14)

    # === 진로소양
    recommended_jinro = recommend_top_n_with_reasons(df_jinro_filtered, user_vector, 5, required_subjects=[r[0] for r in required_jinro_list])
    final_jinro = append_required_lectures(required_jinro_list, recommended_jinro, 2)

    # === 캠퍼스 인코딩 → 텍스트
    def convert_campus_column(df):
        df = df.copy()

        def to_label(x):
            try:
                # 문자열 "[1, 0]" 혹은 [1, 0] 둘 다 처리
                if isinstance(x, str) and x.startswith("["):
                    x = ast.literal_eval(x)
                if x == [1, 0]: return '수정'
                if x == [0, 1]: return '운정'
            except Exception:
                pass
            return x  # 처리 안 되는 경우 그대로 반환

        df['캠퍼스'] = df['캠퍼스'].apply(to_label)
        return df

    major_json = convert_campus_column(top_major).to_dict(orient="records")
    gyo_json = convert_campus_column(final_gyo).to_dict(orient="records")
    jinro_json = convert_campus_column(final_jinro).to_dict(orient="records")

    return {
        "전공": major_json,
        "교양": gyo_json,
        "진로소양": jinro_json
    }
