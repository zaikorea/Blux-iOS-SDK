#!/bin/bash
#
# 개인 테스트용 태그 생성 및 CocoaPods 배포 스크립트
#
# 사용법:
#   ./scripts/release-personal.sh [GITHUB_USERNAME]
#
# 예시:
#   ./scripts/release-personal.sh           # GitHub username 자동 감지
#   ./scripts/release-personal.sh johndoe   # username 직접 지정
#
# 생성되는 태그: (BASE_VERSION patch+1)-USERNAME.YYYYMMDD.COMMIT_HASH
# 예: BASE_VERSION=0.6.11 → 0.6.12-johndoe.20260225.abc1234
#
# 버전 SSoT: SdkConfig.swift의 sdkVersion (최신 프로덕션 버전)
# podspec은 SdkConfig.swift에서 버전을 읽으므로, SdkConfig.swift만 변경하면 됨

set -euo pipefail
IFS=$'\n\t'

START_SECONDS=$SECONDS

SDK_CONFIG_PATH="${SDK_CONFIG_PATH:-BluxClient/Classes/SdkConfig.swift}"
PODSPEC_PATH="${PODSPEC_PATH:-BluxClient.podspec}"
GITHUB_USERNAME="${1:-}"

die() {
    echo "Error: $*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

# CocoaPods trunk: .netrc에 저장된 토큰을 COCOAPODS_TRUNK_TOKEN으로 로드 (한 번만 인증하면 재실행 시 재인증 불필요)
load_trunk_token() {
    if [ -n "${COCOAPODS_TRUNK_TOKEN:-}" ]; then
        return 0
    fi
    local netrc="${HOME}/.netrc"
    if [ -f "$netrc" ] && grep -q "trunk.cocoapods.org" "$netrc" 2>/dev/null; then
        local token
        token=$(awk '/machine trunk.cocoapods.org/ { found=1; next } found && /^[[:space:]]*password[[:space:]]+/ { print $2; exit } found && /^[[:space:]]*machine[[:space:]]+/ { exit }' "$netrc" 2>/dev/null)
        if [ -n "$token" ]; then
            export COCOAPODS_TRUNK_TOKEN="$token"
        fi
    fi
}

parse_sdk_version() {
    ruby -ne 'if $_ =~ /sdkVersion\s*=\s*"([^"]+)"/; puts $1; exit; end' "$1"
}

# publish.sh와 동일한 태그 형식 검증 (stg personal만 허용)
STG_PERSONAL_RE='^[0-9]+\.[0-9]+\.[0-9]+-[a-z0-9][a-z0-9-]*\.[0-9]{8}\.[a-f0-9]{7,40}$'

validate_tag() {
    local v="$1"
    if [[ "${v}" =~ ${STG_PERSONAL_RE} ]] && [[ ! "${v}" =~ -internal\. ]]; then
        return 0
    fi
    die "Invalid personal tag format: '${v}' (expected: x.y.z-USERNAME.YYYYMMDD.COMMIT_HASH)"
}

require_cmd git
require_cmd ruby
require_cmd pod

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "This script must be run inside a git repository."
fi

if ! git remote get-url origin >/dev/null 2>&1; then
    die "Remote 'origin' not found. Configure origin first."
fi

if [ ! -f "$SDK_CONFIG_PATH" ]; then
    die "SdkConfig not found: $SDK_CONFIG_PATH"
fi

if [ ! -f "$PODSPEC_PATH" ]; then
    die "Podspec not found: $PODSPEC_PATH"
fi

# SdkConfig.swift에서 BASE_VERSION 읽기 (SSoT)
BASE_VERSION="$(parse_sdk_version "$SDK_CONFIG_PATH")"
if [ -z "$BASE_VERSION" ]; then
    die "Failed to parse sdkVersion from $SDK_CONFIG_PATH"
fi

NEXT_BASE_VERSION=$(echo "$BASE_VERSION" | awk -F. 'BEGIN{OFS="."} {$NF=$NF+1; print $0}')

# GitHub username 자동 감지 (gh CLI 사용) 또는 git config에서 추출
if [ -z "$GITHUB_USERNAME" ]; then
    if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
        GITHUB_USERNAME=$(gh api user -q '.login' 2>/dev/null | tr '[:upper:]' '[:lower:]')
    fi

    if [ -z "$GITHUB_USERNAME" ]; then
        GITHUB_USERNAME=$(git config user.name 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
    fi
fi

if [ -z "$GITHUB_USERNAME" ]; then
    echo "Error: Could not detect GitHub username. Please provide it as argument." >&2
    echo "Example: $0 johndoe" >&2
    exit 1
fi

DATE=$(date +%Y%m%d)
COMMIT_HASH=$(git rev-parse --short HEAD)

TAG="${NEXT_BASE_VERSION}-${GITHUB_USERNAME}.${DATE}.${COMMIT_HASH}"

validate_tag "$TAG"

echo "=== Blux iOS SDK: Personal Release ==="
echo "BASE_VERSION : $BASE_VERSION (from $SDK_CONFIG_PATH)"
echo "Tag          : $TAG"
echo ""

# dirty check
ALLOW_DIRTY="${ALLOW_DIRTY:-0}"
if [ "$ALLOW_DIRTY" != "1" ]; then
    if ! git diff --quiet || ! git diff --cached --quiet; then
        die "Working tree is dirty. Commit/stash changes or run with ALLOW_DIRTY=1."
    fi
fi

# 태그 생성 (이미 있으면 재사용)
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null 2>&1; then
    echo "Tag already exists locally: $TAG (reusing)"
else
    git tag "$TAG"
    echo "Created tag: $TAG"
fi

# 태그 푸시
echo "Pushing tag to origin..."
git push origin "$TAG"

echo ""
echo "Waiting for remote to recognize the tag..."

REMOTE_WAIT_MAX="${REMOTE_WAIT_MAX:-60}"
REMOTE_WAITED=0
REMOTE_INTERVAL="${REMOTE_INTERVAL:-2}"
while [ "$REMOTE_WAITED" -lt "$REMOTE_WAIT_MAX" ]; do
    if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
        echo "Remote tag is visible: $TAG"
        break
    fi
    echo "Remote tag not visible yet... (${REMOTE_WAITED}s)"
    sleep "$REMOTE_INTERVAL"
    REMOTE_WAITED=$((REMOTE_WAITED + REMOTE_INTERVAL))
done

if ! git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
    die "Remote did not expose tag '$TAG' within ${REMOTE_WAIT_MAX}s. Please retry later."
fi

# SdkConfig.swift를 풀 태그 버전으로 임시 변경 → EXIT 시 원복
# podspec은 SdkConfig.swift에서 버전을 읽으므로 별도 변경 불필요
ORIGINAL_SDK_CONFIG="$(cat "$SDK_CONFIG_PATH")"

cleanup() {
    printf "%s" "$ORIGINAL_SDK_CONFIG" > "$SDK_CONFIG_PATH"
    echo "Reverted SdkConfig.swift to ${BASE_VERSION}"
}
trap cleanup EXIT

ruby -pi -e "gsub(/^(\s*static var sdkVersion\s*=\s*)\".+\"/, %Q(\\\\1\"${TAG}\"))" "$SDK_CONFIG_PATH"

UPDATED_VERSION="$(parse_sdk_version "$SDK_CONFIG_PATH")"
if [ "$UPDATED_VERSION" != "$TAG" ]; then
    die "Failed to update sdkVersion. Expected: $TAG, Got: $UPDATED_VERSION"
fi

echo "Temporarily updated sdkVersion: ${BASE_VERSION} → ${TAG}"
echo ""

# pod lib lint: podspec 유효성 + 빌드 검증 (CI의 lint 단계에 대응)
SKIP_LINT="${SKIP_LINT:-0}"
if [ "$SKIP_LINT" != "1" ]; then
    echo "Running pod lib lint (stage=stg)..."
    BLUX_STAGE=stg pod lib lint "$PODSPEC_PATH" --allow-warnings --skip-tests
    echo "Lint OK."
    echo ""
fi

# CocoaPods 배포: .netrc 토큰 사용으로 매번 재인증 방지
load_trunk_token
trunk_exit=0
trunk_err=$(pod trunk me 2>&1) || trunk_exit=$?
if [ "$trunk_exit" -ne 0 ]; then
    echo "$trunk_err" >&2
    echo "" >&2
    echo "CocoaPods trunk 인증이 필요하거나 만료되었습니다." >&2
    echo "한 번만 아래를 실행한 뒤 메일의 인증 링크를 클릭하세요:" >&2
    echo "  pod trunk register development@zaikorea.org 'Blux'" >&2
    echo "인증 후 이 스크립트를 다시 실행하면 됩니다." >&2
    exit 1
fi
echo "Publishing to CocoaPods (stage=stg)..."
BLUX_STAGE=stg pod trunk push "$PODSPEC_PATH" --allow-warnings

echo ""
echo "=== Done! ==="
echo "Tag    : $TAG"
echo "Stage  : stg"
echo "Elapsed: $((SECONDS - START_SECONDS))s"
