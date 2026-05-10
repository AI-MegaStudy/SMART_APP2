# Owner App Requirements Coverage

Source docs:
- `04_요구사항_정의서.md`
- `docs/08_점주_관리앱_화면설계_기능정의서.md`

## Current Rule

화면은 단순 그림으로 남겨두지 않는다. API가 이미 있는 기능은 실제 API/DB 저장까지 연결하고, DB/API가 부족해 fallback을 쓰는 경우에도 화면에는 개발자용 `더미`, `Mock`, `fallback` 표현을 노출하지 않는다.

## 점주 앱 기능 매핑

| Screen | Requirement | Status | Evidence / action |
|---|---|---|---|
| O-001 로그인 | 점주 로그인, JWT 발급 | Done | `POST /auth/login`, `GET /me`, OWNER role 검증 |
| O-002 대시보드 | 오늘 처리 업무 카운트 | Done | `GET /owner/dashboard`; seed 상태별 카운트 검증 |
| O-003 농장 관리 | 농장 정보/정책 수정 | Done | `GET /owner/farms/me`, `PUT /owner/farms/{farmId}`, `POST /owner/farms/{farmId}/image`. 생성형 AI 농장 이미지 seed 적용 |
| O-004 상품 관리 | 상품 등록/수정/상태 변경 | Done | `GET/POST/PUT /owner/products`, `POST /owner/products/{productId}/image`, `PATCH /status` API smoke. 등록/수정 폼에 대표 이미지와 상품 소개 입력 포함 |
| O-005 ML 예측 | 농장/상품/환경값/과거 수확량 입력 후 결과 저장 | Done | 수확 예측 화면에 입력값 selector/stepper 추가, `POST /owner/ml/predictions` 저장 smoke 통과 |
| O-006 수확 슬롯 확정 | 예측 참고 후 점주 확정값 저장 | Done | 예측값 그대로 저장하지 않고 날짜/kg/판매가/고객 안내 문구를 점주가 조정 후 `POST /owner/harvest-slots` smoke 통과 |
| O-007 예약/주문 현황 | 예약/주문 상태 확인 | Done | `GET /owner/orders`, `GET /owner/reservations` 탭 분리. 긴 내부 주문번호는 화면에 직접 노출하지 않음 |
| O-008 발주 목록 | 발주 목록 확인 | Done | `GET /owner/procurements` |
| O-009 발주 상세/결정 | 승인/부분승인/거절 저장 | Done | 상세 결정 화면, `PATCH /owner/procurements/{id}/decision`. API 데이터가 없을 때도 품목별 수량 조정과 로컬 처리 흐름 유지 |
| O-010 신선도 검사 | 이미지 선택/분석/점주 판정 저장 | Done | 갤러리 선택 버튼/카드 탭 연결, 추천등급/신선도/색상/형태/멍 확률 표시, 분석 실패 시 선택 이미지 기준 보조 판정 표시, `POST /owner/quality-inspections` 저장 |
| O-011 배송 관리 | 배송 등록/상태 변경 | Done | `POST /owner/shipments`, `PATCH /owner/shipments/{id}/status`. 송장 스캔 액션은 발표용 송장 입력 보조 흐름으로 동작 |
| O-012 반품/환불 관리 | 승인/거절, 환불 처리 | Done | `GET /owner/returns`, `PATCH /owner/returns/{id}/decision` |
| O-013 내 정보 | 점주 기본 정보 수정 | Done | `GET/PUT /owner/profile` |

## Follow-up

- O-005/O-006은 임시 prediction/slot 생성 후 DB 정리하는 smoke로 검증했다.
- O-010은 이미지 선택 UX와 분석 fallback을 보강했으며 iOS 사진 접근은 앱 재빌드 후 다시 확인한다.
- 계정 찾기/계정 지원 요청은 별도 운영 API 없이도 발표 흐름이 끊기지 않도록 접수/안내 UX로 처리한다.
