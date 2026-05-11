# Owner App Requirements Coverage

Source docs:
- `04_요구사항_정의서.md`
- `docs/08_점주_관리앱_화면설계_기능정의서.md`

Last updated: 2026-05-11

## Overall Progress

| Area | Progress | Current state |
|---|---:|---|
| 점주 앱 요구사항 화면 반영 | 92% | 요구사항상 핵심 점주 화면은 모두 실제 화면/동선으로 구현. 목록 중심인 주문/예약/배송 상세는 추가 보강 여지 |
| API/DB 실제 연결 | 88% | 계정, 상품, 농장, 수확 예측, 슬롯, 주문/예약, 발주, 신선도, 배송, 반품, 프로필 API 연결 |
| fallback 축소 | 90% | API 정상 응답 시 실제 DB를 우선 사용. 서버 장애/세션 만료/외부 모델 부재/플랫폼 제약 시에도 점주 업무 화면은 발표용 보조 흐름으로 유지 |
| 발표 완성도 | 94% | 개발자용 더미 문구 제거, 갤러리 UX/차트/상태 처리/선택형 입력 보강, 주요 저장/등록 실패 화면을 로컬 완료 흐름으로 대체 |
| 운영 이식 준비 | 80% | DB 스키마 차이 없음 확인, SMART_WEB endpoint migration script 작성 및 임시 적용 검증 |

## Current Rule

화면은 단순 그림으로 남겨두지 않는다. API가 이미 있는 기능은 실제 API/DB 저장까지 연결하고, DB/API가 부족해 fallback을 쓰는 경우에도 화면에는 개발자용 `더미`, `Mock`, `fallback` 표현을 노출하지 않는다.

현재 fallback 정책은 `API 정상 응답 > 실제 DB 데이터 표시`, `API 실패/세션 만료/외부 연동 부재 > 사용자에게 자연스러운 보조 흐름 표시`이다. 발표 중 끊기면 안 되는 점주 업무 화면은 상품/농장/프로필/수확/신선도/배송/발주/반품까지 로컬 보조 데이터 또는 화면상 완료 처리로 이어진다.

## 점주 앱 기능 매핑

| Screen | Requirement | Status | Evidence / action |
|---|---|---|---|
| O-001 로그인 | 점주 로그인, JWT 발급 | Done | `POST /auth/login`, `GET /me`, OWNER role 검증 |
| O-002 대시보드 | 오늘 처리 업무 카운트 | Done | `GET /owner/dashboard`; seed 상태별 카운트 검증 |
| O-003 농장 관리 | 농장 정보/정책 수정 | Done | `GET /owner/farms/me`, `PUT /owner/farms/{farmId}`, `POST /owner/farms/{farmId}/image`. 생성형 AI 농장 이미지 seed 적용 |
| O-004 상품 관리 | 상품 등록/수정/상태 변경 | Done | `GET/POST/PUT /owner/products`, `POST /owner/products/{productId}/image`, `PATCH /status` API smoke. 등록/수정 폼에 대표 이미지와 상품 소개 입력 포함 |
| O-005 ML 예측 | 농장/상품/환경값/과거 수확량 입력 후 결과 저장 | Done | 수확 예측 화면에 입력값 selector/stepper 추가, `POST /owner/ml/predictions` 저장 smoke 통과. 세션/API 실패 시 발표용 양광/부사 예측 fallback |
| O-006 수확 슬롯 확정/관리 | 예측 참고 후 점주 확정값 저장, 열린 슬롯 관리 | Done | 예측값 그대로 저장하지 않고 날짜/kg/판매가/고객 안내 문구를 점주가 조정 후 `POST /owner/harvest-slots` 저장. `GET/PUT/PATCH /owner/harvest-slots`로 슬롯 목록, 수량/가격/안내문 수정, 마감/재오픈 연결 |
| O-007 예약/주문 현황 | 예약/주문 상태 확인 | Done | `GET /owner/orders`, `GET /owner/reservations` 탭 분리. 긴 내부 주문번호는 화면에 직접 노출하지 않음 |
| O-008 발주 목록 | 발주 목록 확인 | Done | `GET /owner/procurements` |
| O-009 발주 상세/결정 | 승인/부분승인/거절 저장 | Done | 상세 결정 화면, `PATCH /owner/procurements/{id}/decision`. API 데이터가 없을 때도 품목별 수량 조정과 로컬 처리 흐름 유지 |
| O-010 신선도 검사 | 이미지 선택/분석/점주 판정 저장 | Done | 갤러리 선택 버튼/카드 탭 연결, 추천등급/신선도/색상/형태/멍 확률 표시, 분석/API/세션/갤러리 실패 시 검사 대상과 샘플 이미지 기준 보조 판정 표시, `POST /owner/quality-inspections` 저장 우선 |
| O-011 배송 관리 | 배송 등록/상태 변경 | Done | `POST /owner/shipments`, `PATCH /owner/shipments/{id}/status`. 배송 가능 발주/API가 부족해도 승인 발주 보조 데이터와 화면상 등록 완료 처리. 송장 스캔 액션은 발표용 송장 입력 보조 흐름으로 동작 |
| O-012 반품/환불 관리 | 승인/거절, 환불 처리, 고객 첨부 이미지 확인 | Done | `GET /owner/returns`, `PATCH /owner/returns/{id}/decision`, `evidence_image_url` 실제 이미지 표시/확대 |
| O-013 내 정보 | 점주 기본 정보 수정 | Done | `GET/PUT /owner/profile` |

## API / Migration Coverage

| Item | Status | Evidence |
|---|---|---|
| SMART_APP 추가 FastAPI endpoint | Done | 이메일 찾기, 비밀번호 재설정, 농장 이미지 업로드, 점주 배송 목록 endpoint 구현 |
| SMART_WEB 대비 차이 분석 | Done | `docs/planning/DB_AND_FASTAPI_DIFF_REPORT.md` |
| SMART_WEB 이식 스크립트 | Done | `scripts/migrate_owner_app_endpoints_to_smart_web.py` |
| SMART_WEB 실제 폴더 적용 | Pending | dry-run과 임시 복사본 `--apply`는 검증 완료. 실제 SMART_WEB은 수정하지 않음 |
| DB 스키마 migration | Not needed now | `harvest_slot_db2`는 `harvest_slot_db` 대비 스키마 차이 없음 |
| 운영 seed/data patch | Pending | 발표용 DB2 데이터는 존재. 운영 반영용 SQL은 별도 승인 후 작성 |

## Follow-up

- O-005/O-006은 임시 prediction/slot 생성 후 DB 정리하는 smoke로 검증했다.
- O-010은 이미지 선택 UX와 분석 fallback을 보강했으며 iOS 사진 접근은 앱 재빌드 후 다시 확인한다.
- 이메일 찾기와 비밀번호 재설정은 실제 API로 연결했다. 계정 탈퇴/비활성화 같은 운영성 계정 지원은 안내 UX로 유지한다.
- SMART_WEB endpoint migration은 스크립트와 문서까지 준비됐고, 실제 SMART_WEB 프로젝트 적용 여부만 결정하면 된다.
