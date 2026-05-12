# 점주 앱 수확 예측 입력/출력 매핑

작성일: 2026-05-11

## 목적

점주 앱의 `수확 예측` 화면은 백엔드 ML 예측 API를 호출한다. 다만 점주 화면에는 개발자용 필드명이나 모델 내부 용어를 그대로 노출하지 않는다. 화면에는 점주가 이해할 수 있는 업무 표현으로 번역해서 보여주고, 실제 API 필드와 계산 의미는 이 문서에서 추적한다.

## 호출 API

- 우선 호출: `POST /api/v1/owner/ml/predictions/auto-weather`
- 보조 호출: `POST /api/v1/owner/ml/predictions`
- 날씨 피처 단독 조회: `GET /api/v1/weather/features?stn_id=136&target_year=2026`
- 인증: 점주 로그인 후 `Authorization: Bearer {access_token}`
- 우선 호출 요청 구조:

```json
{
  "farm_id": 3,
  "product_id": 5,
  "target_year": 2026,
  "stn_id": "136",
  "past_yield_kg": 610,
  "market_price": 39000,
  "variety": "양광"
}
```

- 보조 호출 요청 구조:

```json
{
  "farm_id": 3,
  "product_id": 5,
  "features": {
    "past_yield_kg": 610,
    "market_price": 39000,
    "variety": "양광",
    "mar_avg_temp": 8.5,
    "aug_sunshine": 210,
    "oct_rainfall": 65,
    "aug_humidity": 72
  }
}
```

## 입력값 매핑

| 백엔드 필드 | 앱 화면 표현 | 현재 앱 입력/출처 | 판단 |
| --- | --- | --- | --- |
| `farm_id` | 선택 상품의 농장 | 상품/농장 조회 결과 | 점주가 직접 입력하지 않는다. 상품 선택으로 자동 결정한다. |
| `product_id` | 상품 | `수확 예측` 화면 상품 드롭다운 | 점주가 상품을 선택한다. |
| `past_yield_kg` | 최근 기준 수확량 | 점주가 kg 단위로 조정 | 앱 직접 입력이 적절하다. 향후 과거 수확 기록이 있으면 기본값으로 자동 제안한다. |
| `market_price` | 기준 판매가 | 상품 등록 가격 | 점주가 예측 화면에서 직접 입력하기보다 상품 가격 또는 시세 데이터에서 가져오는 것이 적절하다. |
| `variety` | 품종 | 상품 등록값 | 상품 선택으로 자동 결정한다. |
| `target_year` | 예측 기준 연도 | 앱에서 현재 연도를 전달 | 백엔드가 KMA ASOS 일별 데이터를 조회할 기준 연도다. |
| `stn_id` | 기상 관측 지점 | 기본값 `136` | 앱은 KMA 키를 알 필요 없이 백엔드에 지점 번호만 전달한다. |
| `mar_avg_temp` | 3월 평균기온 | 백엔드 KMA 날씨 API 결과 | auto-weather 실패 시 앱 프리셋 보조값을 사용한다. |
| `aug_sunshine` | 8월 일조량 | 백엔드 KMA 날씨 API 결과 | auto-weather 실패 시 앱 프리셋 보조값을 사용한다. |
| `oct_rainfall` | 10월 강수량 | 백엔드 KMA 날씨 API 결과 | auto-weather 실패 시 앱 프리셋 보조값을 사용한다. 예약 안전계수와 주의 문구에 영향을 준다. |
| `aug_humidity` | 8월 습도 | 백엔드 KMA 날씨 API 결과 | auto-weather 실패 시 앱 프리셋/작황 보조값을 사용한다. |

## 현재 앱 프리셋

정상 흐름에서는 백엔드가 `GET /weather/features`와 같은 날씨 피처 로직을 내부 호출해 값을 만든다. 앱의 `최근 기상 기준` 프리셋은 KMA 키 누락, KMA 장애, 백엔드 실패 시 끊김 없이 예측을 보여주기 위한 보조값이다.

점주 화면은 복잡한 기상 수치 입력 대신 `최근 기상 기준`을 선택하게 한다. 앱은 이를 아래 수치로 변환해 API에 전달한다.

| 화면 선택 | 3월 평균기온 | 8월 일조량 | 10월 강수량 | 8월 습도 |
| --- | ---: | ---: | ---: | ---: |
| 평년 수준 | 8.5도 | 210시간 | 65mm | 72% |
| 고온 | 10.2도 | 245시간 | 52mm | 66% |
| 저온 | 5.8도 | 184시간 | 71mm | 74% |
| 강수 많음 | 8.1도 | 158시간 | 132mm | 86% |

`재배 상태`는 현재 아래처럼 보정한다.

| 화면 선택 | 보정 |
| --- | --- |
| 양호 | 추가 보정 없음 |
| 관수 필요 | 8월 습도 -6 |
| 병해 확인 | 8월 일조량 -18, 8월 습도 +5 |

## 응답값 의미

| 백엔드 필드 | 앱 화면 표현 | 의미 |
| --- | --- | --- |
| `prediction_id` | 화면 직접 표시 없음 | 예측 결과 저장 ID. 수확 슬롯 생성 시 연결된다. |
| `unit_yield_kg_10a` | 값: `nkg`, 라벨: `1,000㎡ 기준 수확량` | 표준 재배면적 기준 수확량. `10a`는 `1,000㎡`, 약 `302.5평`, `0.1ha`이다. |
| `predicted_harvest_start` | 예측 수확 날짜 | 예상 수확 시작일. |
| `predicted_harvest_end` | 예측 수확 날짜 | 예상 수확 종료일. |
| `estimated_yield_kg` | 예상 수확량 | 선택한 농장/상품 기준으로 보정된 총 예상 수확량. |
| `suggested_reservable_min_kg` | 권장 예약량 하한 | 고객에게 열어도 되는 보수적 최소 예약 수량. |
| `suggested_reservable_max_kg` | 권장 예약량 상한 | 고객에게 열어도 되는 최대 권장 예약 수량. 슬롯 확정 기본값으로 사용한다. |
| `recommended_price` | 권장 판매가 | 기준 판매가와 품종 보정을 반영한 권장 판매가. |
| `confidence` | 신뢰도 | 예측 신뢰도. 현재 백엔드 기본값은 `0.78`이다. |
| `safety_factor` | 화면 직접 표시 없음 | 권장 예약량 계산에 쓰는 안전계수. 비가 많으면 낮아진다. |
| `warning_message` | 상태 문구 | `정상`, `수확기 강수량 주의 필요` 같은 점주용 상태 문구. |
| `model_version` | 화면 직접 표시 없음 | 개발 검증용 모델 버전. Flutter debug 로그에서 확인한다. |

## 화면 표현 원칙

- 점주 화면에는 `API`, `feature`, `model_version`, `10a` 같은 개발/전문 용어를 그대로 노출하지 않는다.
- `features`는 `예측에 반영된 기준`으로 번역해서 보여준다.
- `unit_yield_kg_10a`는 카드 overflow를 피하기 위해 값과 기준 면적을 분리한다. 값은 `1510kg`, 라벨은 `1,000㎡ 기준 수확량`, 신뢰도 카드 배지는 `1510kg/1,000㎡`처럼 표시한다.
- `confidence`는 정상 호출 시 백엔드 응답값을 그대로 표시한다. API 실패로 보조 계산값을 쓰는 경우에는 앱 내부 보조값이 표시되며, 이 여부는 debug console에서만 확인한다.
- 수확량 차트는 백엔드가 별도 일자별 예측 배열을 주는 구조가 아니므로, `estimated_yield_kg`와 `confidence`를 기준으로 앱에서 만든 참고 추이다. 각 막대에는 kg 수치를 함께 표시한다.
- `market_price`는 `기준 판매가`, `variety`는 `품종`, 기상 수치는 `날씨 기준`, 작황 보정은 `작황 보정`으로 표시한다.
- 실제 API 요청/응답 원문과 fallback 여부는 Flutter debug console의 `[API 정상]`, `[API 폴백]` 로그로 확인한다.

## 검증 기준

정상 API 호출 시 debug console에는 다음 정보가 남아야 한다.

```text
[API 정상][harvest.prediction] request=... result=id=..., model=rf-apple-harvest-v1, unitYield10a=..., estimated=..., reservable=..., price=..., period=...
```

API 실패 또는 세션 만료로 앱 내부 보조 계산값을 쓰면 다음 정보가 남아야 한다.

```text
[API 폴백][harvest.prediction] 수확 예측 API 실패...
[API 폴백][harvest.prediction] fallback result=...
```

발표 화면에서는 fallback이라는 단어가 보이면 안 된다. fallback 여부는 개발자가 debug console에서만 확인한다.
