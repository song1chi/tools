#!/bin/bash

# --- 설정 구간 ---
INPUT_FILE="scan_list.txt"       # 이미지 목록 파일
OUTPUT_DIR="./trivy_reports"     # 결과 저장될 폴더
CACHE_DIR="$HOME/.cache/trivy"   # Trivy 캐시 폴더
TEMPLATE_PATH="$PWD/license.tpl" # (라이선스 스캔 시) 템플릿 경로

# 결과 폴더가 없으면 생성
mkdir -p "$OUTPUT_DIR"

# 입력 파일 존재 확인
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE 파일을 찾을 수 없습니다."
    exit 1
fi

echo "=== Trivy 배치 스캔을 시작합니다 ==="

# 파일을 한 줄씩 읽으며 루프 실행
while IFS= read -r image || [ -n "$image" ]; do
    # 빈 줄이나 주석(#)은 건너뛰기
    [[ -z "$image" || "$image" =~ ^# ]] && continue

    echo "------------------------------------------------"
    echo "Scan Target: $image"

    # 이미지 이름에서 파일명에 쓸 수 없는 문자(/, :)를 밑줄(_)로 변경
    # 예: bkimminich/juice-shop:v12.0.0 -> bkimminich_juice-shop__v12.0.0.html
    SAFE_NAME=$(echo "$image" | sed 's|/|_|g' | sed 's|:|__|g')

    # --- Docker 실행 명령 ---
    # 필요에 따라 아래 옵션을 주석 해제/수정하여 사용하세요.
    
    # [Option 1] 일반 보안 취약점(Vulnerability) 스캔 (기본)
    REPORT_FILE="$OUTPUT_DIR/${SAFE_NAME}-license-long.html"
    sudo docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$CACHE_DIR":/root/.cache/trivy \
        -v "$PWD":/.opt \
        -v "$OUTPUT_DIR":/output \
        aquasec/trivy image \
	--scanners license \
        --format template \
        --template "@/.opt/license.tpl" \
        -o "/output/${SAFE_NAME}-license-long.html" \
        "$image"

    echo "Result saved: $REPORT_FILE"
    echo ""

    # [Option 1] 일반 보안 취약점(Vulnerability) 스캔 (기본)
    REPORT_FILE="$OUTPUT_DIR/${SAFE_NAME}-license-short.html"
    sudo docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$CACHE_DIR":/root/.cache/trivy \
        -v "$PWD":/.opt \
        -v "$OUTPUT_DIR":/output \
        aquasec/trivy image \
	--scanners license \
	--severity UNKNOWN,HIGH,CRITICAL \
        --format template \
        --template "@/.opt/license.tpl" \
        -o "/output/${SAFE_NAME}-license-short.html" \
        "$image"

    echo "Result saved: $REPORT_FILE"

done < "$INPUT_FILE"

echo "------------------------------------------------"
echo "=== 모든 작업이 완료되었습니다. ==="
echo "결과 폴더 확인: $OUTPUT_DIR"

