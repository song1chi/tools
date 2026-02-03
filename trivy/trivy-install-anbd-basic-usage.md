# [도구 가이드] Trivy 설치 및 사용 방법 (Docker Image)

**Trivy**는 Aqua Security에서 개발한 올인원(All-in-one) 보안 스캐너입니다. 이 문서는 **Docker Image**를 사용하여 설치하고, 다른 Docker 이미지 및 로컬 소스 코드(Javascript 등)의 취약점을 스캔하는 방법에 대해 설명합니다.

> 아래에서 ```knqyf263/vuln-image:1.2.3```는 trivy 테스트용 이미지 입니다.
> 의도적으로 많은 취약점이 포함되어 있습니다.


---

## 1. 개요
*   **용도**: 컨테이너 이미지 및 파일시스템 취약점 스캔, SBOM 생성 및 검증
*   **실행 방식**: 별도의 바이너리 설치 없이 Docker Container로 실행

## 2. 설치 방법 (Docker Image)
Docker가 설치된 환경에서 아래 명령어로 공식 이미지를 다운로드합니다.

```bash
docker pull aquasec/trivy:latest
```

## 3. 기본 사용법 (Basic Usage)
Trivy 실행 시 `docker run` 명령어를 사용합니다. 버전 확인 및 도움말을 통해 도구가 정상 동작하는지 확인할 수 있습니다.

```bash
# 버전 확인
docker run --rm aquasec/trivy:latest --version

# 도움말 확인
docker run --rm aquasec/trivy:latest --help
```

## 4. 취약점 스캔 (Vulnerability Scanning)

로컬 환경의 캐시나 파일을 사용하기 위해 **볼륨 마운트(-v)**가 필수적입니다.

### 4.1. 다른 Docker Image 취약점 스캔
원격 레지스트리(Docker Hub 등)에 있는 이미지나 로컬 데몬에 있는 이미지를 스캔합니다.

#### 기본 명령어 구조
```bash
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest image [이미지명]
```

*   `-v /var/run/docker.sock:/var/run/docker.sock`: 호스트의 Docker 데몬을 공유하여 로컬 이미지를 스캔할 수 있게 합니다.
*   `-v $HOME/.cache/trivy:/root/.cache/trivy`: 취약점 DB를 호스트에 캐싱하여 매번 다운로드하는 시간을 단축합니다.

#### 사용 예시 (취약한 이미지 스캔)
실습을 위해 다수의 취약점이 포함된 `knqyf263/vuln-image:1.2.3` 이미지를 스캔합니다.

```bash
# knqyf263/vuln-image:1.2.3 이미지 스캔
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest image knqyf263/vuln-image:1.2.3
```

### 4.2. 로컬 소스 코드 취약점 스캔 (Javascript 프로젝트)
로컬에 있는 프로젝트 소스 코드를 스캔합니다. Javascript 프로젝트(`package.json`, `package-lock.json`)의 의존성 취약점을 탐지할 때 유용합니다.

#### 기본 명령어 구조
```bash
docker run --rm \
    -v $PWD:/src \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest fs /src
```

*   `-v $PWD:/src`: 현재 디렉토리(소스 코드 위치)를 컨테이너 내부의 `/src`로 마운트합니다.
*   `fs /src`: 컨테이너 내부의 `/src` 경로(즉, 호스트의 현재 디렉토리)를 파일시스템 모드로 스캔합니다.

#### 사용 예시 (Javascript 프로젝트)
Javascript 프로젝트 루트 디렉토리에서 실행하세요.

```bash
# 1. 일반적인 취약점 스캔 (모든 취약점 출력)
docker run --rm \
    -v $PWD:/src \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest fs /src

# 2. 중요도(Severity) 필터링 (HIGH, CRITICAL만 출력)
docker run --rm \
    -v $PWD:/src \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest fs --severity HIGH,CRITICAL /src
```

> **참고**: Javascript 프로젝트 스캔 시 `package-lock.json` 또는 `yarn.lock` 파일이 존재해야 더 정확한 의존성 분석이 가능합니다.

## 5. SBOM 생성 (SBOM Generation)
이미지 또는 소스 코드에 대한 SBOM을 생성할 수 있습니다. 결과 파일을 호스트에 저장하기 위해 `-v $PWD:/src` 마운트가 필요합니다.

### 5.1. 로컬 소스 코드 → CycloneDX SBOM 생성
Javascript 프로젝트 등 소스 코드를 스캔하여 CycloneDX 포맷의 SBOM을 생성합니다.

```bash
docker run --rm \
    -v $PWD:/src \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest fs --format cyclonedx --output /src/sbom.json /src
```
*   `--output /src/sbom.json`: 컨테이너 내부 `/src` 경로에 파일을 생성하면, 호스트의 현재 디렉토리에 `sbom.json`으로 저장됩니다.

### 5.2. Docker Image → SPDX SBOM 생성
컨테이너 이미지를 스캔하여 SPDX 포맷의 SBOM을 생성합니다.

```bash
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:/src \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest image --format spdx-json --output /src/sbom.spdx.json knqyf263/vuln-image:1.2.3
```

## 6. SBOM 활용 (Scanning SBOM)
이미 생성된 SBOM 파일(`sbom.json` 등)의 취약점을 스캔할 수 있습니다. 이미지가 없어도 SBOM 파일만으로 취약점 점검이 가능합니다.

```bash
# 현재 디렉토리의 sbom.json 파일을 스캔
docker run --rm \
    -v $PWD:/src \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest sbom /src/sbom.json
```

## 7. 리포트 생성 (Report Generation)
취약점 점검 결과를 터미널 출력이 아닌 파일로 저장하여, 정식 보고서 형태로 활용할 수 있습니다.

### 7.1. JSON 리포트 (데이터 처리용)
결과를 JSON 포맷으로 저장하여 다른 시스템에서 파싱하거나 데이터를 가공할 때 사용합니다.

```bash
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:/src \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest image \
    --format json \
    --output /src/report.json \
    knqyf263/vuln-image:1.2.3
```

### 7.2. HTML 리포트 (사람이 보기 좋은 형식)
Trivy 내장 템플릿을 사용하여 브라우저에서 보기 좋은 HTML 보고서를 생성합니다. 제출용 또는 검토용으로 적합합니다.

```bash
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:/src \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest image \
    --format template \
    --template "@contrib/html.tpl" \
    --output /src/report.html \
    knqyf263/vuln-image:1.2.3
```

*   `--format template`: 템플릿 형식을 사용함을 명시
*   `--template "@contrib/html.tpl"`: Trivy에 내장된 기본 HTML 템플릿 사용

---

## 부록. 폐쇄망(Offline) 환경 점검 방법

인터넷이 연결되지 않은 폐쇄망(Air-gapped) 환경에서 Trivy를 사용하기 위해서는, **인터넷이 가능한 외부 PC**에서 먼저 취약점 DB를 다운로드하여 옮겨야 합니다.

### 단계 1: 외부 PC에서 취약점 DB 다운로드 (Online)
인터넷이 연결된 환경에서 `--download-db-only` 옵션을 사용하여 DB만 다운로드합니다. 이때 DB는 호스트의 `$HOME/.cache/trivy` 경로에 저장됩니다.

```bash
# 1. DB 다운로드 (DB 및 Java Index DB)
docker run --rm \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest image --download-db-only

# 2. 다운로드된 DB 파일 확인 및 압축 (예시)
ls -al $HOME/.cache/trivy
tar -czvf trivy-db.tar.gz -C $HOME/.cache/trivy .
```

*   생성된 `trivy-db.tar.gz` 파일을 USB 등의 매체를 통해 폐쇄망의 분석 PC로 이동합니다.

### 단계 2: 폐쇄망 PC에서 스캔 수행 (Offline)
폐쇄망 환경의 PC에 DB 파일을 위치시킨 후(압축 해제), `--offline-scan` 옵션으로 스캔을 수행합니다.

```bash
# 1. DB 압축 해제 (분석 PC의 $HOME/.cache/trivy 경로에)
mkdir -p $HOME/.cache/trivy
tar -xzvf trivy-db.tar.gz -C $HOME/.cache/trivy

# 2. 오프라인 모드로 스캔 수행
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $HOME/.cache/trivy:/root/.cache/trivy \
    aquasec/trivy:latest image \
    --offline-scan \
    knqyf263/vuln-image:1.2.3
```

*   `-v $HOME/.cache/trivy:/root/.cache/trivy`: 옮겨온 DB가 있는 호스트 경로를 컨테이너에 마운트합니다.
*   `--offline-scan`: DB 업데이트를 시도하지 않고, 로컬에 있는 DB 데이터만 사용하여 스캔합니다.
