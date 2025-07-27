# utils/credit_calc.py
from typing import List, Dict

def compute_credit_ratios(courses: list[dict]) -> dict:
    """
    저장된 수강 강의 데이터를 기반으로 졸업학점(130학점) 대비
    전공/교양/교직 비율을 계산하는 함수

    Args:
        courses (list[dict]): 이전 수강 강의 리스트
            예: [{"이수구분": "전공", "학점": 3}, ...]

    Returns:
        dict: 영역별 비율 및 학점 합계
    """

    GRADUATION_CREDIT = 130  # 졸업 요건 학점 (고정값)
    
    major = sum(course.get("학점", 0) for course in courses if course.get("이수구분") == "전공")
    liberal = sum(course.get("학점", 0) for course in courses if course.get("이수구분") == "교양")
    teaching = sum(course.get("학점", 0) for course in courses if course.get("이수구분") == "교직")

    def ratio(val): return round((val / GRADUATION_CREDIT) * 100, 2)

    return {
        "전체 학점": GRADUATION_CREDIT,
        "전공": major,
        "교양": liberal,
        "교직": teaching,
        "전공 비율": ratio(major),
        "교양 비율": ratio(liberal),
        "교직 비율": ratio(teaching)
    }
