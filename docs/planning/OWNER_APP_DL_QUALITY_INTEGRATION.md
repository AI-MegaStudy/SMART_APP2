# 점주 앱 신선도 DL 연동 정리

작성일: 2026-05-11

## 목적

신선도 검사 화면에서 점주가 선택한 사과 이미지를 외부 DL 분석 서버로 먼저 전송한다. 외부 서버가 응답하면 실제 분석값을 화면에 표시하고 저장한다. 외부 서버 주소가 없거나 ngrok/Kaggle 세션이 내려가면 기존 백엔드 분석 또는 앱 내부 보조 판정으로 자동 전환해 발표 흐름이 끊기지 않게 한다.

## 외부 DL 호출

기본 호출 주소:

```text
https://imbecile-plow-unboxed.ngrok-free.dev/owner/quality-inspections
```

앱 빌드 시 다른 ngrok 주소를 쓰려면 아래 dart define을 사용한다.

```bash
flutter build ios --simulator \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 \
  --dart-define=DL_QUALITY_API_URL=https://새-ngrok주소/owner/quality-inspections
```

빈 값으로 빌드하면 외부 DL 호출을 건너뛰고 기존 백엔드/보조 판정으로 진행한다.

```bash
--dart-define=DL_QUALITY_API_URL=
```

## 호출 순서

1. 앱에서 검사 대상 발주 품목을 선택한다.
2. 갤러리 또는 데모 프리셋 이미지로 `Uint8List` 이미지 bytes를 확보한다.
3. 이미지는 기존 백엔드 이미지 업로드 API에 먼저 저장 시도한다.
4. 앱이 외부 DL 서버에 multipart/form-data로 이미지를 전송한다.
   - field name: `image`
   - file name: 선택 이미지명
   - content type: png/webp/jpeg 자동 판별
5. 외부 DL 성공 시 해당 값을 화면에 표시한다.
6. 외부 DL 실패 시 기존 백엔드 `/owner/quality-inspections/analyze`로 전환한다.
7. 백엔드 분석도 실패하면 앱 내부 보조 판정으로 전환한다.
8. 저장 시 화면에 표시된 분석값을 `/owner/quality-inspections`에 같이 보낸다.

## 응답값 표시

외부 DL 응답 중 앱 화면에 표시하는 값:

| 응답 필드 | 화면 표현 |
| --- | --- |
| `model_grade` | 추천 등급 |
| `freshness_score` | 신선도 |
| `color_score` | 색상 점수 |
| `roundness_score` | 형태 점수 |
| `bruise_probability` | 멍 확률 |
| `model_decision` | 모델 판정. 화면에서는 `통과`, `확인 필요`로 번역 |

화면에 직접 노출하지 않고 debug console에서만 확인하는 값:

| 응답 필드 | 용도 |
| --- | --- |
| `model_version` | 실제 DL 모델 버전 확인 |
| `angle_label` | 촬영 각도 판단 |
| `angle_confidence` | 각도 판정 신뢰도 |
| `grade_confidence` | 등급 판정 신뢰도 |
| `image_quality` | 밝기/노출/채도/흐림 등 이미지 품질 점검 |

## fallback 정책

| 단계 | 성공 시 | 실패 시 |
| --- | --- | --- |
| 외부 DL ngrok | 실제 DL 결과 표시 | 백엔드 분석 API 호출 |
| 백엔드 분석 API | 백엔드 분석 결과 표시 | 앱 내부 보조 판정 |
| 앱 내부 보조 판정 | 발표 흐름 유지 | 없음 |

점주 화면에는 `fallback`, `ngrok`, `Kaggle`, `API 실패` 같은 개발자용 표현을 노출하지 않는다. 개발자는 Flutter debug console에서 아래 로그로 확인한다.

```text
[API 정상][quality.dl] ...
[API 폴백][quality.dl] ...
[API 폴백][quality.backend] ...
```

## 백엔드 저장 확장

기존 저장 API `POST /owner/quality-inspections`는 점주 확정 등급/판정만 받았다. 앱에서 외부 DL 결과를 실제 저장할 수 있도록 아래 필드를 선택적으로 받도록 확장했다.

```json
{
  "model_grade": "C",
  "freshness_score": 55.35,
  "color_score": 52.47,
  "roundness_score": 80.65,
  "bruise_probability": 0.021,
  "model_decision": "HOLD",
  "model_version": "apple-single-image-top-middle-side-balanced-split-router-v1"
}
```

이 필드들이 있으면 백엔드는 저장 시 다시 mock 분석을 실행하지 않고 앱이 전달한 DL 결과를 저장한다.
