# Semgrep Container 실행 스크립트 가이드

`sast-report/run-semgrep-container.sh` 스크립트는 Docker/Podman 환경에서 Semgrep을 실행하여 코드를 점검하고, 그 결과를 파일로 저장하는 도구입니다.

## 1. 사용법

```bash
./run-semgrep-container.sh [--output json|sarif|text] <source-code-root-or-git-url>
```

### 아규먼트 설명

- **`--output`**: (선택) 결과 리포트 형식을 지정합니다. (기본값: `json`)
  - `json`: 원본 데이터 포함 (기본값, jq 요약 출력 지원)
  - `sarif`: **(권장)** VSCode 등 IDE 및 보안 도구 연동 표준 포맷
  - `text`: 콘솔에서 읽을 수 있는 텍스트 포맷
- **`<source-code-root-or-git-url>`**: (필수) 점검 대상
  - **로컬 경로**: 점검할 소스 코드가 있는 디렉토리 경로 (예: `../apps/my-app`)
  - **Git URL**: GitHub 리포지토리 주소 (예: `https://github.com/org/repo.git`)
    - URL 입력 시, 현재 디렉토리에 `apps-under-check` 폴더를 생성하고 자동으로 clone 후 점검합니다.

## 2. 권장 워크플로우 (VS Code 활용)

Semgrep의 강력함을 100% 활용하는 **가장 추천하는 방법**은 **SARIF 포맷**으로 추출하여 VS Code에서 확인하는 것입니다.

### 단계 1: SARIF 포맷으로 점검 실행

> **참고사항**: <br>
> 실습을 위해 ../apps 폴더에서 `git clone https://github.com/juice-shop/juice-shop.git` 해둔 상태이다.
> 실제 사용 시에는 점검할 app의 소스 코드 경로를 입력한다.

```bash
# 예시: 로컬 프로젝트 점검
./run-semgrep-container.sh --output sarif ../apps/juice-shop
```

실행이 완료되면 현재 디렉토리에 `semgrep_result_{앱이름}.sarif` 파일이 생성됩니다.

### 단계 2: VS Code 확장 프로그램 설치

VS Code 마켓플레이스에서 **"SARIF Viewer"** (Microsoft 제공) 확장을 설치합니다.

- [SARIF Viewer for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=MS-SarifVSCode.sarif-viewer)

### 단계 3: 결과 파일 열기

1. VS Code에서 생성된 `.sarif` 파일을 엽니다.
2. **SARIF Viewer**가 자동으로 로드되며, **"SARIF Results"** 패널에 취약점 목록이 표시됩니다.
3. 목록을 클릭하면 해당 코드 위치로 바로 이동하며 상세 설명과 수정 가이드를 볼 수 있습니다.

![SARIF Viewer Example](https://github.com/microsoft/sarif-vscode-extension/raw/main/images/sarif-viewer-screenshot.png) *(참고용 이미지)*

## 3. 실행 예시

### 3.1. 로컬 소스 코드 점검 (기본 JSON)

```bash
./run-semgrep-container.sh ../apps/backend-api
# 결과: ./semgrep_result_backend-api.json 생성 (jq 설치 시 요약 출력)
```

### 3.2. GitHub 리포지토리 점검 (Text 포맷)

```bash
./run-semgrep-container.sh --output text https://github.com/juice-shop/juice-shop.git
# 결과: ./semgrep_result_juice-shop.txt 생성
```

### 3.3. GitHub 리포지토리 점검 (SARIF 포맷 - 권장)

```bash
./run-semgrep-container.sh --output sarif https://github.com/juice-shop/juice-shop.git
# 결과: ./semgrep_result_juice-shop.sarif 생성 -> VSCode에서 열기
```
