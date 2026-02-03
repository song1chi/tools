# `trivy-*.sh` 사용 방법

이 문서는 여러 개의 Docker 이미지를 대상으로 [trivy](https://trivy.dev) 스캔을 일괄 수행하고, 결과를 HTML 등의 보고서로 저장하는 `trivy-*.sh` 스크립트의 사용법을 설명합니다.

## 1. 사전 준비 사항 (Prerequisites)

이 스크립트를 실행하기 위해 다음 항목들이 준비되어 있어야 합니다.

* **Docker:** 호스트 머신에 Docker가 설치되어 있고 실행 중이어야 합니다.
* **Trivy 이미지:** Docker Hub에서 Trivy 이미지를 미리 받아두는 것을 권장합니다.
```bash
docker pull aquasec/trivy
```


* **커스텀 템플릿 (선택 사항):** 라이선스 스캔을 수행할 경우, 동일한 디렉토리에 `license.tpl` 파일이 존재해야 합니다.

## 2. 디렉토리 구조

스크립트 실행 전, 파일 구성은 아래와 같아야 합니다.

```text
.
├── trivy-license.sh     # 실행 스크립트 - license-long.html, license-short.html 생성
├── trivy-sbom.sh        # 실행 스크립트 - cyclonedx 및 spdx 형식의 SBOM 파일 생성(json)
├── trivy-vlun.sh        # 실행 스크립트 - 취약점 정보 파일 생성 ( vuln.html)
|                        # (공백 줄)
├── scan_list.txt        # 스캔할 이미지 목록 (사용자가 생성)
├── license.tpl          # 라이선스 리포트용 템플릿 (라이선스 스캔 시 필수)
└── trivy_reports/       # (자동 생성됨) 결과 보고서가 저장될 폴더

```

## 3. 설정 방법

### 3-1. 이미지 목록 작성 (`scan_list.txt`)

`scan_list.txt` 파일을 생성하고 스캔할 도커 이미지 이름을 한 줄에 하나씩 입력합니다.

```text
# 예시: scan_list.txt
nginx:latest
python:3.9-alpine
bkimminich/juice-shop:v12.0.0
# 주석 처리는 #을 사용하면 무시됩니다.

```
다음 명령으로 생성할 수도 있습니다.

```bash
docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>" > scan_list.txt
```

### 3-2. 스캔 모드 선택 (스크립트 수정)

`trivy_batch.sh` 파일을 열어 원하는 스캔 모드(취약점 vs 라이선스)에 따라 주석(`#`)을 해제하거나 설정합니다.

**옵션 1: 보안 취약점(Vulnerability) 스캔 (기본값)**

```bash
# [Option 1] 부분이 활성화되어 있어야 합니다.
sudo docker run --rm \
    ...
    aquasec/trivy image \
    --format template \
    --template "@contrib/html.tpl" \
    ...

```

**옵션 2: 라이선스(License) 스캔**

```bash
# [Option 1] 전체를 주석(#) 처리하고, [Option 2]의 주석을 해제합니다.
# 또한 --template "@/src/license.tpl" 경로가 올바른지 확인하세요.

sudo docker run --rm \
    ...
    --scanners license \
    --format template \
    --template "@/src/license.tpl" \
    ...

```

## 4. 실행 방법

터미널에서 스크립트가 있는 디렉토리로 이동한 후 다음 명령을 실행합니다.

1. **실행 권한 부여 (최초 1회)**
```bash
chmod +x trivy_batch.sh

```


2. **스크립트 실행**
```bash
./trivy_batch.sh

```


*(Docker 실행을 위해 `sudo` 권한이 필요할 수 있으며, 비밀번호 입력을 요구할 수 있습니다.)*

## 5. 결과 확인

스크립트 실행이 완료되면 `trivy_reports` 폴더 안에 HTML 파일들이 생성됩니다.

* **파일명 규칙:** 이미지 이름의 `/`와 `:` 문자가 파일 시스템 호환 문자로 자동 변환됩니다.
* `nginx:latest` → `nginx__latest.html`
* `bkimminich/juice-shop:v12.0.0` → `bkimminich_juice-shop__v12.0.0.html`



## 6. 트러블슈팅 (FAQ)

**Q. `template: ... can't evaluate field ...` 오류가 발생합니다.**

* **원인:** 라이선스 스캔 시 `license.tpl` 파일의 문법이 Trivy 버전이나 데이터 구조와 맞지 않을 때 발생합니다.
* **해결:** `license.tpl` 파일 내에 존재하지 않는 필드(예: `.Version`)를 참조하고 있는지 확인하고 제거하세요.

**Q. `scan_list.txt 파일을 찾을 수 없습니다.` 오류가 뜹니다.**

* 스크립트와 같은 디렉토리에 `scan_list.txt` 파일이 정확한 이름으로 존재하는지 확인하세요.

**Q. 매번 DB를 새로 다운로드합니다.**

* 스크립트 내에 `-v "$CACHE_DIR":/root/.cache/trivy` 옵션이 설정되어 있는지 확인하세요. 호스트의 캐시 폴더 권한 문제일 수도 있습니다.
