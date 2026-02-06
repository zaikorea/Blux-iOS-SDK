#!/usr/bin/env bash
set -euo pipefail

PODSPEC_PATH="${PODSPEC_PATH:-BluxClient.podspec}"
TAG="${1:-${GITHUB_REF_NAME:-${TRAVIS_TAG:-}}}"

# stg 태그 형식 (Android와 동일):
# - x.y.z-internal.YYYYMMDD.COMMIT_HASH  (공용 테스트, GitHub Actions 자동 생성)
# - x.y.z-GITHUB_USERNAME.YYYYMMDD.COMMIT_HASH  (개인 테스트, 수동 생성)
#
# 참고:
# - YYYYMMDD: 8자리 날짜
# - COMMIT_HASH: 7~40자리 커밋 해시 (소문자 hex)
# - GITHUB_USERNAME: 소문자 영숫자와 하이픈 (internal 제외)
STG_INTERNAL_RE='^[0-9]+\.[0-9]+\.[0-9]+-internal\.[0-9]{8}\.[a-f0-9]{7,40}$'
STG_PERSONAL_RE='^[0-9]+\.[0-9]+\.[0-9]+-[a-z0-9][a-z0-9-]*\.[0-9]{8}\.[a-f0-9]{7,40}$'

# prod 태그 형식 (Android와 동일):
# - x.y.z
# - x.y.z-alpha.N
# - x.y.z-beta.N
# - x.y.z-rc.N
#
# 참고:
# - N은 1부터 시작, 선행 0 없음
PROD_RE='^[0-9]+\.[0-9]+\.[0-9]+(-((alpha|beta|rc)\.[1-9][0-9]*))?$'

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

is_stg_tag() {
  local v="$1"
  if [[ "${v}" =~ ${STG_INTERNAL_RE} ]]; then
    return 0
  fi
  # personal 태그: internal이 아닌 것만 허용
  if [[ "${v}" =~ ${STG_PERSONAL_RE} ]] && [[ ! "${v}" =~ -internal\. ]]; then
    return 0
  fi
  return 1
}

is_prod_tag() {
  local v="$1"
  [[ "${v}" =~ ${PROD_RE} ]]
}

if [[ -z "${TAG}" ]]; then
  fail "tag is empty (pass as arg or set GITHUB_REF_NAME/TRAVIS_TAG)"
fi

STAGE=""
if is_stg_tag "${TAG}"; then
  STAGE="stg"
elif is_prod_tag "${TAG}"; then
  STAGE="prod"
else
  echo "ERROR: Invalid tag name: '${TAG}'" >&2
  echo "" >&2
  echo "Expected:" >&2
  echo "  stg:  x.y.z-internal.YYYYMMDD.COMMIT_HASH, x.y.z-GITHUB_USERNAME.YYYYMMDD.COMMIT_HASH" >&2
  echo "  prod: x.y.z, x.y.z-alpha.N, x.y.z-beta.N, x.y.z-rc.N (N: [1-9][0-9]*)" >&2
  exit 1
fi

if [[ ! -f "${PODSPEC_PATH}" ]]; then
  fail "podspec not found: ${PODSPEC_PATH}"
fi

PODSPEC_VERSION="$(
  ruby -ne 'if $_ =~ /^\s*s\.version\s*=\s*[\"\x27]([^\"\x27]+)[\"\x27]/; puts $1; exit; end' "${PODSPEC_PATH}"
)"

if [[ -z "${PODSPEC_VERSION}" ]]; then
  fail "failed to parse s.version from ${PODSPEC_PATH}"
fi

if [[ "${PODSPEC_VERSION}" != "${TAG}" ]]; then
  echo "ERROR: podspec version mismatch" >&2
  echo "  tag:     ${TAG}" >&2
  echo "  podspec: ${PODSPEC_VERSION} (${PODSPEC_PATH})" >&2
  exit 1
fi

echo "OK: tag='${TAG}' stage='${STAGE}' podspec='${PODSPEC_VERSION}'"

# CocoaPods 배포
echo "Publishing to CocoaPods (stage=${STAGE})..."
BLUX_STAGE="${STAGE}" pod trunk push "${PODSPEC_PATH}" --allow-warnings

echo "Done!"
