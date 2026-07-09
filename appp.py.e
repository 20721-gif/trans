# 수정된 데이터 불러오기 코드
@st.cache_data
def load_data():
    # 파일 자체를 UTF-8로 변환했으므로 인코딩 지정 불필요 (기본값이 utf-8)
    df = pd.read_csv('서울시 시간별 (초)미세먼지_2025년.csv')
    
    df['일시'] = pd.to_datetime(df['일시'])
    df = df.dropna(subset=['미세먼지(PM10)', '초미세먼지(PM25)'])
    df['미세먼지(PM10)'] = pd.to_numeric(df['미세먼지(PM10)'], errors='coerce')
    df['초미세먼지(PM25)'] = pd.to_numeric(df['초미세먼지(PM25)'], errors='coerce')
    
    return df
