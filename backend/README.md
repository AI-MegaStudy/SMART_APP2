# SMART APP 백엔드 실행 가이드

## 실행 환경

- Python 3.12 권장
- ML 모델은 `scikit-learn==1.8.0`으로 저장되어 있습니다.
- `scikit-learn==1.8.0`은 Python 3.11 이상에서만 설치됩니다.
- 이 레포는 Python `3.12.12` 기준으로 맞춰져 있습니다.

## 모델 파일 위치

ML 예측을 사용하려면 모델 파일이 아래 경로에 있어야 합니다.

```text
backend/app/ml_models/model.joblib
```

## macOS 설정

레포 루트(`/Users/.../smart_app`)에서 실행합니다.

### 1. Python 3.12 확인

```bash
python3.12 --version
```

`python3.12`가 없다면 Homebrew 또는 pyenv로 설치합니다.

Homebrew:

```bash
brew install python@3.12
```

pyenv:

```bash
pyenv install 3.12.12
pyenv local 3.12.12
```

### 2. 가상환경 생성 및 패키지 설치

```bash
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r backend/requirements.txt
```

### 3. 서버 실행

```bash
source .venv/bin/activate
uvicorn backend.app.main:app --reload
```

## Windows 설정

레포 루트(`C:\...\smart_app`)에서 실행합니다.

### 이미 설치된 venv로 서버 실행

PowerShell:

```powershell
cd C:\...\smart_app
.\.venv\Scripts\Activate.ps1
uvicorn backend.app.main:app --reload
```

cmd:

```bat
cd C:\...\smart_app
.\.venv\Scripts\activate.bat
uvicorn backend.app.main:app --reload
```

Git Bash:

```bash
cd /c/.../smart_app
source .venv/Scripts/activate
uvicorn backend.app.main:app --reload
```

PowerShell에서 activate가 막히면 아래 명령을 한 번만 실행한 뒤 다시 activate합니다.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 처음 설치할 때

Python 3.12 확인:

```powershell
py -3.12 --version
```

Python 3.12가 없다면 아래에서 설치합니다.

```text
https://www.python.org/downloads/
```

설치할 때 `Add python.exe to PATH` 옵션을 켜는 것을 권장합니다.

PowerShell:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r backend\requirements.txt
```

명령 프롬프트(cmd)를 쓰는 경우:

```bat
py -3.12 -m venv .venv
.\.venv\Scripts\activate.bat
python -m pip install --upgrade pip
python -m pip install -r backend\requirements.txt
```

## Flutter 앱 연결

백엔드를 로컬에서 실행한 뒤 Flutter 앱은 아래처럼 실행합니다.

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

iOS 시뮬레이터 빌드 예시:

```bash
flutter build ios --simulator --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## API 문서

서버 실행 후 브라우저에서 Swagger 문서를 확인할 수 있습니다.

```text
http://127.0.0.1:8000/docs
```

ML 예측 API 문서는 앱 레포에도 복사되어 있습니다.

```text
docs/api/ml_prediction_api.md
docs/api/frontend_integration_guide.md
docs/api/examples/ml_prediction_request.json
docs/api/examples/ml_prediction_response.json
```

## 자주 나는 문제

### `scikit-learn==1.8.0` 설치 실패

대부분 Python 버전이 낮아서 발생합니다. 아래처럼 Python 3.12인지 확인하세요.

```bash
python --version
```

Python 3.10 환경에서는 `scikit-learn==1.8.0`이 설치되지 않습니다.

### `model.joblib` 관련 경고

모델은 `scikit-learn==1.8.0` 기준으로 저장되었습니다. 다른 버전에서 로드하면 경고가 나거나 예측 결과가 달라질 수 있습니다.

### `.venv`를 커밋해야 하나요?

아니요. `.venv`는 로컬 개발 환경이며 `.gitignore`에 제외되어 있습니다. 다른 개발자는 이 문서대로 각자 생성하면 됩니다.
