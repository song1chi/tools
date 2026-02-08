#!/bin/bash

# 기본 출력 형식 설정
OUTPUT_FORMAT="json"
INPUT_ARG=""

# 인자 파싱
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        *)
            INPUT_ARG="$1"
            shift
            ;;
    esac
done

# 인자 확인
if [ -z "$INPUT_ARG" ]; then
    echo "Usage: $0 [--output json|sarif|text] <source-code-root-or-git-url>"
    exit 1
fi

# 출력 포맷에 따른 플래그 및 확장자 설정
case "$OUTPUT_FORMAT" in
    json)
        OUTPUT_FLAG="--json"
        EXT="json"
        ;;
    sarif)
        OUTPUT_FLAG="--sarif"
        EXT="sarif"
        ;;
    text)
        OUTPUT_FLAG="--text"
        EXT="txt"
        ;;
    *)
        echo "❌ Error: Unsupported output format '$OUTPUT_FORMAT'. Use json, sarif, or text."
        exit 1
        ;;
esac

# jq 설치 확인
HAS_JQ=false
if command -v jq &> /dev/null; then
    HAS_JQ=true
else
    # JSON 형식일 때만 경고
    if [ "$OUTPUT_FORMAT" == "json" ]; then
        echo "⚠️  Warning: 'jq' tool is not installed."
        echo "    Summary output will be disabled."
    fi
fi

# GitHub URL인지 확인 (http/https 또는 git@ 프로토콜)
if [[ "$INPUT_ARG" =~ ^https?:// ]] || [[ "$INPUT_ARG" =~ ^git@ ]]; then
    # 1. 대상 디렉토리 설정
    APPS_DIR="./apps-under-check"
    mkdir -p "$APPS_DIR"
    
    # 2. 리포지토리 이름 추출 및 클론 경로 설정
    REPO_NAME=$(basename "$INPUT_ARG" .git)
    TARGET_DIR="$(realpath "$APPS_DIR")/$REPO_NAME"
    APP_NAME="$REPO_NAME"
    
    echo "⬇️ GitHub Repository Detected: $INPUT_ARG"
    echo "📂 Target Directory: $TARGET_DIR"

    # 3. Git Clone 수행
    if [ -d "$TARGET_DIR" ]; then
        echo "⚠️  Directory already exists. Skipping git clone..."
    else
        echo "🚀 Cloning repository..."
        git clone "$INPUT_ARG" "$TARGET_DIR"
        if [ $? -ne 0 ]; then
            echo "❌ Git clone failed."
            exit 1
        fi
    fi
else
    # 4. 로컬 경로일 경우
    if [ ! -d "$INPUT_ARG" ]; then
        echo "❌ Error: Directory '$INPUT_ARG' not found."
        exit 1
    fi
    TARGET_DIR=$(realpath "$INPUT_ARG")
    APP_NAME=$(basename "$TARGET_DIR")
fi

# 결과 보고서 파일명 설정
CURRENT_DIR=$(pwd)
REPORT_FILE="$CURRENT_DIR/semgrep_result_${APP_NAME}.$EXT"

echo "Running Semgrep on: $TARGET_DIR"
echo "Format: $OUTPUT_FORMAT"
echo "Output will be saved to: $REPORT_FILE"

# Podman 실행
# -v "$TARGET_DIR:/src": 대상 디렉토리를 컨테이너 내부 /src로 마운트
# -v "$CURRENT_DIR:/output": 현재 디렉토리를 컨테이너 내부 /output으로 마운트
podman run --rm -v "$TARGET_DIR:/src" -v "$CURRENT_DIR:/output" returntocorp/semgrep \
  semgrep scan --config=auto $OUTPUT_FLAG --output "/output/semgrep_result_${APP_NAME}.$EXT"


echo "---------------------------------------------------"
echo "✅ 점검 완료"
echo "📄 결과 보고서 위치: $REPORT_FILE"
echo "---------------------------------------------------"

# 결과 요약 출력 (JSON 형식이고 jq가 설치된 경우에만)
if [ "$OUTPUT_FORMAT" == "json" ] && [ "$HAS_JQ" = true ]; then
    echo "📊 결과 요약:"
    jq -r '.results[] | "[\(.check_id)] \(.path):\(.start.line) - \(.extra.message)"' "$REPORT_FILE" 2>/dev/null | head -n 20
    echo "... (전체 내용은 파일 참조)"
elif [ "$OUTPUT_FORMAT" == "json" ]; then
    echo "⚠️ 'jq'가 설치되어 있지 않아 요약을 출력할 수 없습니다."
    echo "   파일 내용을 직접 확인하세요: cat $REPORT_FILE"
else
    echo "ℹ️  요약 출력은 JSON 형식에서만 지원됩니다."
    echo "   파일 내용을 확인하세요: cat $REPORT_FILE"
fi
