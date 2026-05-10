# Flutter 점주 앱 구현 가이드

## 1. 폴더 구조

```text
frontend_owner_app/
  lib/
    main.dart
    core/
      router.dart
      api_client.dart
      auth_store.dart
      camera_service.dart
      theme.dart
    models/
      farm_model.dart
      product_model.dart
      ml_prediction_model.dart
      harvest_slot_model.dart
      procurement_model.dart
      quality_inspection_model.dart
      shipment_model.dart
      return_model.dart
    pages/
      owner_login_page.dart
      dashboard_page.dart
      farm_edit_page.dart
      product_list_page.dart
      product_edit_page.dart
      ml_prediction_page.dart
      harvest_slot_page.dart
      owner_orders_page.dart
      procurement_list_page.dart
      procurement_detail_page.dart
      quality_camera_page.dart
      shipment_page.dart
      return_refund_page.dart
      owner_profile_page.dart
    widgets/
      owner_status_card.dart
      procurement_item_card.dart
      quality_result_card.dart
      form_section.dart
```

## 2. 주요 화면 흐름

```text
Login
→ Dashboard
→ Product/Farm 관리
→ ML Prediction
→ Harvest Slot 확정
→ Procurement 승인
→ Quality Inspection
→ Shipment
→ Return/Refund
```

## 3. 카메라 및 이미지 업로드

신선도 검사는 다음 순서로 구현한다.

```text
1. 발주 품목 선택
2. 카메라 촬영
3. 이미지 미리보기
4. POST /owner/quality-inspections Multipart 전송
5. 모델 결과 표시
6. 점주 확정 등급/판정 저장
```

## 4. 발주 결정 화면 상태

| 상태 | 버튼 |
|---|---|
| `REQUESTED` | 승인, 부분승인, 거절 |
| `APPROVED` | 신선도 검사로 이동 |
| `PARTIAL_APPROVED` | 신선도 검사로 이동 |
| `REJECTED` | 상세 보기 |

## 5. ML 예측 화면 표시

ML 예측 결과 카드에는 다음을 표시한다.

```text
예측 수확 범위
예상 수확량
제안 예약 가능 범위
추천 가격
신뢰도
안전 계수
주의 메시지
```

그 아래 점주 확정 입력 폼을 배치한다.

```text
확정 수확 시작일
확정 수확 종료일
확정 예약 가능 kg
확정 판매가
고객 고지 문구
```

## 6. 화면 개발 우선순위

1. 로그인
2. 대시보드
3. 상품/농장 관리
4. ML 예측/수확 슬롯 확정
5. 발주 목록/상세/결정
6. 신선도 검사
7. 배송 관리
8. 반품/환불 관리
