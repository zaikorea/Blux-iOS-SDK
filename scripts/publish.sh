#!/usr/bin/env bash
set -euo pipefail

PODSPEC_PATH="${PODSPEC_PATH:-BluxClient.podspec}"
TAG="${1:-${GITHUB_REF_NAME:-${TRAVIS_TAG:-}}}"

STG_RE='^[0-9]+\.[0-9]+\.[0-9]+-(internal|wip-[a-z]+)\.[1-9][0-9]*$'
PROD_RE='^[0-9]+\.[0-9]+\.[0-9]+(-((alpha|beta|rc)\.[1-9][0-9]*))?$'

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

if [[ -z "${TAG}" ]]; then
  fail "tag is empty (pass as arg or set GITHUB_REF_NAME/TRAVIS_TAG)"
fi

STAGE=""
if [[ "${TAG}" =~ ${STG_RE} ]]; then
  STAGE="stg"
elif [[ "${TAG}" =~ ${PROD_RE} ]]; then
  STAGE="prod"
else
  echo "ERROR: Invalid tag name: '${TAG}'" >&2
  echo "" >&2
  echo "Expected:" >&2
  echo "  stg:  x.y.z-internal.N, x.y.z-wip-name.N (name: [a-z]+, N: [1-9][0-9]*)" >&2
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

# 실제 배포는 여기서 하지 않습니다(추가 요청 시 반영).
# - CocoaPods trunk push
# - git push --tags
# - GitHub Release 생성
