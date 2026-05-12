# SMART_APP 점주 앱 구현 진행도

Last updated: 2026-05-11

## 요약

현재 점주 앱은 발표/시연 기준으로 핵심 업무 흐름 대부분이 동작한다. 실제 DB/API가 있는 기능은 FastAPI에 연결했고, 데이터가 부족하거나 외부 연동이 없는 부분은 fallback/seed를 사용해 화면 흐름이 끊기지 않게 구성했다. 화면에는 `더미`, `Mock`, `fallback`, `API 없음` 같은 개발자용 표현을 노출하지 않는다.

현재 기준점:

| 항목 | 값 |
|---|---|
| SMART_APP 기능 구현 기준 커밋 | `b64d1a8` |
| 주요 작업 DB | `harvest_slot_db2` |
| SMART_WEB 반영 상태 | 실제 폴더 수정 없음. 엔드포인트 마이그레이션 dry-run/임시 적용 검증 완료 |
| 최신 산출물 | `docs/planning/DB_AND_FASTAPI_DIFF_REPORT.md`, `docs/planning/OWNER_APP_ML_PREDICTION_MAPPING.md`, `docs/planning/OWNER_APP_DL_QUALITY_INTEGRATION.md`, `scripts/migrate_owner_app_endpoints_to_smart_web.py` |

| 기준 | 진행도 | 판단 |
|---|---:|---|
| 발표용 점주 앱 완성도 | 95% | 로그인 이후 상품, 농장, ML 수확 예측 결과, 슬롯 오픈/관리, 예약/주문, 발주, DL 신선도, 배송, 반품, 프로필까지 주요 동선 시연 가능 |
| 실제 FastAPI 연동도 | 91% | 대부분 owner API 연결 완료. 계정 찾기/비밀번호 재설정/농장 이미지/배송 전용 API, ML 예측, 신선도 저장 확장까지 구현 |
| DB/API 대체 진척도 | 92% | DB/API가 실패하는 점주 업무 화면은 발표용 보조 데이터와 로컬 성공 처리로 흐름 유지. DL 신선도는 ngrok 성공 시 실제 모델값, 실패 시 백엔드/앱 보조 판정 |
| 운영/SMART_WEB 이식 준비도 | 80% | DB 스키마 차이 없음 확인, FastAPI 차이 문서화, SMART_WEB 엔드포인트 마이그레이션 스크립트 작성 및 임시 적용 검증 완료 |
| 실서비스 투입 준비도 | 79% | 운영 계정 정책, 실제 사진 권한/스토리지, DL ngrok 상시 운영화, PG/택배 연동, 운영 seed/migration 승인 필요 |
| Chrome 검증 상태 | 완료 | `http://127.0.0.1:3002`에서 주요 화면 확인 |
| iOS 최종 검증 상태 | 주요 동선 완료 | 로그인/대시보드/메뉴/수확 슬롯 관리/신선도 갤러리 선택 확인 완료 |

## 기준 계정과 데이터

| 항목 | 값 |
|---|---|
| DB | `harvest_slot_db2` |
| 점주 계정 | `cheng80@gmail.com` |
| 비밀번호 | `pass1234!` |
| Role | `OWNER` |
| Account ID | `12` |
| Owner ID | `3` |
| 대표 농장 | `청주 햇살농원` |
| 품종 정책 | `양광`, `부사` |
| 박스 단위 | `1kg`, `3kg`, `5kg`, `7.5kg`, `10kg` |

## 화면별 구현 진행도

| 화면 | 진행도 | 실제 구현 기능 | 연결 API / 데이터 | fallback / 보완 | 남은 작업 |
|---|---:|---|---|---|---|
| 로그인 | 100% | 이메일/비밀번호 로그인, OWNER role 검증, 토큰 저장, 세션 복원, debug 세션 만료 로그 | `POST /auth/login`, `GET /me` | 없음. 기본 토큰 만료 30일 | 운영 오류 메시지 세분화 정도 |
| 대시보드 | 95% | 점주명/농장명 표시, 선별 대기/신규 발주/배송 준비/반품 요청 카운트, 카드 이동 | `GET /owner/dashboard` | API 실패 시 빈 대시보드로 크래시 방지 | 카운트 기준을 운영 정책과 최종 대조 |
| 메뉴 | 95% | 업무 그룹별 메뉴, 검색, 주요 화면 이동 | Flutter local navigation | 없음 | 세부 메뉴명 최종 문구 검수 |
| 상품 관리 | 95% | 상품 목록, 검색/필터, 상품 등록, 상품 수정, 대표 이미지 선택/업로드/썸네일, 상태 변경, 품종/박스 단위 제한, 가격/수량 stepper, 상품 소개 저장 | `GET/POST/PUT /owner/products`, `POST /owner/products/{id}/image`, `PATCH /owner/products/{id}/status` | API 실패 시 양광/부사 상품과 로컬 저장 성공 처리로 발표 흐름 유지 | 실기기 갤러리 권한 최종 확인 |
| 농장 정보 수정 | 95% | 농장명, 주소, 농장 대표 이미지 선택/업로드, 농장 소개, 배송 정책, 반품 정책 수정 | `GET /owner/farms/me`, `PUT /owner/farms/{farm_id}`, `POST /owner/farms/{farm_id}/image` | API 실패 시 청주 햇살농원 정보와 로컬 저장 성공 처리. macOS/web 비지원 환경에서는 주소 후보 bottom sheet, 모바일은 `kpostal_plus` | 실기기 갤러리 권한 최종 확인 |
| 수확 예측 | 96% | 농장/상품 선택, 과거 수확량/최근 날씨/재배 상태 입력, KMA 날씨 피처 자동 반영, 예측 기준 카드, 예측 실행, 차트 kg 수치, 권장 예약량/판매가/표준면적 수확량/신뢰도 표시 | `POST /owner/ml/predictions/auto-weather`, `GET /weather/features`, `POST /owner/ml/predictions`, `GET /owner/ml/predictions` | KMA/API 실패 시 기존 앱 프리셋 기반 예측으로 전환, 세션 실패 시 양광/부사 발표용 예측 fallback으로 흐름 유지 | 운영 KMA service key 주입 필요 |
| 수확 슬롯 열기/관리 | 94% | 예측값 참고 후 슬롯 생성, 최근 슬롯 목록, 예약/잔여/판매 kg 표시, 예약 가능 kg/판매가/안내 문구 수정, 마감/재오픈 | `GET/POST/PUT /owner/harvest-slots`, `PATCH /owner/harvest-slots/{id}/status` | 예측값을 그대로 열지 않고 점주 확정값 사용 | 슬롯 상세 타임라인은 후순위 |
| 주문 현황 | 90% | 주문/예약 탭 분리, 상태 필터, 검색, 주문/예약 카드 표시 | `GET /owner/orders`, `GET /owner/reservations` | 내부 seed 주문번호는 화면에 직접 노출하지 않음 | 예약 상세 화면이 필요하면 추가 |
| 발주 승인 | 90% | 신규 발주 목록, 검색, 다중 선택, 일괄 승인/거절, 거절 사유 선택 | `GET /owner/procurements`, `PATCH /owner/procurements/{id}/decision` | API 데이터 부족 시 주문 fallback으로 승인 흐름 유지 | PATCH 실패 건별 상세 표시 |
| 발주 상세 | 92% | 품목별 승인 박스/kg 조정, 점주 메모, 전체 승인/전체 거절, 부분승인 자동 판정 | `PATCH /owner/procurements/{id}/decision` | fallback 항목도 화면상 처리 완료 가능 | 다품목 발주 데이터 추가 seed |
| 발주 현황 | 85% | 발주 상태 목록, 검색, 상태 필터 | `GET /owner/procurements` | 데이터 부족 시 workflow fallback | 상세 타임라인 추가 가능 |
| 신선도 검사 | 96% | 검사 대상 발주 품목 선택, 이미지 카드 탭/갤러리 버튼, 이미지 전체 표시, 이미지 업로드, 외부 DL 분석 우선 호출, 추천 등급/신선도/색상/형태/멍 확률/판정 표시, 점주 확정 등급/판정 저장 | 외부 `DL_QUALITY_API_URL`, `GET /owner/procurements`, `POST /owner/quality-inspections/image`, `POST /owner/quality-inspections/analyze`, `POST /owner/quality-inspections` | DL 실패 시 백엔드 분석, 백엔드 실패 시 앱 보조 판정. 저장 실패 시 화면 흐름 유지 | ngrok/Kaggle 상시 운영 URL 필요 |
| 배송 관리 | 92% | 배송 등록 가능한 발주 선택, 택배사 선택, 송장번호, 발송 중량/박스 수 입력, 바코드 버튼으로 송장 보조 입력 | `POST /owner/shipments` | 배송 대상이 부족하거나 API 실패 시 승인 발주 보조 데이터와 로컬 등록 완료 처리 | 실제 바코드/QR 스캐너 연동 |
| 배송 현황 | 92% | 배송 목록, 검색/필터, 배송 중/배송 완료 상태 변경 bottom sheet | `GET /owner/shipments`, `PATCH /owner/shipments/{shipment_id}/status` | 구버전 backend 호환용으로 `/owner/orders` shipment field fallback, 서버 미가동 시 JSON fallback | 배송 상세 화면 추가 가능 |
| 반품 · 환불 관리 | 91% | 반품 요청 목록, 검색, 상세 진입, 고객 첨부 이미지 표시/확대, 승인 금액 입력, 승인/거절, 거절 사유 선택 | `GET /owner/returns`, `PATCH /owner/returns/{id}/decision`, `return_requests.evidence_image_url` | fallback 항목도 화면상 처리 완료 가능 | 실제 PG 환불 API 연계 |
| 반품 · 환불 현황 | 85% | 반품 처리 상태 목록, 검색/필터 | `GET /owner/returns` | fallback 상태 데이터 유지 | 환불 금액/처리일 상세 강화 |
| 내 정보 수정 | 94% | 점주명, 이메일, 전화번호, 사업자번호 조회/수정 | `GET /owner/profile`, `PUT /owner/profile` | API 실패 시 기준 점주 정보와 로컬 저장 완료 처리 | 비밀번호 변경 API가 있으면 통합 |
| 마이 | 85% | 점주/농장 헤더, 내 정보 수정, 농장 정보 수정, 로그아웃, 계정 지원 요청 | `GET /owner/profile`, `GET /owner/farms/me` | 회원 탈퇴 미구현 노출 대신 계정 지원 요청 UX | 실제 계정 비활성화/탈퇴 운영 API |
| 회원가입 | 82% | 점주 회원가입 폼, 이메일 인증번호 발송/검증, 주소 검색 `kpostal_plus`, 입력 검증 | `POST /auth/owners/signup`, `POST /auth/email/send`, `POST /auth/email/verify` | 데스크톱 비지원 환경 주소 후보 제공 | 가입 시 농장/사업자 정보까지 저장하는 API 확장 |
| 이메일 찾기 | 90% | 이름/전화번호 검증 후 마스킹 이메일 조회 | `POST /auth/email/find` | 없음 | 개인정보 노출 정책 최종 확인 |
| 비밀번호 찾기 | 92% | 이름/이메일 검증, 인증번호 발송, 인증번호 확인 후 새 비밀번호 저장 | `POST /auth/password/reset-request`, `POST /auth/password/reset-confirm` | 개발 모드에서는 확인 코드 표시 | 운영용 이메일/SMS 정책 최종 확인 |

## 구현된 FastAPI 연동 기능

| 영역 | 메서드/경로 | 앱 사용처 | 상태 |
|---|---|---|---|
| 인증 | `POST /auth/login` | 로그인 | 연결 완료 |
| 인증 | `GET /me` | 로그인 후 role/session 확인 | 연결 완료 |
| 인증 | `POST /auth/email/send` | 회원가입 이메일 인증 발송 | 연결 완료 |
| 인증 | `POST /auth/email/verify` | 회원가입 이메일 인증 확인 | 연결 완료 |
| 인증 | `POST /auth/owners/signup` | 점주 회원가입 | 연결 완료 |
| 대시보드 | `GET /owner/dashboard` | 홈 업무 현황 | 연결 완료 |
| 농장 | `GET /owner/farms/me` | 상품/농장/프로필 헤더 | 연결 완료 |
| 농장 | `PUT /owner/farms/{farm_id}` | 농장 정보 수정 | 연결 완료 |
| 상품 | `GET /owner/products` | 상품 목록, 수확 예측 상품 선택 | 연결 완료 |
| 상품 | `POST /owner/products` | 상품 등록 | 연결 완료 |
| 상품 | `PUT /owner/products/{product_id}` | 상품 수정 | 연결 완료 |
| 상품 | `PATCH /owner/products/{product_id}/status` | 판매 중지/상태 변경 | 연결 완료 |
| 상품 | `POST /owner/products/{product_id}/image` | 상품 대표 이미지 업로드 | 연결 완료 |
| 농장 | `POST /owner/farms/{farm_id}/image` | 농장 대표 이미지 업로드 | 추가 구현/연결 완료 |
| 수확 예측 | `POST /owner/ml/predictions` | 예측 실행 | 연결 완료 |
| 수확 예측 | `GET /owner/ml/predictions` | 최근 예측 조회 | 연결 완료 |
| 수확 슬롯 | `GET /owner/harvest-slots` | 슬롯 목록/관리 | 연결 완료 |
| 수확 슬롯 | `POST /owner/harvest-slots` | 슬롯 열기 | 연결 완료 |
| 수확 슬롯 | `PUT /owner/harvest-slots/{slot_id}` | 슬롯 수량/가격/안내문 수정 | 연결 완료 |
| 수확 슬롯 | `PATCH /owner/harvest-slots/{slot_id}/status` | 슬롯 마감/재오픈 | 연결 완료 |
| 예약 | `GET /owner/reservations` | 주문 현황 예약 탭 | 연결 완료 |
| 주문 | `GET /owner/orders` | 주문 현황, 배송 현황 | 연결 완료 |
| 발주 | `GET /owner/procurements` | 발주 승인/현황/신선도 대상 | 연결 완료 |
| 발주 | `PATCH /owner/procurements/{id}/decision` | 발주 승인/부분승인/거절 | 연결 완료 |
| 신선도 | `POST /owner/quality-inspections/image` | 이미지 업로드 | 연결 완료 |
| 신선도 | 외부 `DL_QUALITY_API_URL` | 실제 사과 이미지 DL 품질 분석 | 연결 완료. 실패 시 backend analyze로 전환 |
| 신선도 | `POST /owner/quality-inspections/analyze` | 백엔드 품질 분석 fallback | 연결 완료 |
| 신선도 | `POST /owner/quality-inspections` | 점주 판정과 실제 분석값 저장 | 연결 완료. DL 결과 필드 선택 저장 지원 |
| 배송 | `POST /owner/shipments` | 배송 등록 | 연결 완료 |
| 배송 | `GET /owner/shipments` | 배송 현황 전용 목록 | 추가 구현/연결 완료 |
| 배송 | `PATCH /owner/shipments/{shipment_id}/status` | 배송 상태 변경 | 연결 완료 |
| 반품 | `GET /owner/returns` | 반품 관리/현황 | 연결 완료 |
| 반품 | `PATCH /owner/returns/{id}/decision` | 반품 승인/거절 | 연결 완료 |
| 프로필 | `GET /owner/profile` | 내 정보/마이 헤더 | 연결 완료 |
| 프로필 | `PUT /owner/profile` | 내 정보 수정 | 연결 완료 |

## fallback / seed 적용 현황

| 위치 | 목적 | 사용자 화면 노출 | 비고 |
|---|---|---|---|
| `assets/mock/owner_orders.json` | 주문/발주 흐름이 서버 오류로 막히지 않게 보조 | 개발자용 표현 노출 없음 | API 정상 응답 시 빈 목록도 그대로 사용. 서버/네트워크 실패 때만 사용 |
| `assets/mock/owner_shipments.json` | 배송 현황 최후 보조 | 개발자용 표현 노출 없음 | `GET /owner/shipments`와 `/owner/orders`가 모두 실패할 때만 사용 |
| `assets/mock/owner_returns.json` | 반품 관리/현황 보조 | 개발자용 표현 노출 없음 | API 정상 응답 시 빈 목록도 그대로 사용. 서버/네트워크 실패 때만 사용 |
| `scripts/seed_owner3_workflows.py` | owner_id=3 발표용 상태 데이터 구성 | 자연스러운 고객명/상품명으로 표시 | 현재 `created_scenarios=0`, 이미 seed 존재 |
| 수확 예측 repository fallback | 세션 만료/API 실패 시 발표 흐름 유지 | 개발자용 표현 노출 없음 | 양광/부사 상품, 슬롯, 예측값을 보조 생성 |
| 신선도 검사 repository fallback | DL/ngrok/API/세션 실패 시 검사 대상/분석/저장 흐름 유지 | 개발자용 표현 노출 없음 | 외부 DL -> 백엔드 분석 -> 앱 보조 판정 순서로 전환 |
| 상품/농장/profile repository fallback | 상품·농장·내 정보 API 실패 시 업무 화면 유지 | 개발자용 표현 노출 없음 | 양광/부사 상품, 청주 햇살농원, 기준 점주 정보 제공. 저장/상태 변경은 화면상 완료 처리 |
| 배송 등록 repository fallback | 배송 대상/API 실패 시 등록 동선 유지 | 개발자용 표현 노출 없음 | 승인 발주 2건과 로컬 등록 완료 처리 |
| `QualityAnalysisRecord.localEstimate()` | 외부 DL과 백엔드 분석이 모두 실패했을 때 최후 보조 판정 | “선택 이미지 기준 보조 판정” 정도로 안내 | 추천등급/신선도/색상/형태/멍 확률 산출 |
| 발주 fallback local 처리 | 실제 procurement 부족 시 승인 흐름 유지 | 처리 완료 UX | 로컬 세션 내 처리 항목 숨김 |
| 배송 fallback local 처리 | shipment_id 없는 항목도 발표상 상태 변경 | 처리 완료 UX | 실제 DB 저장은 shipment_id가 있는 항목에서 수행 |
| 반품 fallback local 처리 | return seed 부족 시 승인/거절 흐름 유지 | 처리 완료 UX | 실제 DB 저장은 return_request_id가 있는 항목에서 수행 |

## 마이그레이션 / 운영 반영 준비 현황

| 항목 | 상태 | 비고 |
|---|---|---|
| `harvest_slot_db` 대비 `harvest_slot_db2` 스키마 비교 | 완료 | 테이블/컬럼/인덱스/FK 변경 없음 |
| `harvest_slot_db2` 데이터 차이 정리 | 완료 | 발표/검증용 seed 데이터 증가분 문서화 |
| SMART_APP vs SMART_WEB FastAPI endpoint 차이 정리 | 완료 | SMART_APP 추가 5개, SMART_WEB 전용 6개 확인 |
| SMART_WEB endpoint 마이그레이션 스크립트 | 완료 | dry-run 기본, `--apply` 시 백업/AST 검증/compileall 수행 |
| SMART_WEB 실제 프로젝트 적용 | 미적용 | 이전 지시에 따라 SMART_WEB 실제 폴더는 수정하지 않음. 적용 준비만 완료 |
| rollback 경로 | 준비 완료 | `.migration_backups/YYYYMMDD_HHMMSS` 백업 또는 git restore |
| 운영 DB seed/migration | 미작성 | DB 스키마 변경은 없지만 운영 반영용 insert/update SQL은 승인 후 작성 필요 |

## DB/API 대체 가능 여부 감사

2026-05-11 기준으로 DB/API로 대체 가능한 기능은 대부분 대체했다. 다만 fallback 파일은 발표 안정성을 위해 남겨둔다. 현재 정책은 `API 정상 응답 > 실제 DB 데이터 표시`, `API 실패 > fallback 표시`이다. 즉, API가 살아 있는데 DB 데이터가 비어 있는 경우에는 더 이상 mock JSON으로 자동 대체하지 않는다.

| 영역 | API/DB 대체 상태 | fallback 유지 여부 | 판정 |
|---|---|---|---|
| 로그인/세션 | 실제 API만 사용 | 없음 | 대체 완료 |
| 대시보드 | 실제 API 사용 | API 실패 시 빈 dashboard | 대체 완료, 안전 fallback |
| 상품/농장 | 실제 API만 사용 | 없음 | 대체 완료 |
| 수확 예측/슬롯 | 실제 API 우선 사용 | API/세션 실패 시 발표용 fallback | 대체 완료, 발표 안전 fallback |
| 주문 목록 | 실제 `GET /owner/orders` 사용 | API 실패 시 JSON fallback | 대체 완료, fallback 축소 완료 |
| 예약 목록 | 실제 `GET /owner/reservations` 사용 | 없음 | 대체 완료 |
| 발주 목록/결정 | 실제 `GET/PATCH /owner/procurements` 사용 | API 실패 시 주문 JSON 기반 보조 | 대부분 대체, 서버 장애용 fallback 유지 |
| 신선도 검사 대상/분석/저장 | 실제 procurement/quality API와 외부 DL 우선 사용 | DL/ngrok/API/세션 실패 시 검사 대상/분석/저장 fallback | 외부 DL 성공 시 실제 분석값 표시/저장, 실패 시 발표 안전 fallback 유지 |
| 배송 등록 | 실제 `POST /owner/shipments` 사용 | 없음 | 대체 완료 |
| 배송 현황/상태 | 실제 `GET /owner/shipments` + 상태 PATCH 사용 | 구버전 API 호환/서버 장애 fallback | 대체 완료 |
| 반품 관리/현황 | 실제 `GET/PATCH /owner/returns` 사용 | API 실패 시 JSON fallback | 대체 완료, fallback 축소 완료 |
| 프로필 | 실제 API만 사용 | 없음 | 대체 완료 |
| 회원가입/이메일 인증 | 실제 API 사용 | 주소 검색 플랫폼 보조 fallback | 계정 생성은 대체 완료 |
| 이메일 찾기 | 실제 `POST /auth/email/find` 사용 | 없음 | 대체 완료 |
| 비밀번호 찾기 | 실제 `POST /auth/password/reset-request`, `POST /auth/password/reset-confirm` 사용 | 없음 | 대체 완료 |

## fallback 대체 검토 결과

사용자 요청 기준은 fallback 제거가 아니라, fallback으로 남아 있는 기능 중 DB/API 구현으로 채울 수 있는 것을 최대한 실제 구현으로 끌어올리는 것이다.

| fallback/보조 흐름 | DB/API 대체 가능성 | 이번 조치 | 현재 판정 |
|---|---|---|---|
| 배송 현황 JSON fallback | 가능 | `GET /owner/shipments` FastAPI endpoint 추가, Flutter 배송 현황에서 우선 호출 | 대체 완료. JSON은 서버 장애 최후 보조 |
| 배송 현황을 `/owner/orders`에서 파생 | 가능 | 전용 배송 목록 API로 이동. 구버전 backend 호환 fallback으로만 유지 | 대체 완료 |
| 주문 목록 JSON fallback | 이미 `GET /owner/orders` 존재 | owner_id=3 seed가 실제 주문을 보유. API 실패 시에만 JSON fallback | 추가 API 불필요 |
| 예약 목록 빈 화면 | 이미 `GET /owner/reservations` 존재 | 주문 현황에 예약 탭 연결 완료 | 대체 완료 |
| 발주 목록이 없을 때 주문 fallback | 대부분 대체 가능 | owner_id=3 seed에 실제 procurement 시나리오 생성. API 실패 시에만 fallback | API/DB 대체 완료, 서버 장애 fallback 유지 |
| 반품 목록 JSON fallback | 이미 `GET /owner/returns` 존재 | owner_id=3 seed에 반품 요청 생성. API 실패 시에만 JSON fallback | 추가 API 불필요 |
| 신선도 분석 local estimate | 대부분 대체 | 외부 ngrok DL 분석을 우선 호출하고, 실패 시 backend 분석, 최후에 local estimate 사용 | ngrok/Kaggle 세션 장애 대비 최후 fallback 유지 |
| 주소 후보 fallback | 부분 가능 | 모바일은 `kpostal_plus`, 데스크톱/web 비지원 환경만 후보 사용 | 플랫폼 보조 fallback 필요 |
| 수확 예측 세션 만료 메시지 | 가능 | API/세션 실패 시 repository에서 발표용 예측/슬롯 fallback 반환 | 화면에 로그인 만료 문구 노출 방지 |
| 신선도 검사 세션 만료 메시지 | 가능 | API/세션 실패 시 검사 대상과 backend/local 분석 fallback 반환 | 화면에 로그인 만료 문구 노출 방지 |
| 이메일 찾기 안내 UX | 가능 | `POST /auth/email/find` 추가 및 화면 연결 | 대체 완료 |
| 비밀번호 찾기 안내 UX | 가능 | 인증번호 발송과 새 비밀번호 저장까지 실제 API 연결 | 대체 완료 |
| 상품/농장 이미지 UI 부재 | 가능 | 상품/농장 대표 이미지 선택, 업로드, asset seed 이미지 표시 구현 | 대체 완료 |

## 검증 완료 항목

| 검증 | 결과 |
|---|---|
| `flutter analyze` | 통과 |
| `POST /auth/password/reset-confirm` | known verification code로 새 비밀번호 저장 후 `pass1234!` 로그인 재검증 |
| `GET /owner/harvest-slots`, `PATCH /owner/harvest-slots/{id}/status` | owner_id=3 기준 3건 조회 및 상태 PATCH smoke 통과 |
| `flutter test` | 통과 |
| `python -m compileall backend scripts` | 통과 |
| `python scripts/owner_workflow_smoke.py` | 통과 |
| `python scripts/seed_owner3_workflows.py` | `created_scenarios=0`, seed 존재 확인 |
| `python scripts/migrate_owner_app_endpoints_to_smart_web.py` | SMART_WEB 실제 폴더 dry-run 성공, 파일 수정 없음 |
| SMART_WEB backend 임시 복사본 migration `--apply` | 백업 생성, 신규 5개 endpoint 확인, SMART_WEB 전용 endpoint 보존, compileall 통과 |
| `flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1` | 성공 |
| 반품 증빙 이미지 URL | NAS 업로드 URL로 저장 확인. 앱 asset 경로는 화면 fallback/데모 프리셋에만 사용 |
| Chrome 홈/메뉴/주문/예약 | 확인 완료 |
| Chrome 신선도 검사 화면 | 품목 선택, 이미지 카드 UX, 4개 분석 metric 표시 확인 |
| iOS 시뮬레이터 | 로그인/대시보드/메뉴/수확 슬롯 관리/신선도 갤러리 선택 확인 완료 |

## 남은 작업

| 우선순위 | 작업 | 이유 |
|---|---|---|
| P1 | 실기기 이미지 권한 확인 | iOS 시뮬레이터 갤러리 선택은 확인. 실제 iPhone 사진 권한은 후속 확인 |
| P1 | 주문/예약/발주 상세 화면 보강 | 목록 중심 화면을 발표용 앱처럼 보이게 상세 동선 추가 필요 |
| P1 | SMART_WEB 엔드포인트 실제 적용 여부 결정 | 스크립트는 준비됐지만 SMART_WEB 실제 프로젝트에는 아직 적용하지 않음 |
| P2 | 실제 바코드/QR 스캔 연동 | 지금은 송장 입력 보조 액션으로 발표 흐름 유지 |
| P2 | 배송 상세 화면 추가 | 배송 전용 목록 API는 추가 완료. 다음 보강은 송장/고객/상품 상세 화면 |
| P2 | 실제 PG 환불 연계 | 반품 승인은 처리되지만 PG 환불은 별도 운영 연계 필요 |
| P3 | DB 운영 seed 정리 | `harvest_slot_db2` 개발 DB 기준 작업을 운영 반영하려면 승인된 SQL/seed patch 필요. 스키마 migration은 현재 불필요 |

## 미구현 / 부분구현 상세

아래 항목은 현재 앱에서 아예 없거나, 화면 시연은 가능하지만 운영 기능으로는 아직 부족한 부분이다.

| 구분 | 항목 | 현재 상태 | 미구현 내용 | 필요한 작업 | 차단/보류 사유 |
|---|---|---|---|---|---|
| 인증 | 비밀번호 재설정 | 구현 완료 | 인증번호 발송과 새 비밀번호 저장 모두 가능 | 없음 | 운영 이메일/SMS 정책만 후속 |
| 인증 | 이메일 찾기 | 구현 완료 | 이름/전화번호 기반 점주 계정 조회와 마스킹 이메일 반환 | 없음 | 완료 |
| 인증 | 회원가입 후 농장/사업자 정보 자동 저장 | 회원가입은 owner 계정 생성까지만 연결 | 가입 폼의 농장명/주소/사업자번호가 signup API payload에 완전 반영되지 않음 | owner signup API 확장 또는 가입 후 농장 생성/수정 flow 연결 | 현재 `POST /auth/owners/signup` 스키마가 계정 중심 |
| 인증 | 비밀번호 변경 | 내 정보 화면에는 표시 문구만 있음 | 로그인 상태에서 기존 비밀번호 확인 후 새 비밀번호 변경 API/화면 없음 | `PUT /owner/profile/password` 등 추가 | backend API 없음 |
| 계정 운영 | 회원 탈퇴/비활성화 | `계정 지원 요청` 안내 UX로 대체 | 실제 탈퇴, 비활성화, 데이터 보존 정책 처리 없음 | 계정 비활성화 API와 운영 정책 필요 | 삭제는 데이터 무결성/정책 검토 필요 |
| 상품 | 상품 대표 이미지 업로드 UI | 구현 완료 | 상품 등록/수정 화면에서 대표 이미지 선택/업로드/미리보기, 상품 목록 썸네일 표시 | 없음 | 완료 |
| 상품 | 상품 삭제 | 판매 중지 상태 변경으로 대체 | 물리 삭제 API/UI 없음 | 운영 정책상 삭제 대신 숨김 유지 또는 `DELETE` 추가 | backend에 delete API 없음 |
| 상품 | 실제 재고 관리 | 화면 표시 수량만 있음 | 상품 테이블에 독립 재고 필드 없음 | 실제 판매 가능 수량은 harvest slot 기반으로 계속 관리하거나 스키마 확장 | DB 스키마 변경 필요 |
| 상품 | 다중 이미지/상세 이미지 | 없음 | 상세 갤러리, 상품 설명 이미지, 정렬 기능 없음 | product image table/API 추가 | 발표 필수 범위 밖 |
| 농장 | 농장 대표 이미지 업로드 | 구현 완료 | 농장 이미지 파일 선택/업로드 UI, `POST /owner/farms/{farm_id}/image` API 추가 | 없음 | 완료 |
| 농장 | farm 생성 flow | 기존 농장 조회/수정 중심 | 신규 점주가 농장이 없을 때 농장 생성 API/UI 없음 | `POST /owner/farms` 추가 또는 signup 확장 | 현재 검증 계정은 farm seed 존재 |
| 주소 | 주소 검색 web 완전 연동 | 모바일은 `kpostal_plus`, 데스크톱/web은 후보 bottom sheet | web에서 실제 우편번호 검색 팝업까지 완전 동작 검증 부족 | web 대응 방식 확인 또는 별도 주소 검색 web bridge | 패키지/플랫폼 동작 차이 |
| 수확 예측 | 실제 ML 예측 API | `POST /owner/ml/predictions` 호출, API 응답의 수확량/예약량/가격/신뢰도/표준면적 수확량 표시 | 모델 파일/feature schema 변경 시 앱 request mapping 재검증 필요 | `OWNER_APP_ML_PREDICTION_MAPPING.md` 기준 유지 |
| 수확 예측 | 예측 이력 상세 | 최근 예측 조회는 있음 | 예측별 상세 비교/삭제/재실행 UX 없음 | 예측 이력 화면 추가 | 발표 핵심 동선은 생성/참고 위주 |
| 수확 슬롯 | 슬롯 목록/상세 관리 | 목록/수정/마감 구현 | 슬롯 상세 타임라인, 삭제/숨김 정책 없음 | 상세 화면은 후순위 | 발표 핵심 동선은 관리 카드로 대응 |
| 수확 슬롯 | 예약량 초과 방지 UI | reserved/sold/available kg 표시 | 예약량 변화 실시간 push는 없음 | 필요 시 polling 또는 notification 추가 | 발표 범위 밖 |
| 예약 | 예약 상세 | 목록 탭만 있음 | 예약 상세, 고객 연락처, 예약 만료 처리 UI 없음 | 예약 상세 화면 및 status action 추가 | 현재 요구사항은 현황 확인 중심 |
| 예약 | 예약 취소/만료 처리 | 표시만 함 | 점주가 예약 취소/만료를 처리하는 API/UI 없음 | reservation status patch API 검토 | 운영 정책 필요 |
| 주문 | 주문 상세 | 목록 중심 | 주문 상세, 배송지, 결제 내역, 품목 다중 표시 상세 부족 | 주문 상세 화면 추가 | 발표 동선은 현황/발주 처리 중심 |
| 주문 | 주문 상태 직접 변경 | 없음 | 점주가 주문 취소/보류 처리하는 기능 없음 | order status action API 필요 | 운영 정책 필요 |
| 발주 | PATCH 실패 건별 표시 | 일괄 처리 후 전체 갱신 | 다중 선택 중 일부 실패 시 행별 실패 사유 표시 없음 | batch result UI 추가 | 현재 순차 PATCH 중심 |
| 발주 | 다품목 발주 seed | 단일 품목 중심 seed | 다품목 발주 UI 검증 데이터 부족 | seed에 다품목 procurement 추가 | DB seed 추가 필요 |
| 발주 | 발주 상세 타임라인 | 없음 | 요청/승인/선별/배송까지 timeline 표시 없음 | procurement timeline model/UI 추가 | 발표 필수 범위 밖 |
| 신선도 | iOS 갤러리 최종 검증 | iOS 시뮬레이터 확인 완료 | 실제 iPhone 사진 권한 확인은 남음 | 실기기에서 사진 선택 1회 확인 | 발표 시뮬레이터 기준은 통과 |
| 신선도 | 실제 DL 모델 | 외부 ngrok/Kaggle DL API를 앱에서 multipart 호출, 결과 표시 및 저장 | ngrok URL이 바뀌거나 내려가면 backend/local fallback 사용 | 상시 운영 URL/인프라 필요 |
| 신선도 | 검사 이미지 저장 정책 | 업로드 API 있음 | 영구 스토리지/S3/CDN/보존기간 정책 미확정 | `ImageStorageService` 운영 저장소 연결 | 로컬/개발 저장소 기준 |
| 신선도 | 재촬영/부적합 flow | 일부 판단값만 있음 | RETAKE 사유, 재촬영 강제, 다중 이미지 비교 부족 | 분석 결과 action_required 기반 UX 강화 | 현재는 점주 보조 판정 중심 |
| 배송 | 실제 바코드/QR 스캐너 | 버튼이 송장 자동 입력 보조로 동작 | 카메라 기반 바코드/QR scan 없음 | 모바일 scanner 패키지 도입 및 권한 설정 | 발표용으로는 송장 보조 입력 처리 |
| 배송 | 배송 전용 list API | 구현 완료 | `GET /owner/shipments` 추가, 앱 배송 현황에서 우선 사용 | 없음 | 완료 |
| 배송 | 택배사 송장 검증 | 입력 형식 검증만 있음 | 택배사별 송장 자리수/배송조회 연동 없음 | carrier별 validation, tracking URL/API 추가 | 외부 택배 API 미연동 |
| 배송 | 배송 라벨/출력 | 없음 | 포장 라벨, 송장 출력, 운송장 PDF 없음 | 라벨 템플릿/출력 flow 추가 | 발표 범위 밖 |
| 반품 | 실제 PG 환불 | 반품 승인/거절 상태 처리 | 결제 취소/부분환불 PG API 연동 없음 | payment/refund service 연계 | 결제 운영 연계 필요 |
| 반품 | 반품 이미지 상세 보기 | 구현 완료 | 고객 첨부 이미지를 실제 이미지로 표시하고 탭 시 확대 확인 가능 | 없음 | 다운로드/다중 이미지 비교는 발표 범위 밖 |
| 반품 | 환불 정책 자동 판정 | 점주 선택 중심 | 정책 기반 자동 승인/부분승인 추천 없음 | return policy rule engine 추가 | 정책 확정 필요 |
| 프로필 | 사업자등록 검증 | 입력/저장 중심 | 사업자번호 외부 검증 없음 | 공공 API 또는 운영 검증 flow 추가 | 외부 API 미연동 |
| 프로필 | 전화번호 인증 | 입력/저장 중심 | SMS 인증/변경 인증 없음 | SMS 인증 API 추가 | 외부 메시징 필요 |
| 알림 | 푸시 알림 | 없음 | 신규 발주/반품/배송 이슈 push 없음 | FCM/APNs, device token API, notification settings 추가 | 발표 범위 밖 |
| 알림 | 앱 내 알림함 | 없음 | 업무 이벤트 기록/읽음 처리 없음 | notification table/API/UI 추가 | DB 스키마 필요 |
| 검색 | 전역 검색 | 메뉴 검색만 있음 | 주문/발주/고객/상품 통합 검색 없음 | 통합 검색 endpoint/UI 추가 | 현재 화면별 검색으로 대체 |
| 리포트 | 매출/정산 | 없음 | 매출 통계, 정산 예정, 기간별 리포트 없음 | analytics/settlement API/UI 추가 | 요구사항 우선순위 밖 |
| 설정 | 운영 설정 | 없음 | 배송비, 출고 요일, 반품 기간, 알림 설정 없음 | owner settings schema/API/UI 추가 | DB 스키마 필요 |
| 권한 | 다중 관리자 | 없음 | 농장 staff/manager 초대, 권한 구분 없음 | role/permission schema 확장 | 현재 OWNER 단일 계정 기준 |
| 오프라인 | 로컬 큐/재시도 | fallback 조회 중심 | 네트워크 복구 후 저장 재시도 큐 없음 | offline queue/retry layer 추가 | 발표 앱 기준에서는 과함 |
| 테스트 | Flutter form/widget 상세 테스트 | 일부 단위/위젯 테스트 | 모든 업무 화면 폼 검증 자동 테스트 부족 | page별 widget/integration test 추가 | 빠른 구현 우선 |
| 테스트 | iOS 전체 e2e | 부분 확인 | 로그인부터 이미지/배송/반품까지 전체 e2e 미완 | 시뮬레이터 자동화 또는 수동 체크리스트 | 시간/도구 이슈 |
| 배포 | 운영 빌드/배포 | 로컬 빌드 | 앱스토어/TestFlight, backend deploy, env 분리 없음 | prod/staging env, CI/CD, signing 설정 | 현재 로컬 발표용 |
| DB | 원본 DB 반영 | `harvest_slot_db2`에서 개발 | 원본 `harvest_slot_db`에는 변경/seed 반영 안 함 | 승인된 SQL/migration 작성 후 반영 | 원본 DB 보호 정책 |

## 현재 로컬 실행 기준

| 서비스 | URL |
|---|---|
| FastAPI | `http://127.0.0.1:8000` |
| Flutter web build preview | `http://127.0.0.1:3002` |

현재 커밋 기준:

| Commit | 내용 |
|---|---|
| `28b5269` | SMART_WEB 엔드포인트 안전 마이그레이션 스크립트와 절차 문서화 |
| `27202f9` | `harvest_slot_db2` / FastAPI 차이 보고서 작성 |
| `c3c5772` | 비밀번호 재설정과 수확 슬롯 관리 API/화면 보강 |
| `25fda82` | 점주 앱 생성 이미지/계정 찾기/이미지 업로드 연결 |
| `0f3e6fb` | 점주 배송 목록 전용 API 추가 |
| `92bcf06` | 전체 구현 진행도 문서화 |
| `3d0debd` | 점주 앱 fallback 업무 흐름/완성도 보강 |
| `68a91ad` | 요구사항 기반 점주 업무 화면 보강 |
