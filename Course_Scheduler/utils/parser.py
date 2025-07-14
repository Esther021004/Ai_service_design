import pandas as pd
from collections import defaultdict
import random

# CSV 로드 함수 (매번 호출 시 메모리 절약 가능)
def load_course_csv(csv_path: str = 'data/합쳐진_파일_최종_필요컬럼만_수정.csv') -> pd.DataFrame:
    return pd.read_csv(csv_path)

# 시간표 파싱 함수: '화/1-3,목/1' -> {'화': [1, 2, 3], '목': [1]}
def parse_timeslot(timestr: str):
    if timestr.strip() == '미정':
        return None
    try:
        parts = timestr.split(',')
        result = defaultdict(list)
        for part in parts:
            day, time_part = part.strip().split('/')
            time_part = time_part.strip('[]')
            if '-' in time_part:
                start, end = map(int, time_part.split('-'))
                result[day.strip()].extend(range(start, end + 1))
            else:
                result[day.strip()].append(int(time_part))
        return {day: sorted(set(times)) for day, times in result.items()}
    except:
        return None

# 시간표 겹침 검사 함수
def is_overlapping(new_time: dict, existing_schedule: list) -> bool:
    for day in new_time:
        new_slots = set(new_time[day])
        for lec in existing_schedule:
            if day in lec['시간표']:
                if new_slots & set(lec['시간표'][day]):
                    return True
    return False

# 분반 여부 판단 및 랜덤 선택 함수
def get_random_course_row(df: pd.DataFrame, subject: str, professor: str):
    matches = df[(df['교과목명'] == subject) & (df['교수'] == professor)]
    if matches.empty:
        return None, False
    selected = matches.sample(n=1).iloc[0]
    is_divided = len(matches) > 1
    return selected, is_divided
