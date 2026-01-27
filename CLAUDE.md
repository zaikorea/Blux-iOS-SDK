# Blux iOS SDK

iOS용 행동 분석 및 인앱 메시징 SDK

## 프로젝트 구조

```text
BluxClient/Classes/     # SDK 소스 코드
├── BluxClient.swift    # 메인 API 파사드
├── services/           # 핵심 서비스 (Event, Inapp, Device, HTTP)
├── events/             # 이벤트 타입들 (Order, Cart, PageView 등)
├── request/            # API 요청/응답 모델
├── views/              # WebView, BannerWindow 등 UI 컴포넌트
├── notification/       # 푸시 알림 관련
└── utilities/          # Logger, Validator, 유틸리티

Example/                # CocoaPods 예제 앱
ExampleSPM/             # Swift Package Manager 예제 앱
```

## 빌드 시스템

- **CocoaPods**: `BluxClient.podspec` (주요 배포)
- **SPM**: `Package.swift`
- **최소 지원**: iOS 13.0+, Swift 5.0+

## 개발 워크플로우

### Example 앱 빌드 (CocoaPods)

```bash
cd Example
pod install
open BluxExample.xcworkspace
```

### SPM 예제

```bash
cd ExampleSPM
open BluxExampleSPM.xcodeproj
```

### SDK 배포

1. `BluxClient.podspec`에서 버전 업데이트
2. `Package.swift`에서 버전 태그 확인
3. 태그 생성: `git tag X.Y.Z && git push origin X.Y.Z`

## 주요 컴포넌트

| 파일                  | 역할                                     |
| --------------------- | ---------------------------------------- |
| `BluxClient.swift`    | SDK 초기화, 사용자 인증, 이벤트 전송 API |
| `EventService.swift`  | 이벤트 배칭(100ms), 폴링, 전송           |
| `InappService.swift`  | 인앱 메시지 표시 (모달/배너/팝업)        |
| `HTTPClient.swift`    | API 통신 (PROD/STG/DEV/LOCAL)            |
| `DeviceService.swift` | 디바이스 정보, 푸시 토큰 관리            |

## 커밋 컨벤션

```text
feat: 새 기능
fix: 버그 수정
refactor: 리팩토링
build: 빌드/배포 관련
feat(example): 예제 앱 관련
```
