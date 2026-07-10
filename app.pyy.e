import streamlit as st
import pandas as pd
import plotly.express as px

# 페이지 기본 설정
st.set_page_config(page_title="서울시 미세먼지 대시보드", page_icon="☁️", layout="wide")

# 데이터 불러오기 및 캐싱 (로딩 속도 최적화)
@st.cache_data
def load_data():
    file_path = '서울시 시간별 (초)미세먼지_2025년.csv'
    
    # 여러 인코딩 방식을 순차적으로 시도하여 에러 방지
    encodings = ['utf-8', 'cp949', 'euc-kr', 'utf-8-sig']
    df = None
    
    for enc in encodings:
        try:
            df = pd.read_csv(file_path, encoding=enc)
            break  # 읽기 성공 시 반복문 탈출
        except UnicodeDecodeError:
            continue
            
    # 모든 인코딩 시도 실패 시 에러 메시지 출력
    if df is None:
        st.error("데이터 파일을 읽는 데 실패했습니다. 파일 인코딩을 확인해주세요.")
        return pd.DataFrame()
    
    # 일시 데이터를 datetime 형식으로 변환
    df['일시'] = pd.to_datetime(df['일시'], errors='coerce')
    
    # 결측치(NaN)가 있는 행 제거
    df = df.dropna(subset=['미세먼지(PM10)', '초미세먼지(PM25)'])
    
    # 숫자형 데이터로 변환 (만약 문자로 인식되었을 경우 대비)
    df['미세먼지(PM10)'] = pd.to_numeric(df['미세먼지(PM10)'], errors='coerce')
    df['초미세먼지(PM25)'] = pd.to_numeric(df['초미세먼지(PM25)'], errors='coerce')
    
    return df

# 데이터 로드
df = load_data()

# 데이터가 정상적으로 로드되었을 때만 화면 렌더링
if not df.empty:
    # 메인 타이틀
    st.title("☁️ 2025년 서울시 (초)미세먼지 시각화 대시보드")
    st.markdown("제공된 시간별 데이터를 바탕으로 서울시 자치구별 미세먼지(PM10)와 초미세먼지(PM25) 농도를 분석합니다.")

    # 사이드바 설정 (필터링)
    st.sidebar.header("📊 데이터 필터링")

    # 자치구 목록 추출 ('평균'을 맨 앞으로)
    districts = df['구분'].unique().tolist()
    if '평균' in districts:
        districts.insert(0, districts.pop(districts.index('평균')))

    selected_district = st.sidebar.selectbox("구/구분 선택", districts)

    # 선택한 자치구 데이터 필터링
    filtered_df = df[df['구분'] == selected_district].sort_values('일시')

    # --- 시각화 1: 시간에 따른 미세먼지 변화 (선 그래프) ---
    st.subheader(f"📈 {selected_district} 시간별 미세먼지 추이")
    fig1 = px.line(filtered_df, x='일시', y=['미세먼지(PM10)', '초미세먼지(PM25)'],
                   labels={'value': '농도 (µg/m³)', 'variable': '먼지 종류', '일시': '시간'},
                   color_discrete_map={'미세먼지(PM10)': '#1f77b4', '초미세먼지(PM25)': '#d62728'})
    st.plotly_chart(fig1, use_container_width=True)

    # --- 시각화 2: 전체 자치구 평균 비교 (막대 그래프) ---
    st.subheader("📊 서울시 자치구별 평균 (초)미세먼지 농도 비교 ('평균' 항목 제외)")
    # '평균' 데이터를 제외하고 자치구별 평균 계산
    gu_df = df[df['구분'] != '평균']
    avg_df = gu_df.groupby('구분')[['미세먼지(PM10)', '초미세먼지(PM25)']].mean().reset_index()

    fig2 = px.bar(avg_df, x='구분', y=['미세먼지(PM10)', '초미세먼지(PM25)'], 
                  barmode='group',
                  labels={'value': '평균 농도 (µg/m³)', 'variable': '먼지 종류', '구분': '자치구'})
    st.plotly_chart(fig2, use_container_width=True)

    # --- 원본 데이터 확인 ---
    st.subheader("📋 데이터 표 확인")
    st.dataframe(filtered_df.style.format({'미세먼지(PM10)': '{:.1f}', '초미세먼지(PM25)': '{:.1f}'}))
