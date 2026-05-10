# harvest_slot_db2 / FastAPI 차이 보고서

작성일: 2026-05-11

## 비교 기준

| 항목 | 기준 |
|---|---|
| SMART_APP 경로 | `/Users/cheng80/Desktop/smart_app` |
| SMART_APP 커밋 | `main@c3c5772` |
| SMART_WEB 경로 | `/Users/cheng80/Desktop/smart_web` |
| SMART_WEB 커밋 | `main@33bff03` |
| 원본 DB | `harvest_slot_db` |
| 작업 DB | `harvest_slot_db2` |

주의: `.env`에 DB/SMTP 비밀번호가 있으므로 이 문서에는 접속 비밀번호나 SMTP 앱 비밀번호를 기록하지 않는다.

## DB 스키마 비교 결론

`harvest_slot_db2`는 `harvest_slot_db` 대비 **새로 만든 테이블, 삭제한 테이블, 추가/삭제/수정한 컬럼, 인덱스, FK가 없다.**

즉 현재까지 작업은 DB2에 **스키마 변경 없이 데이터만 추가/수정**한 상태다.

| 비교 항목 | 결과 |
|---|---|
| 테이블 추가 | 없음 |
| 테이블 삭제 | 없음 |
| 컬럼 추가 | 없음 |
| 컬럼 삭제 | 없음 |
| 컬럼 타입/nullable/default/extra/key 변경 | 없음 |
| 인덱스 추가/삭제/변경 | 없음 |
| FK 추가/삭제/변경 | 없음 |

## DB 데이터 차이

`harvest_slot_db2`는 원본 DB 복제 후 발표/검증용 owner 흐름 데이터를 추가한 상태다. 주요 차이는 row count 기준으로 아래와 같다.

| 테이블 | `harvest_slot_db` | `harvest_slot_db2` | 차이 |
|---|---:|---:|---:|
| `accounts` | 10 | 17 | +7 |
| `customer_profiles` | 7 | 14 | +7 |
| `email_verifications` | 5 | 7 | +2 |
| `farms` | 2 | 2 | +0 |
| `harvest_slots` | 42 | 42 | +0 |
| `ml_predictions` | 2 | 7 | +5 |
| `order_items` | 31 | 37 | +6 |
| `orders` | 29 | 35 | +6 |
| `owner_profiles` | 3 | 3 | +0 |
| `payments` | 24 | 30 | +6 |
| `procurement_items` | 21 | 27 | +6 |
| `procurements` | 21 | 27 | +6 |
| `products` | 6 | 7 | +1 |
| `quality_inspections` | 4 | 7 | +3 |
| `refunds` | 4 | 5 | +1 |
| `reservation_items` | 39 | 45 | +6 |
| `reservations` | 37 | 43 | +6 |
| `return_requests` | 7 | 8 | +1 |
| `shipments` | 13 | 15 | +2 |

### DB2 데이터 변경 성격

| 구분 | 내용 |
|---|---|
| 기준 점주 | `cheng80@gmail.com`, `owner_id=3`, `account_id=12` |
| 발표용 상품 | 양광/부사 사과 상품과 발표 검증용 상품 데이터 |
| 이미지 URL | 생성형 AI 이미지 asset 경로를 `farms.farm_image_url`, `products.image_url`, 일부 품질/반품 관련 evidence 경로에 반영 |
| 업무 흐름 데이터 | 주문, 결제, 예약, 발주, 신선도 검사, 배송, 반품 흐름을 owner_id=3 기준으로 검증 가능하게 seed |
| 스키마 영향 | 없음. 운영 DB 반영 시에는 migration이 아니라 seed/data patch 성격 |

## FastAPI 엔드포인트 비교 요약

| 항목 | SMART_APP backend | SMART_WEB backend |
|---|---:|---:|
| AST 기준 라우터 엔드포인트 수 | 66 | 67 |
| SMART_APP에만 있는 엔드포인트 | 5 |
| SMART_WEB에만 있는 엔드포인트 | 6 |

### SMART_APP에 추가된 엔드포인트

| Method | Path | 파일 | 목적 |
|---|---|---|---|
| `POST` | `/auth/email/find` | `backend/app/routers/auth_router.py` | 이름/전화번호 기반 점주 이메일 찾기 |
| `POST` | `/auth/password/reset-request` | `backend/app/routers/auth_router.py` | 비밀번호 재설정 인증번호 발송 요청 |
| `POST` | `/auth/password/reset-confirm` | `backend/app/routers/auth_router.py` | 인증번호 확인 후 새 비밀번호 저장 |
| `POST` | `/owner/farms/{farm_id}/image` | `backend/app/routers/owner_router.py` | 농장 대표 이미지 업로드 및 `farms.farm_image_url` 갱신 |
| `GET` | `/owner/shipments` | `backend/app/routers/shipment_router.py` | 점주 배송 현황 전용 목록 조회 |

### SMART_WEB에는 있으나 SMART_APP에는 없는 엔드포인트

| Method | Path | SMART_WEB 파일 | 비고 |
|---|---|---|---|
| `GET` | `/me/addresses` | `app/routers/address_router.py` | 고객 배송지 목록 |
| `POST` | `/me/addresses` | `app/routers/address_router.py` | 고객 배송지 생성 |
| `PUT` | `/me/addresses/{address_id}` | `app/routers/address_router.py` | 고객 배송지 수정 |
| `PATCH` | `/me/addresses/{address_id}/default` | `app/routers/address_router.py` | 기본 배송지 설정 |
| `DELETE` | `/me/addresses/{address_id}` | `app/routers/address_router.py` | 고객 배송지 삭제 |
| `PUT` | `/me` | `app/routers/auth_router.py` | 현재 계정 정보 수정. SMART_APP은 점주 전용 `PUT /owner/profile`을 사용 |

### 동일한 엔드포인트지만 구현 파일이 달라진 영역

아래 파일들은 SMART_WEB 대비 SMART_APP에서 구현 내용이 다르다. 엔드포인트 경로가 동일해도 응답 필드, fallback 대응, owner 앱용 직렬화가 달라질 수 있다.

| 영역 | SMART_APP 변경 파일 | 성격 |
|---|---|---|
| 인증 | `auth_router.py`, `auth_schema.py`, `auth_service.py`, `email_verification_service.py` | 이메일 찾기, 비밀번호 재설정 요청/확정 추가 |
| 점주 | `owner_router.py`, `owner_service.py` | 농장 이미지 업로드 endpoint 추가, dashboard/profile 응답 보강 |
| 상품/농장 | `product_service.py` | farm/product image URL 직렬화 및 업로드 처리 |
| 배송 | `shipment_router.py`, `shipment_service.py` | 점주 배송 현황 전용 list API 추가 |
| ML/주문/발주/품질 | `ml_service.py`, `order_service.py`, `procurement_service.py`, `quality_analysis_service.py` | owner 앱 발표 흐름을 위한 응답/판정/fallback 보강 |
| 라우터 구성 | `router.py` | SMART_APP에는 address router include가 없음 |

## 엔드포인트 차이의 앱 영향

| 차이 | 앱 영향 |
|---|---|
| `/auth/email/find` 추가 | 이메일 찾기 화면이 안내 UX가 아니라 실제 DB 조회로 동작 |
| `/auth/password/reset-request`, `/auth/password/reset-confirm` 추가 | 비밀번호 찾기 화면에서 인증번호 발송과 새 비밀번호 저장까지 가능 |
| `/owner/farms/{farm_id}/image` 추가 | 농장 정보 수정 화면에서 대표 이미지 업로드 가능 |
| `/owner/shipments` 추가 | 배송 현황 화면이 주문 목록 파생이 아니라 배송 전용 API를 우선 사용 |
| address endpoints 없음 | SMART_APP 점주앱은 고객 배송지 관리 화면을 직접 다루지 않음. 주소 입력은 Flutter `kpostal_plus`/후보 fallback으로 처리 |
| `PUT /me` 없음 | SMART_APP은 고객/공통 계정 수정 대신 점주 전용 `PUT /owner/profile`로 처리 |

## 운영 DB 반영 시 필요한 판단

현재 `harvest_slot_db2`에는 스키마 변경이 없으므로 운영 반영은 아래 중 하나다.

| 선택지 | 내용 | 승인 필요성 |
|---|---|---|
| 데이터 seed만 반영 | owner_id=3 기준 발표 데이터, 이미지 URL, 업무 흐름 데이터를 운영/검증 DB에 insert/update | 필요 |
| API 코드만 반영 | DB 스키마 변경 없이 FastAPI 코드 배포 | 필요 |
| 원본 DB 스키마 migration | 현재 기준 필요 없음 | 불필요 |

## 재확인 명령

이 문서는 아래 방식으로 확인했다.

```bash
# DB 비교
python - <<'PY'
# information_schema.TABLES / COLUMNS / STATISTICS / KEY_COLUMN_USAGE 비교
PY

# FastAPI 라우터 비교
python - <<'PY'
# ast로 app/routers/*_router.py의 @router.get/post/put/patch/delete 추출
PY
```

