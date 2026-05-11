# SMART_APP FastAPI Integration Plan

Created: 2026-05-11
Last updated: 2026-05-11

## Goal

현재 Flutter 점주 앱을 `backend/app`의 FastAPI 최종본에 연결해 실제로 동작하는 점주 관리 앱으로 만든다.

기준 소스:
- 앱 화면/기능: `docs/07_점주_관리앱_기획서.md`, `docs/08_점주_관리앱_화면설계_기능정의서.md`, `docs/16_Flutter_점주앱_구현가이드.md`
- 백엔드 최종본: `backend/app`
- 보조 참고: `/Users/cheng80/Desktop/파이널 프로젝트 기획 문서/harvest_slot_docs_v3_2/00_harvest_slot_docs_v3_2`
- 읽기 전용 참고: `/Users/cheng80/Desktop/smart_web`

SMART_WEB은 API client, repository, model mapping 패턴만 참고한다. 파일은 수정하지 않는다.

## Local Verification Account

2026-05-11 생성한 점주 검증 계정:

| Field | Value |
|---|---|
| Email | `cheng80@gmail.com` |
| Password | `pass1234!` |
| Role | `OWNER` |
| Account ID | `12` |
| Owner ID | `3` |
| Owner name | `cheng80` |
| Phone | `01000000000` |
| Email verified | `true` |

이 계정은 Chrome 수동 검증용 계정이다. DB 스키마 변경은 하지 않았고, 사용자 승인 후 현재 모델에 맞는 최소 더미 레코드만 생성했다.

2026-05-11 사용자 승인 후 생성한 검증용 더미 데이터:

| Type | ID | Values |
|---|---:|---|
| Farm | `3` | `cheng80 테스트 농장`, `충북 충주`, `충북 충주시 산척면 과수원길 24` |
| Product | `5` | `양광 사과`, `5kg`, `39000원`, `ACTIVE` |
| Harvest slot | `40` | product `5`, `OPEN`, 예약 가능 `120kg` |
| Product | `6` | `부사 사과`, `3kg`, `32000원`, `ACTIVE` |
| Harvest slot | `41` | product `6`, `OPEN`, 예약 가능 `90kg` |

이 데이터는 DB 스키마 변경 없이 현재 FastAPI 모델로 생성했다. 상품 API 검증 기준은 `open_slot_count=1`이 각 상품에 내려오는 것이다.

2026-05-11 `고객웹_QA_더미데이터_생성정리_2026-05-11.pdf`의 QA 데이터 기준을 점주 앱 발표용 seed/fallback에 반영했다.

적용 기준:
- 예약 -> 주문 -> 결제 -> 배송 -> 반품/환불 관계가 깨지지 않는 상태 흐름을 유지한다.
- 화면에는 `QA`, `Mock`, `DB`, `API`, `더미` 같은 개발자용 표현을 노출하지 않는다.
- 고객명은 발표 화면에 자연스럽게 보이도록 `홍길동`, `김민지`, `박서준`, `이수현`, `최지우`, `정하윤`을 사용한다.
- 실제 DB 데이터가 부족한 화면은 `assets/mock/*.json` fallback으로 먼저 시작하고, 현재 DB/API로 구현 가능한 API는 붙인다.

owner_id=3 업무 seed:

| Scenario | Customer | Main state |
|---|---|---|
| `REQUESTED` | `홍길동` | 신규 발주 승인 대기 |
| `APPROVED_READY` | `김민지` | 품질 검사 완료, 배송 준비 |
| `PARTIAL_QUALITY` | `박서준` | 부분 승인, 선별 대기 |
| `SHIPPED` | `이수현` | 배송 중 |
| `RETURN_REQUESTED` | `최지우` | 배송 완료 후 반품 요청 |
| `REJECTED` | `정하윤` | 발주 거절 |

## Development Database

2026-05-11 원본 DB를 보존하기 위해 개발/검증용 DB를 추가했다.

| Item | Value |
|---|---|
| Source DB | `harvest_slot_db` |
| Development DB | `harvest_slot_db2` |
| Clone scope | schema + data |
| Copied tables | `19` |
| Views / triggers | `0 / 0` |
| `.env` backup | `.env.harvest_slot_db.backup.20260511-041743` |

현재 로컬 `.env`는 `DATABASE_NAME=harvest_slot_db2`로 전환했다. 이후 DB 스키마 변경, 추가 seed, 기능 검증은 `harvest_slot_db2` 기준으로 진행한다. 원본 `harvest_slot_db` 반영이 필요한 변경은 별도 SQL 또는 마이그레이션으로 문서화한 뒤 사용자 승인 후 적용한다.

## Premises

1. 백엔드 API는 `backend/app`이 최종본이다.
2. Flutter 앱은 현재 대부분 더미 데이터와 로컬 상태로 동작한다.
3. 우선순위는 실제 점주 업무 흐름이다: 로그인 -> 대시보드 -> 상품/농장 -> 수확 슬롯 -> 주문/발주 -> 신선도 -> 배송 -> 반품 -> 프로필.
4. 데이터가 부족하거나 백엔드 API가 없는 기능은 억지 구현하지 않고 후순위로 문서화한다.
5. 앱 내부 상태명은 화면 표시용 한글과 백엔드 enum을 분리한다.
6. DB 수정이 필요한 작업은 후순위로 미루고, 사용자 검증을 받은 뒤 진행한다.
7. 기능 검증은 먼저 Chrome으로 빠르게 확인하고, 최종 앱 검증은 iOS 시뮬레이터에서 진행한다.
8. DB 데이터가 없어 화면 검증이 막히는 경우, API 우선 호출 후 `assets/mock/*.json` fallback으로 기능 흐름을 유지한다. fallback 원인은 이 문서에 남긴다.
9. 사과 품종은 `양광`, `부사` 두 가지로 제한한다.
10. 상품 박스 단위는 SMART_WEB과 동일하게 `1kg`, `3kg`, `5kg`, `7.5kg`, `10kg`만 사용한다.
11. 입력 필드가 필요한 화면은 가능한 경우 수동 입력보다 dropdown, stepper, selector를 우선 사용한다.
12. 사용자 주소 입력은 `kpostal_plus` 패키지를 사용한다.

## Current Architecture

```text
Flutter screens
  -> repository / view model layer
  -> ApiService or ApiClient
  -> FastAPI /api/v1
  -> service / repository / SQLAlchemy models
```

현재 앱은 공통 `ApiService`를 통해 `/api/v1` prefix, 응답 래퍼, 토큰 인증, multipart upload를 처리한다. 부족한 데이터가 있는 업무 화면은 API 우선 호출 후 `assets/mock/*.json` fallback으로 발표 흐름을 유지한다. 신선도 검사는 앱에서 외부 `DL_QUALITY_API_URL`로 multipart 이미지를 먼저 전송하고, 실패하면 백엔드 분석 API와 앱 보조 판정으로 순차 전환한다.

## Target API Client

필수 기능:
- `API_BASE_URL` dart define 지원, 기본값 `http://127.0.0.1:8000/api/v1`
- `GET`, `POST`, `PUT`, `PATCH`, 파일 업로드
- 공통 응답 래퍼에서 `data` 추출
- 실패 응답의 `message`, `error`, status code를 화면에 전달
- access token 저장 및 `Authorization: Bearer <token>` 자동 주입
- JWT 세션 복원/로그인 시 debug console에 만료 시각과 남은 기간 출력
- 백엔드 기본 access token 만료 시간은 30일

## Page/API Map

| Priority | Flutter page | User outcome | Backend API | Current state | Plan |
|---|---|---|---|---|---|
| P0 | `login_page.dart` | 점주 로그인 | `POST /api/v1/auth/login`, `GET /api/v1/me` | 완료 | 실제 로그인, 토큰 저장, role OWNER 검증, 세션 기간 로그 |
| P0 | `dashboard_page.dart` | 오늘 업무량 확인 | `GET /api/v1/owner/dashboard` | 완료 | snake_case 필드 매핑, API 실패 시 발표용 보조 카운트 |
| P1 | `product_page.dart` | 상품 목록 확인 | `GET /api/v1/owner/products` | 완료 | 상태 enum 매핑, 대표 이미지 전체 표시 |
| P1 | `product_add_page.dart` | 상품 등록 | `POST /api/v1/owner/products` | 완료 | farm_id 연결, 품종/박스/이미지/가격 입력 |
| P1 | `product_edit_page.dart` | 상품 수정/상태 변경 | `PUT /api/v1/owner/products/{id}`, `PATCH /status` | 완료 | id 기반 update, status enum 변환 |
| P1 | `farm_detail_page.dart` | 농장 정보 수정 | `GET /api/v1/owner/farms/me`, `PUT /api/v1/owner/farms/{farm_id}`, `POST /owner/farms/{farm_id}/image` | 완료 | 첫 농장 조회 후 수정 저장, 대표 이미지 업로드 |
| P2 | `harvest_slot_page.dart` | ML 참고 후 슬롯 생성 | `POST /api/v1/owner/ml/predictions`, `GET /api/v1/owner/ml/predictions`, `POST /api/v1/owner/harvest-slots` | 완료 | 입력 기준 카드, 차트 수치, 권장값, 표준면적 수확량, 신뢰도 표시 |
| P2 | `orders_page.dart` | 예약/주문 조회 | `GET /api/v1/owner/reservations`, `GET /api/v1/owner/orders` | 완료 | 예약/주문 탭 분리 |
| P2 | `procurement_page.dart` | 발주 승인/거절 | `GET /api/v1/owner/procurements`, `GET /api/v1/owner/procurements/{id}`, `PATCH /decision` | 완료 | procurement_id 단위 결정, 상세 품목별 수량 조정 |
| P3 | `quality_page.dart` | 신선도 검사 저장 | 외부 `DL_QUALITY_API_URL`, `GET /api/v1/owner/procurements`, `POST /api/v1/owner/quality-inspections/analyze`, `POST /api/v1/owner/quality-inspections` | 완료 | 발주 품목 선택, 이미지 전체 표시, 외부 DL 분석 우선, 결과값 저장 |
| P3 | `shipment_page.dart` | 배송 등록 | `POST /api/v1/owner/shipments`, `PATCH /api/v1/owner/shipments/{id}/status` | 완료 | READY_TO_SHIP 발주 상품 선택 후 송장 등록 |
| P3 | `shipment_status_page.dart` | 배송 상태 확인 | `GET /api/v1/owner/shipments` | 완료 | 전용 shipment 목록 API 우선, 구버전 orders fallback |
| P3 | `return_page.dart` | 반품 승인/거절 | `GET /api/v1/owner/returns`, `PATCH /api/v1/owner/returns/{id}/decision` | 완료 | return_request_id 기반 결정, 첨부 이미지 확대 |
| P3 | `return_status_page.dart` | 처리 결과 확인 | `GET /api/v1/owner/returns` | 완료 | 상태 필터 매핑 |
| P4 | `owner_detail_page.dart` | 점주 정보 수정 | `GET /api/v1/owner/profile`, `PUT /api/v1/owner/profile` | 완료 | owner_name, owner_phone, business_number 수정 |
| P4 | `signup_page.dart` | 점주 회원가입 | `POST /api/v1/auth/owners/signup`, email APIs | 완료 | 회원가입 + 이메일 인증 흐름 연결 |
| P4 | `email_find_page.dart` | 이메일 찾기 | `POST /auth/email/find` | 완료 | 이름/전화번호 기반 마스킹 이메일 조회 |
| P4 | `password_find_page.dart` | 비밀번호 재설정 | `POST /auth/password/reset-request`, `POST /auth/password/reset-confirm` | 완료 | 인증번호 발송 후 새 비밀번호 저장 |

## Implementation Phases

### Phase 1: Foundation

- [x] `ApiException` 추가
- [x] 공통 `ApiClient` 추가
- [x] `AuthSession` 추가
- [x] `AuthRepository` 추가
- [x] `login_page.dart`를 실제 로그인으로 교체
- [x] `DashboardRepository`를 새 API client로 교체
- [x] `DashboardModel` snake_case 매핑 추가
- [x] `flutter analyze` 통과
- [x] `flutter test` 통과

Success criteria:
- [x] 로그인 성공 시 `Home`으로 진입한다.
- [x] 로그인 실패 메시지가 실제 API 실패와 연결된다.
- [x] 대시보드가 `/api/v1/owner/dashboard`의 `data`를 읽는다.
- [x] 백엔드 미실행 시 화면이 크래시하지 않고 빈 대시보드 또는 JSON fallback으로 전환한다.

### Phase 2: Product/Farm

- [x] `OwnerFarm` model 추가
- [x] `OwnerProduct` model 추가
- [x] `OwnerRepository` 또는 `ProductRepository` 추가
- [x] 상품 목록을 `GET /owner/products`로 교체
- [x] 상품 등록/수정 연결
- [x] 상품 상태 enum 매핑: `ACTIVE`, `HIDDEN`, `SOLD_OUT`
- [x] 농장 조회/수정 연결
- [x] 상품 품종 selector를 `양광`, `부사`로 제한
- [x] 상품 포장 단위를 SMART_WEB 기준 `1kg`, `3kg`, `5kg`, `7.5kg`, `10kg` dropdown으로 제한
- [x] 상품 가격/표시 수량을 수동 입력에서 stepper로 변경
- [x] `flutter analyze` 통과
- [x] `flutter test` 통과

Success criteria:
- [x] 점주가 백엔드 상품 목록을 보고 등록/수정할 수 있다.
- [x] 화면 한글 상태와 백엔드 enum이 섞이지 않는다.
- [x] farm_id가 없는 경우 저장을 막고 원인을 표시한다.
- [x] Chrome에서 백엔드 연결 상태로 상품 목록/등록 화면 흐름 검증

### Phase 3: Harvest Slot, Order, Procurement

- [x] ML prediction request/response model 추가
- [x] Harvest slot request/response model 추가
- [x] 주문 목록 model 추가
- [x] 발주 목록/상세 model 추가
- [x] 수확 슬롯 생성 연결
- [x] 주문 현황 API 우선 + JSON fallback 연결
- [x] 발주 승인 화면을 주문 API 우선 + JSON fallback 데이터로 구동
- [x] 실제 발주 목록/승인 API 우선 + JSON fallback 연결
- [x] 발주 상세 및 결정 화면 추가: 품목별 승인 박스/kg, 점주 메모, 부분승인/거절 저장

Success criteria:
- 점주가 상품별 수확 슬롯을 생성할 수 있다.
- 고객 결제 후 생성된 발주를 점주가 승인/거절할 수 있다.
- 일괄 승인 UI는 procurement_id별 PATCH 실패를 개별 표시한다.
- 발주 상세 화면에서 품목별 수량을 조정해 `APPROVED`, `PARTIAL_APPROVED`, `REJECTED`를 저장한다.

### Phase 4: Quality, Shipment, Return

- [x] 발주 품목 선택 UI 추가
- [x] 외부 DL 품질 이미지 분석/저장 연결
- [x] 배송 등록 연결
- [x] 배송 상태 변경 연결
- [x] 배송 현황 API 우선 + JSON fallback 연결
- [x] 반품 현황 API 우선 + JSON fallback 연결
- [x] 반품 목록/관리 화면 API 우선 + JSON fallback 연결
- [x] 반품 승인/거절 API 우선 + fallback 로컬 처리 연결

Success criteria:
- 점주가 신선도 검사 결과와 점주 판정을 분리해 저장한다.
- 외부 DL 서버가 살아 있으면 실제 모델 결과를 표시하고, 실패하면 백엔드 분석/앱 보조 판정으로 흐름을 유지한다.
- READY_TO_SHIP 주문에 송장을 등록할 수 있다.
- 반품 승인 시 approved_amount 검증 실패를 화면에 표시한다.
- 배송 현황에서 실제 shipment_id가 있는 항목은 배송 중/배송 완료로 상태 변경할 수 있다.

### Phase 5: Profile, Signup, Recovery

- [x] 점주 프로필 조회/수정 연결
- [x] 회원가입 API 연결
- [x] 이메일 인증 요청/검증 연결
- [x] 이메일 찾기 API 추가 및 화면 연결
- [x] 비밀번호 재설정 API 추가 및 화면 연결

## Deferred / Missing Data

| Item | Reason | Later action |
|---|---|---|
| 상품 삭제 | backend 최종본에 `DELETE /owner/products/{id}`가 없다 | 물리 삭제 대신 `PATCH /status`로 `INACTIVE` 처리 |
| DL 신선도 상시 운영 URL | 현재 외부 ngrok/Kaggle 세션 의존 | 발표 전 `DL_QUALITY_API_URL` 최신값 확인. 운영은 고정 HTTPS endpoint 필요 |
| fallback 배송 상태 변경 | JSON fallback 항목은 실제 shipment_id가 없다 | 발표용 조회만 허용하고, 실제 상태 변경은 DB shipment_id가 있는 항목에서만 처리 |
| 신선도 검사 대상 데이터 부족 | `POST /owner/quality-inspections/*`는 실제 `procurement_item_id`가 필요하다 | owner_id=3 seed에 선별 대기 품목을 추가했고, 없으면 화면에서 “승인된 발주 품목 없음”으로 안내. 외부 DL 실패 시에도 앱 보조 판정 유지 |
| 회원가입 농장 정보 저장 | `POST /auth/owners/signup`는 owner 계정만 만들고 농장명/주소/사업자번호는 받지 않는다 | 가입 후 로그인 상태에서 농장 정보 수정 화면으로 저장하거나, 별도 owner signup 확장 API 검토 |
| 고객웹 QA seed 원본 스크립트 | PDF에는 `seed_customer_flow_qa_data.py` 기준이 있지만 현재 로컬 프로젝트에는 스크립트 파일이 없다 | PDF의 상태 분포와 화면 노출 기준만 owner3 seed/fallback에 반영했다 |
| fallback 데이터 | API/DB가 부족한 상태에서도 발표 흐름이 필요하다 | `assets/mock/owner_orders.json`, `owner_shipments.json`, `owner_returns.json`은 유지하되 개발자용 `QA` 노출은 제거했다 |
| DB 스키마 변경이 필요한 기능 | 사용자 검증 전에는 DB 변경 범위를 확정하지 않는다 | 현재 DB/API로 검증 가능한 화면을 먼저 연결한 뒤 별도 승인 후 진행 |
| 상품 수량 입력 | backend `products`에는 재고/수량 필드가 없고 실제 예약 가능 수량은 `harvest_slots`에 있다 | 상품 화면에서는 표시/데모 값으로 유지하고 실제 판매 가능 수량은 수확 슬롯 단계에서 연결 |
| Chrome 로그인 이후 검증 | 2026-05-11 `cheng80@gmail.com` 계정으로 login -> dashboard -> product list -> product add input 확인 완료 | 농장 수정/등록 저장은 별도 상세 검증 대상으로 남김 |
| Chrome 회원가입 화면 검증 | 2026-05-11 기존 점주 계정 `cheng80@gmail.com`으로 실제 검증하고, 회원가입은 화면 진입과 이메일 인증 UI 연결만 확인했다 | 새 실계정 생성/인증 발송/가입 제출은 하지 않는다. 실제 점주 회원가입 재검증은 사용자 요청 시 별도 진행 |
| DB 기존 상품 품종 | owner_id 1 DB 상품 중 `신고` 품종이 존재하지만 앱 정책은 `양광`, `부사` 두 가지다 | DB 수정은 사용자 검증 후 진행하고, 앱 신규/수정 UI는 `양광`, `부사`만 선택 가능하게 제한 |
| DB OWNER 비밀번호 | 기존 `owner@test.com`은 로그인 비밀번호가 확인되지 않았다 | 신규 검증 계정 `cheng80@gmail.com` / `pass1234!`를 기준으로 진행 |
| owner workflow smoke | 2026-05-11 `scripts/owner_workflow_smoke.py`로 임시 발주 생성 -> 승인 -> 품질검사 -> 배송등록 -> 배송완료 -> 반품승인까지 실제 API/DB로 검증했다 | 스모크 데이터는 실행 후 자동 정리한다 |
| iOS simulator final | 2026-05-11 iPhone 17 시뮬레이터에서 직접 비밀번호 입력 후 login -> dashboard -> menu -> 배송 현황 -> profile 확인 완료 | 보안 입력 필드는 자동입력에서 문자가 누락될 수 있어 최종 로그인만 수동 입력으로 검증 |
| owner product/farm smoke | 2026-05-11 실제 API로 농장 동일값 저장, 상품 생성, 상품 수정, 상품 `INACTIVE` 상태 전환을 검증했다 | 검증 상품은 비활성 상태로 남겨 발표 목록에는 노출되지 않게 처리 |

## Test Plan

- [x] API wrapper `data` extraction: `scripts/owner_api_check.py`, `scripts/owner_workflow_smoke.py` 실제 응답 검증
- [x] Dart unit: dashboard snake_case mapping
- [ ] Flutter smoke: login form validation
- [x] Flutter analyze
- [x] Flutter test
- [x] Chrome manual: login -> dashboard
- [x] Chrome manual: product list -> product add input flow
- [x] Chrome manual: signup screen email verification UI only, no submit
- [x] Chrome manual: login -> dashboard -> 발주 현황 -> 배송 현황 -> 배송 상태 action sheet
- [x] API smoke: farm update flow
- [x] iOS simulator final: login -> dashboard -> menu -> profile
- [x] iOS simulator final: connected owner workflow smoke test
- [x] Manual API: `POST /api/v1/auth/login`
- [x] Manual API: `GET /api/v1/me`
- [x] Manual API: `GET /api/v1/owner/dashboard`
- [x] Manual API: owner3 login -> dashboard -> products -> procurements -> quality analyze
- [x] Manual flow: login -> dashboard -> product list
- [x] Manual flow: product create -> edit -> inactive
- [x] Manual flow: procurement decision -> shipment create -> shipment status -> return decision

## Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|---|---|---|---|---|---|
| 1 | CEO | 백엔드 신규 구현보다 Flutter 연동 계층을 먼저 만든다 | Mechanical | Explicit over clever | 백엔드 owner API는 대부분 존재하고 앱이 더미 상태라 병목은 프론트 연동이다 | 백엔드부터 재작성 |
| 2 | Eng | SMART_WEB의 API client 패턴을 참고하되 smart_app에 맞는 단순 client를 만든다 | Mechanical | DRY | 같은 백엔드 래퍼/토큰 구조를 이미 해결한 로컬 참고가 있다 | 현재 `ApiService.get` 확장만 계속 덧붙이기 |
| 3 | Eng | 이메일 찾기/비밀번호 재설정은 후순위로 둔다 | Mechanical | Pragmatic | backend 최종본에 API가 없어 지금 붙이면 fake UX가 된다 | 화면에서 성공 처리만 하는 임시 구현 |
| 4 | Design | 상태값은 백엔드 enum과 화면 한글 표시값을 분리한다 | Mechanical | Explicit over clever | API 저장값과 사용자가 보는 문구가 섞이면 수정/필터/전송 버그가 난다 | 한글 문자열을 내부 상태로 계속 사용 |
| 5 | Eng | DB 수정이 필요한 작업은 사용자 검증 후로 미룬다 | Mechanical | Bias toward action | 현재 DB/API로 검증 가능한 기능부터 붙여야 실제 앱 흐름을 빨리 확인할 수 있다 | 검증 전 DB 스키마/seed 변경 병행 |
| 6 | QA | Chrome으로 빠른 검증 후 iOS 시뮬레이터로 최종 검증한다 | Mechanical | Pragmatic | Chrome은 반복 확인이 빠르고 iOS 시뮬레이터는 실제 앱 타깃에 가깝다 | 매번 iOS만 실행해서 반복 속도를 늦추기 |
| 7 | QA | 사용자 승인 후 검증용 계정과 최소 seed를 만들고 Chrome 검증을 진행한다 | Mechanical | Pragmatic | 실제 로그인과 상품 목록 검증에는 OWNER 계정, 농장, 상품, 수확 슬롯이 필요했다 | 스키마 변경 또는 대량 seed 생성 |
| 8 | Product | 상품 등록/수정 UI는 `양광`, `부사`와 SMART_WEB 포장 단위만 허용한다 | Mechanical | DRY | SMART_WEB 고객 예약 단위와 점주 상품 단위가 같아야 주문/발주 수량 계산이 맞는다 | 자유 텍스트 품종/포장 단위 입력 |
| 9 | UX | 가격과 표시 수량은 수동 입력 대신 stepper로 조정한다 | Mechanical | Explicit over clever | 숫자 오타를 줄이고 모바일에서 반복 조작하기 쉽다 | 키보드 숫자 입력 유지 |
