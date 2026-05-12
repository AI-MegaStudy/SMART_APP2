# 사용자 예약웹 튜토리얼 적용 가이드

작성일: 2026-05-12

## 목적

점주 앱에서 서브타이틀 3탭으로 실행하는 설명형 튜토리얼 방식을 사용자 예약웹(`/Users/cheng80/Desktop/smart_web`)에 옮기기 위한 적용 문서다.

목표는 별도 데모 페이지를 만들지 않고 실제 사용자 웹 화면 위에서 상품 탐색, 예약, 주문, 결제, 배송 확인, 반품 신청 흐름을 설명하는 것이다.

## 적용 패키지

Flutter Web 기준으로 아래 패키지를 사용한다.

```yaml
dependencies:
  tutorial_coach_mark: ^1.3.3
```

현재 점주 앱 적용 파일:

- 패키지 선언: `pubspec.yaml`
- 튜토리얼 매니저: `lib/demo/owner_coach_tour_manager.dart`
- 진입점: `lib/view/home.dart`
- 타겟 키 모음: `lib/demo/owner_demo_manager.dart`의 `DemoTargetKeys`

사용자 웹에서는 같은 구조를 이름만 바꿔 적용한다.

권장 파일명:

- `lib/demo/customer_coach_tour_manager.dart`
- `lib/demo/customer_demo_target_keys.dart`

## 적용 방식

### 1. 타겟 키 정의

실제 화면 위젯에 붙일 `GlobalKey`를 한 곳에 모은다.

예시:

```dart
class CustomerDemoTargetKeys {
  static final homeHero = GlobalKey(debugLabel: 'demo.customer.home.hero');
  static final featuredProducts = GlobalKey(debugLabel: 'demo.customer.featured.products');
  static final productCard = GlobalKey(debugLabel: 'demo.customer.product.card');
  static final productImage = GlobalKey(debugLabel: 'demo.customer.product.image');
  static final slotSelector = GlobalKey(debugLabel: 'demo.customer.slot.selector');
  static final addToBasket = GlobalKey(debugLabel: 'demo.customer.add.to.basket');
  static final basketItems = GlobalKey(debugLabel: 'demo.customer.basket.items');
  static final reservationConfirm = GlobalKey(debugLabel: 'demo.customer.reservation.confirm');
  static final checkoutAddress = GlobalKey(debugLabel: 'demo.customer.checkout.address');
  static final paymentApprove = GlobalKey(debugLabel: 'demo.customer.payment.approve');
  static final orderTimeline = GlobalKey(debugLabel: 'demo.customer.order.timeline');
  static final returnReason = GlobalKey(debugLabel: 'demo.customer.return.reason');

  const CustomerDemoTargetKeys._();
}
```

주의:

- 하나의 `GlobalKey`는 동시에 한 위젯에만 붙인다.
- 탭 전환이나 목록 재사용으로 같은 키가 중복 생성되지 않게 첫 번째 카드에만 조건부로 붙인다.
- 제목만 강조하지 말고 실제 카드, 선택 영역, 버튼, 입력 필드에 붙인다.

### 2. 시작 트리거

점주 앱은 홈 화면 서브타이틀인 농장명을 3번 빠르게 탭하면 튜토리얼을 시작한다.

사용자 웹도 일반 사용자에게 보이지 않는 방식으로 숨긴다.

권장 트리거:

- 홈 상단 서비스 서브타이틀 또는 작은 설명 문구 3번 빠른 탭
- 예: `농가 직배송 예약 플랫폼` 문구 3탭

메인 타이틀이나 CTA 버튼에는 트리거를 걸지 않는다. 사용자가 실수로 누를 가능성이 낮은 보조 문구가 적절하다.

### 3. 튜토리얼 매니저 구성

점주 앱의 `OwnerCoachTourManager`와 같은 방식으로 별도 매니저를 둔다.

핵심 책임:

- 현재 화면을 실제 라우트로 이동한다.
- 대상 위젯이 생길 때까지 기다린다.
- `Scrollable.ensureVisible()`로 대상이 보이게 한다.
- 이동/스크롤 후 `tutorial_coach_mark`를 표시한다.
- 버블에는 핵심 설명만 담는다.
- `스킵`, `다음`은 버블 안에 텍스트 버튼으로 둔다.

권장 표시 규칙:

- 전체 딤은 약하게 유지한다. 현재 점주 앱은 `opacityShadow: 0.24`.
- 버블 글자는 발표용으로 충분히 크게 둔다.
- 하단 대상일 때 버블은 위쪽에, 상단 대상일 때 버블은 아래쪽에 배치한다.
- 화면 전환 후 바로 표시하지 말고 0.8초 내외 대기한다.
- 스크롤 후 0.1~0.2초 기다린 뒤 표시한다.

### 4. 버블 구성

점주 앱 기준:

- 배경: 흰색
- 제목: 24px, 굵게
- 설명: 20px, 굵게
- 액션: 왼쪽 `스킵`, 오른쪽 `다음`
- 버튼 배경 없음. 글자만 표시

사용자 웹에서도 같은 원칙을 유지한다.

버블 문구는 개발 용어 대신 고객 행동 중심으로 쓴다.

좋은 예:

- `이 상품은 농가가 확정한 수확 기간 안에서 예약할 수 있습니다.`
- `예약함에서 수량과 금액을 확인한 뒤 서버 예약으로 전환합니다.`
- `결제가 끝나면 농가 확인 단계로 넘어갑니다.`

피할 표현:

- `API 호출`
- `DB 반영`
- `procurement 생성`
- `mock 데이터`
- `feature`, `model_version`

단, 발표자가 기술 설명을 해야 하는 별도 문서에서는 API 이름을 써도 된다. 실제 버블에는 고객이 보는 의미만 쓴다.

## 적용 순서

1. `pubspec.yaml`에 `tutorial_coach_mark: ^1.3.3` 추가
2. `flutter pub get` 실행
3. `CustomerDemoTargetKeys` 추가
4. 홈, 상품 목록, 상품 상세, 예약함, 예약 확인, 주문서, 결제, 주문 완료, 주문 상세, 반품 신청 화면에 키 부착
5. `CustomerCoachTourManager` 추가
6. 홈 서브타이틀 3탭 트리거 연결
7. 실제 라우트 이동 함수 연결
8. 시나리오 순서대로 `_show()` 호출 작성
9. 화면 밖 대상은 `Scrollable.ensureVisible()` 후 표시
10. `flutter analyze`, `flutter test`, 웹 실행 확인

## 사용자 예약웹 시나리오 흐름

기획서 기준 고객 여정:

```text
홈
→ 상품 목록
→ 상품 상세
→ 수확 슬롯 선택
→ 로컬 예약함
→ 예약 확인
→ 서버 예약 생성
→ 주문서 작성
→ Mock 결제
→ 주문 완료
→ 주문 상세 확인
→ 배송 확인
→ 반품 신청
```

### 1. 홈

1. 서비스 소개
   - 대상: 홈 상단 소개 영역
   - 설명: 과수농가가 확정한 수확 슬롯을 기준으로 예약하는 서비스임을 안내한다.

2. 추천 상품
   - 대상: 추천 상품 카드
   - 설명: 예약 가능한 상품과 수확 예정 기간을 한눈에 확인한다.

3. 상품 목록 이동
   - 대상: 상품 보기 버튼 또는 상품 카드
   - 설명: 실제 상품 목록으로 이동해 예약 가능한 상품을 탐색한다.

### 2. 상품 목록

4. 상품 필터
   - 대상: 과일 종류 필터
   - 설명: 원하는 과일 종류와 예약 가능 상태를 기준으로 상품을 좁힌다.

5. 상품 카드
   - 대상: 첫 번째 예약 가능 상품 카드
   - 설명: 가격, 포장 단위, 수확 예정 범위, 농장명을 확인한다.

### 3. 상품 상세

6. 상품 이미지와 농장 정보
   - 대상: 상품 대표 이미지/농장명 영역
   - 설명: 실제 농가와 상품 정보를 확인하고 예약할 상품인지 판단한다.

7. 수확 슬롯 선택
   - 대상: 슬롯 선택 카드
   - 설명: 농가가 확정한 수확 기간과 예약 가능 수량 안에서 선택한다.

8. 수량 선택
   - 대상: 수량 stepper 또는 입력 컨트롤
   - 설명: 예약할 박스 수량을 선택한다. 서버 예약 시 한 번 더 검증된다.

9. 예약함 담기
   - 대상: `예약함에 담기` 버튼
   - 설명: 바로 결제하지 않고 예약함에서 품목과 수량을 다시 확인한다.

### 4. 로컬 예약함

10. 예약함 품목
    - 대상: 예약함 품목 목록
    - 설명: 선택한 상품, 슬롯, 수량, 금액을 주문 전 확인한다.

11. 수량 변경/삭제
    - 대상: 수량 변경 또는 삭제 버튼
    - 설명: 서버 예약 전까지는 로컬 예약함에서 자유롭게 조정한다.

12. 예약 확인 이동
    - 대상: `예약 확인` 버튼
    - 설명: 서버에 예약을 생성하기 전 마지막 확인 단계로 이동한다.

### 5. 예약 확인

13. 예약 조건 확인
    - 대상: 수확 예정 범위, 수량, 가격, 안내 문구
    - 설명: 농가 확정 기준으로 예약 조건을 다시 확인한다.

14. 서버 예약 생성
    - 대상: `예약 생성` 또는 `예약 확정` 버튼
    - 설명: 이 시점부터 서버가 슬롯 수량을 점유하고 만료 시간을 관리한다.

### 6. 주문서 작성

15. 배송 정보 입력
    - 대상: 수령인, 전화번호, 주소 입력 영역
    - 설명: 예약을 주문으로 전환하기 위해 배송 정보를 입력한다.

16. 주문 생성
    - 대상: `주문하기` 버튼
    - 설명: 예약 상태와 만료 시간을 확인한 뒤 주문을 생성한다.

### 7. Mock 결제

17. 결제 금액 확인
    - 대상: 주문 금액 카드
    - 설명: 예약 수량과 확정 판매가 기준으로 결제 금액을 확인한다.

18. 결제 승인
    - 대상: `결제하기` 버튼
    - 설명: 결제가 완료되면 농가 확인 단계로 넘어간다.

### 8. 주문 완료

19. 주문 완료 안내
    - 대상: 주문 완료 메시지
    - 설명: 결제 완료 후 농가가 출고 가능 여부를 확인하는 단계임을 안내한다.

20. 주문 상세 이동
    - 대상: `주문 상세 보기` 버튼
    - 설명: 이후 상태는 주문 상세에서 확인한다.

### 9. 마이페이지 주문 목록/상세

21. 주문 목록
    - 대상: 주문 카드
    - 설명: 결제 완료, 농가 확인 중, 배송 중 같은 상태를 목록에서 확인한다.

22. 주문 상세 타임라인
    - 대상: 상태 타임라인
    - 설명: 예약, 결제, 농가 승인, 선별, 배송 단계를 순서대로 확인한다.

23. 배송 정보
    - 대상: 송장번호/배송 상태 영역
    - 설명: 배송이 시작되면 송장과 배송 상태가 표시된다.

### 10. 반품 신청

24. 반품 신청 진입
    - 대상: `반품 신청` 버튼
    - 설명: 배송 완료 주문에 한해 반품 요청을 접수한다.

25. 반품 사유
    - 대상: 사유 코드 선택
    - 설명: 상품 손상, 오배송 등 요청 사유를 선택한다.

26. 증빙 이미지
    - 대상: 이미지 첨부 영역
    - 설명: 상품 상태를 확인할 수 있는 사진을 첨부한다.

27. 요청 금액과 제출
    - 대상: 요청 금액, `반품 신청` 버튼
    - 설명: 요청 내용을 확인한 뒤 접수한다. 이후 상태는 주문 상세에서 추적한다.

## 구현 시 주의사항

- 튜토리얼은 실제 라우트와 실제 위젯 위에서만 동작한다.
- 별도 가짜 튜토리얼 화면을 만들지 않는다.
- 페이지 이동 중에는 기존 coach mark를 반드시 종료한다.
- 긴 목록은 첫 번째 의미 있는 카드에만 키를 붙인다.
- 하단 고정 버튼이 있는 화면은 버블이 버튼을 가리지 않게 `ContentAlign.top`을 우선 고려한다.
- 상품 상세, 예약함, 결제, 반품 신청은 실제 저장 직전까지만 보여도 된다.
- 결제/반품 제출처럼 외부 상태를 바꾸는 버튼은 발표용 계정과 seed 데이터에서만 수행한다.
- 고객 웹에는 ML/DL 내부 결과를 직접 노출하지 않는다. 수확 예측 결과는 농가가 확정한 수확 기간/수량/가격으로만 보여준다.

## 검증 체크리스트

- 홈 서브타이틀 3탭으로만 시작되는가.
- 각 단계가 실제 페이지 이동과 실제 UI 위에서 진행되는가.
- 상품 카드, 슬롯 선택, 예약함, 예약 생성, 주문서, 결제, 주문 상세, 반품 신청이 빠지지 않는가.
- 버블이 화면 밖으로 밀리지 않는가.
- 같은 `GlobalKey`가 동시에 두 번 붙지 않는가.
- 스크롤 후 대상 위치가 안정된 뒤 coach mark가 표시되는가.
- 화면 또는 `다음` 클릭으로 다음 단계가 정상 진행되는가.
- `스킵` 클릭 시 즉시 종료되는가.
- `flutter analyze`와 `flutter test`가 통과하는가.
