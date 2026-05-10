# SMART_APP FastAPI Integration Plan

Created: 2026-05-11

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

현재 앱의 실제 HTTP 호출은 `DashboardRepository.fetchDashboard()` 한 곳뿐이다. 이 호출도 `/owner/dashboard`를 쓰고 있어 실제 백엔드 prefix `/api/v1/owner/dashboard`와 맞지 않고, 공통 응답 래퍼 `data/message/error`도 풀지 않는다.

## Target API Client

필수 기능:
- `API_BASE_URL` dart define 지원, 기본값 `http://127.0.0.1:8000/api/v1`
- `GET`, `POST`, `PUT`, `PATCH`, 파일 업로드
- 공통 응답 래퍼에서 `data` 추출
- 실패 응답의 `message`, `error`, status code를 화면에 전달
- access token 저장 및 `Authorization: Bearer <token>` 자동 주입
- 401 또는 403 발생 시 로그인 만료 상태로 전환할 수 있는 구조

## Page/API Map

| Priority | Flutter page | User outcome | Backend API | Current state | Plan |
|---|---|---|---|---|---|
| P0 | `login_page.dart` | 점주 로그인 | `POST /api/v1/auth/login`, `GET /api/v1/me` | 하드코딩 계정 검사 | 실제 로그인, 토큰 저장, role OWNER 검증 |
| P0 | `dashboard_page.dart` | 오늘 업무량 확인 | `GET /api/v1/owner/dashboard` | 일부 repository, 경로/래퍼/필드명 불일치 | API client 교체, snake_case 필드 매핑 |
| P1 | `product_page.dart` | 상품 목록 확인 | `GET /api/v1/owner/products` | 로컬 리스트 | repository + model 추가, 상태 enum 매핑 |
| P1 | `product_add_page.dart` | 상품 등록 | `POST /api/v1/owner/products` | local pop result | farm_id 선택/기본값 연결 후 등록 |
| P1 | `product_edit_page.dart` | 상품 수정/상태 변경 | `PUT /api/v1/owner/products/{id}`, `PATCH /status` | local edit | id 기반 update, status enum 변환 |
| P1 | `farm_detail_page.dart` | 농장 정보 수정 | `GET /api/v1/owner/farms/me`, `PUT /api/v1/owner/farms/{farm_id}` | 하드코딩 폼 | 첫 농장 조회 후 수정 저장 |
| P2 | `harvest_slot_page.dart` | ML 참고 후 슬롯 생성 | `POST /api/v1/owner/ml/predictions`, `GET /api/v1/owner/ml/predictions`, `POST /api/v1/owner/harvest-slots` | 정적 입력 | 농장/상품 선택, 예측 생성, 점주 확정 슬롯 생성 |
| P2 | `orders_page.dart` | 예약/주문 조회 | `GET /api/v1/owner/reservations`, `GET /api/v1/owner/orders` | `sampleOrders` | 예약과 주문 모델 분리, 화면에서는 합산 또는 탭 분리 |
| P2 | `procurement_page.dart` | 발주 승인/거절 | `GET /api/v1/owner/procurements`, `GET /api/v1/owner/procurements/{id}`, `PATCH /decision` | 주문 더미 재사용 | procurement_id 단위 결정, 일괄 선택은 순차 PATCH |
| P3 | `quality_page.dart` | 신선도 검사 저장 | `GET /api/v1/owner/procurements`, `POST /api/v1/owner/quality-inspections/analyze`, `POST /api/v1/owner/quality-inspections` | 이미지 선택만 | 발주 품목 선택 UI 추가 후 분석/저장 |
| P3 | `shipment_page.dart` | 배송 등록 | `POST /api/v1/owner/shipments`, `PATCH /api/v1/owner/shipments/{id}/status` | 로컬 문자열 파싱 | READY_TO_SHIP 주문 선택 후 송장 등록 |
| P3 | `shipment_status_page.dart` | 배송 상태 확인 | `GET /api/v1/owner/orders` plus shipment fields | 로컬 상태 | 주문 응답의 shipment 포함 여부 확인 후 매핑 |
| P3 | `return_page.dart` | 반품 승인/거절 | `GET /api/v1/owner/returns`, `PATCH /api/v1/owner/returns/{id}/decision` | 로컬 리스트 | return_request_id 기반 결정 |
| P3 | `return_status_page.dart` | 처리 결과 확인 | `GET /api/v1/owner/returns` | 로컬 상태 | 상태 필터 매핑 |
| P4 | `owner_detail_page.dart` | 점주 정보 수정 | `GET /api/v1/owner/profile`, `PUT /api/v1/owner/profile` | 하드코딩 폼 | owner_name, owner_phone, business_number만 수정 |
| P4 | `signup_page.dart` | 점주 회원가입 | `POST /api/v1/auth/owners/signup`, email APIs | 로컬 이메일 중복 검사 | 회원가입 + 이메일 인증 흐름 연결 |
| Deferred | `email_find_page.dart` | 이메일 찾기 | 없음 | 폼만 있음 | 별도 API 필요 |
| Deferred | `password_find_page.dart` | 비밀번호 재설정 | 없음 | 폼만 있음 | 별도 API 필요 |

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
- [x] 백엔드 미실행 시 화면이 크래시하지 않고 demo fallback을 보여준다.

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

Success criteria:
- 점주가 상품별 수확 슬롯을 생성할 수 있다.
- 고객 결제 후 생성된 발주를 점주가 승인/거절할 수 있다.
- 일괄 승인 UI는 procurement_id별 PATCH 실패를 개별 표시한다.

### Phase 4: Quality, Shipment, Return

- [ ] 발주 품목 선택 UI 추가
- [ ] 품질 이미지 분석/저장 연결
- [ ] 배송 등록 연결
- [ ] 배송 상태 변경 연결
- [x] 배송 현황 API 우선 + JSON fallback 연결
- [x] 반품 현황 API 우선 + JSON fallback 연결
- [x] 반품 목록/관리 화면 API 우선 + JSON fallback 연결
- [x] 반품 승인/거절 API 우선 + fallback 로컬 처리 연결

Success criteria:
- 점주가 신선도 검사 결과와 점주 판정을 분리해 저장한다.
- READY_TO_SHIP 주문에 송장을 등록할 수 있다.
- 반품 승인 시 approved_amount 검증 실패를 화면에 표시한다.

### Phase 5: Profile, Signup, Recovery

- [x] 점주 프로필 조회/수정 연결
- [x] 회원가입 API 연결
- [x] 이메일 인증 요청/검증 연결
- [ ] 이메일 찾기 API 없음 문서화 유지
- [ ] 비밀번호 재설정 API 없음 문서화 유지

## Deferred / Missing Data

| Item | Reason | Later action |
|---|---|---|
| 이메일 찾기 | backend 최종본에 이름/전화번호 기반 이메일 찾기 API가 없다 | `POST /auth/email/find` 또는 운영 정책 결정 후 구현 |
| 비밀번호 재설정 | backend 최종본에 reset token 발급/검증 API가 없다 | `POST /auth/password/reset-request`, `POST /auth/password/reset-confirm` 설계 필요 |
| 상품 삭제 | backend 최종본에 `DELETE /owner/products/{id}`가 없다 | 물리 삭제 대신 `PATCH /status`로 `INACTIVE` 처리 |
| 농장 이미지 업로드 | 농장 전용 업로드 API가 명확하지 않다 | 공통 이미지 업로드 후 `farm_image_url` 저장으로 처리 가능 |
| 배송 현황 상세 | owner shipment list 전용 API가 없다 | `GET /owner/orders` 응답에 shipment 포함 여부 확인 후 부족하면 API 추가 |
| 배송 등록 API 연결 | `POST /owner/shipments`는 실제 `order_id`가 필요하지만 fallback 발주 승인 데이터에는 실제 order_id가 없다 | 실제 procurement/order seed가 생기면 shipment create를 API 저장으로 전환. 현재는 로컬 현황 반영 유지 |
| 회원가입 농장 정보 저장 | `POST /auth/owners/signup`는 owner 계정만 만들고 농장명/주소/사업자번호는 받지 않는다 | 가입 후 로그인 상태에서 농장 정보 수정 화면으로 저장하거나, 별도 owner signup 확장 API 검토 |
| seed/demo data | 주문/발주/배송/반품까지 검증할 seed가 아직 부족하다 | 현재 점주/농장/상품/수확 슬롯 seed는 생성됨. 다음 단계에서 주문 계열 seed 필요 시 사전 검토 후 생성 |
| 주문/발주 DB 데이터 없음 | 현재 DB에 PDF의 QA 주문/결제/배송/반품 seed가 없다 | `assets/mock/owner_orders.json` fallback으로 주문/발주 화면을 먼저 기능하게 하고, 실제 seed는 별도 검토 후 생성 |
| 배송/반품 DB 데이터 없음 | 현재 DB에 배송/반품 QA seed가 없다 | `assets/mock/owner_shipments.json`, `assets/mock/owner_returns.json` fallback으로 현황 화면을 먼저 기능하게 한다 |
| DB 스키마 변경이 필요한 기능 | 사용자 검증 전에는 DB 변경 범위를 확정하지 않는다 | 현재 DB/API로 검증 가능한 화면을 먼저 연결한 뒤 별도 승인 후 진행 |
| 상품 수량 입력 | backend `products`에는 재고/수량 필드가 없고 실제 예약 가능 수량은 `harvest_slots`에 있다 | 상품 화면에서는 표시/데모 값으로 유지하고 실제 판매 가능 수량은 수확 슬롯 단계에서 연결 |
| Chrome 로그인 이후 검증 | 2026-05-11 `cheng80@gmail.com` 계정으로 login -> dashboard -> product list -> product add input 확인 완료 | 농장 수정/등록 저장, 주문 계열 흐름은 연결 단계별로 추가 검증 |
| Chrome 회원가입 화면 검증 | 2026-05-11 기존 점주 계정 `cheng80@gmail.com`으로 실제 검증하고, 회원가입은 화면 진입과 이메일 인증 UI 연결만 확인했다 | 새 실계정 생성/인증 발송/가입 제출은 하지 않는다. 실제 점주 회원가입 재검증은 사용자 요청 시 별도 진행 |
| DB 기존 상품 품종 | owner_id 1 DB 상품 중 `신고` 품종이 존재하지만 앱 정책은 `양광`, `부사` 두 가지다 | DB 수정은 사용자 검증 후 진행하고, 앱 신규/수정 UI는 `양광`, `부사`만 선택 가능하게 제한 |
| DB OWNER 비밀번호 | 기존 `owner@test.com`은 로그인 비밀번호가 확인되지 않았다 | 신규 검증 계정 `cheng80@gmail.com` / `pass1234!`를 기준으로 진행 |

## Test Plan

- [ ] Dart unit: API wrapper `data` extraction
- [ ] Dart unit: dashboard snake_case mapping
- [ ] Flutter smoke: login form validation
- [x] Flutter analyze
- [x] Flutter test
- [x] Chrome manual: login -> dashboard
- [x] Chrome manual: product list -> product add input flow
- [x] Chrome manual: signup screen email verification UI only, no submit
- [ ] Chrome manual: farm update flow
- [ ] iOS simulator final: login -> dashboard -> menu -> profile
- [ ] iOS simulator final: connected owner workflow smoke test
- [x] Manual API: `POST /api/v1/auth/login`
- [x] Manual API: `GET /api/v1/me`
- [x] Manual API: `GET /api/v1/owner/dashboard`
- [x] Manual flow: login -> dashboard -> product list
- [ ] Manual flow: product create -> edit -> inactive
- [ ] Manual flow: procurement decision -> shipment create -> return decision

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
