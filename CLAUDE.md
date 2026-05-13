# Blux iOS SDK

iOS용 행동 분석 / 인앱 메시징 / 푸시 SDK. Swift, CocoaPods + SPM. RN/Flutter wrapper SDK가 이 모듈을 그대로 import해 사용.

## 자주 쓰는 명령

```bash
cd Example && bundle exec pod install && open BluxExample.xcworkspace        # Example 앱
xcodebuild -scheme BluxClient -destination 'platform=iOS Simulator,name=iPhone 15' test   # 단위 테스트
BLUX_STAGE=stg bundle exec pod lib lint BluxClient.podspec --allow-warnings --skip-tests  # podspec lint
./scripts/release-personal.sh                                                # 개인 stg 배포
```

## 절대 어기지 말 것

- **버전 SSoT는 [`BluxClient/Classes/SdkConfig.swift`](BluxClient/Classes/SdkConfig.swift)의 `sdkVersion` 한 군데.** podspec / 워크플로우 / 배포 스크립트 모두 정규식으로 이 값을 읽음. 수동 git tag 만들지 말고 release 워크플로우에 위임 — release-prod는 `release/x.y.z` 브랜치 + workflow_dispatch, release-internal은 main push 자동, personal은 [`scripts/release-personal.sh`](scripts/release-personal.sh). **단 prod만 SSoT 일관성 보장** (sed → commit → tag). **internal/personal은 태그 push 후 `SdkConfig.swift`를 임시 수정만** (커밋 안 함) — git tag가 가리키는 source의 `sdkVersion`은 base 그대로이고 podspec `spec.version`만 풀 태그. 따라서 internal/personal SDK가 송출하는 `X-BLUX-SDK-INFO` 헤더는 base 버전이며 풀 버전 식별은 `Podfile.lock` / 태그명으로 해야 한다.

- **`Stage.setStage`는 `defaultStage == .prod`일 때만 차단된다.** "prod 빌드 = 차단"이 아님. [Stage.swift](BluxClient/Classes/Stage.swift)는 **Info.plist `BluxStage` → 컴파일 플래그(`BLUX_LOCAL/DEV/STG`) → 기본 `.prod`** 순으로 결정. 호스트가 Info.plist에 `BluxStage=stg`를 박으면 prod 분기 빌드라도 런타임 stage 전환이 가능. **prod 출시 빌드는 Info.plist에 `BluxStage` 키 없거나 명시적으로 `prod`이어야** 가드 의도대로 동작.

- **세션 경계 청소는 [`initialize`](BluxClient/Classes/BluxClient.swift)(credential 변경) + `signOut` 양쪽에 똑같이.** 한쪽만 수정하면 회귀. 5종 정적 슬롯(`EventHandlers.unhandledNotification` / `EventService.clearPendingBatch` / `InappService.dismissCurrentInApp` / `InappService.clearInappQueue` / `EventQueue.shared.clearPending`) + credential 변경 시 `isActivated=false` / `ColdStartNotificationManager.reset()`. 새 정적 슬롯 추가 시 양쪽 + [`SdkStateGuard`](Tests/BluxClientTests/support/SdkStateGuard.swift)까지 세 곳에 등록. 자세한 사고 이력은 [.claude/docs/pitfalls.md #1](.claude/docs/pitfalls.md#1-credential-전환-drain-누락-57af3ef-b3072e5).

- **외부 의존성 추가 금지.** `URLSession` + `Codable` + `WKWebView` 표준만. 호스트 앱에 dynamic framework로 들어가므로 의존성 충돌이 호스트 빌드를 깨뜨림.

- **`BluxClient`에 새 public 파라미터 추가 시 4곳 동기화.** (1) [`BluxClient.swift`](BluxClient/Classes/BluxClient.swift) 본체, (2) [`BluxWebSdkBridge.handleInitialize`](BluxClient/Classes/BluxWebSdkBridge.swift) 등 브릿지 액션 핸들러, (3) [`Tests/BluxClientPublicAPITests/PublicAPISurfaceTests.swift`](Tests/BluxClientPublicAPITests/PublicAPISurfaceTests.swift) 시그니처 캡처, (4) RN(Blux-RN-SDK) / Flutter(Blux-Flutter-SDK) wrapper binding. 빠뜨리면 Web SDK 브릿지 / wrapper만 silent하게 죽음. 자세한 사고 이력은 [.claude/docs/pitfalls.md #2](.claude/docs/pitfalls.md#2-customdeviceid-정규화--새-파라미터-4곳-동기화-f657254-60f9ca0).

## 호스트 앱 통합 (수동 작업)

iOS는 자동 등록 메커니즘이 없어 호스트 앱이 명시적으로 다음을 해야 한다. 살아있는 reference: [Example/](Example/).

1. **App Group capability** — 호스트 + NSE 양쪽 entitlements + 양쪽 Info.plist `BluxAppGroupName` 키. 미설정 시 NSE에서 `bluxClientId`/`bluxAPIKey` 못 봐서 `trackReceived` 실패.
2. **APNs entitlement** + Info.plist `UIBackgroundModes = [remote-notification]`.
3. **NSE 타겟** + `BluxNotificationServiceExtensionHelper.shared.didReceive` 위임 ([Example/BluxNotificationServiceExtension/NotificationService.swift](Example/BluxNotificationServiceExtension/NotificationService.swift)).
4. **AppDelegate 위임 4개 메서드** — `didFinishLaunchingWithOptions`에서 `BluxClient.initialize` + `UNUserNotificationCenter.current().delegate = self`, `didRegisterForRemoteNotificationsWithDeviceToken` → `BluxAppDelegate.shared`, `userNotificationCenter(_:didReceive:)` / `(_:willPresent:)` → `BluxNotificationCenter.shared`. swizzling은 의도적으로 안 씀 — 호스트가 자체 delegate 가질 때 chain 깨지는 사고 이력. ([Example/BluxExample/AppDelegate.swift](Example/BluxExample/AppDelegate.swift))
5. **NSE Info.plist `BluxStage`** — non-prod 분기 빌드 사용 시 NSE Info.plist에도 main 앱과 같은 값 명시 ([Example/BluxNotificationServiceExtension/Info.plist](Example/BluxNotificationServiceExtension/Info.plist)). NSE는 별도 process라 main app의 `Stage.setStage` 호출이 안 보이고, Info.plist 없으면 NSE 내부 `Stage.current`가 default `.prod`로 fallback해 NSE의 `trackReceived` HTTP가 prod API로 향한다.

## 자주 깨지는 곳 (운영)

| 증상 | 원인/해결 |
|------|----------|
| `Podfile.lock is stale` (CI) | 로컬에서 `cd Example && bundle exec pod install --repo-update` 후 lock 커밋 |
| `Unexpected CocoaPods version` | 시스템 `pod`이 1.16.2 아님. 항상 `bundle exec pod ...` 사용 |
| `xcodebuild -downloadPlatform iOS` 실패 | macos-26 runner에 iOS platform 매번 다운로드 필요. 30초 간격 3회 자동 재시도 (8aa3f6c). 서버 일시 장애면 워크플로우 재실행 |
| `No available iPhone Simulator found` | runner 변경. CI가 `xcrun simctl list devices available -j \| jq`로 동적 선택. 셀렉터 점검 |
| Wrapper SDK 빌드 깨짐 | public 시그니처 변경. `PublicAPISurfaceTests` 동기화 + RN/Flutter 측 release 필요 |
| CocoaPods trunk 토큰 만료 | `pod trunk register development@zaikorea.org 'Blux'` → 메일 인증 → 재실행. 로컬은 `~/.netrc`에서 자동 로드 |

## 커밋 prefix

```text
feat / fix / refactor / build / ci / test / chore / docs / feat(example)
```

이슈/PR 번호는 끝에 ` (#NN)`. PR 템플릿은 [.github/pull_request_template.md](.github/pull_request_template.md). CODEOWNERS: `@geongun20 @silvermanseoul @NoMoreViolence`.

## 추가 컨텍스트

- **반복 발생한 버그 패턴 / race / drain 정책** → [.claude/docs/pitfalls.md](.claude/docs/pitfalls.md)
- **Stage / 워크플로우 / 빌드 도구 버전** → [.github/workflows/](.github/workflows/), [BluxClient.podspec](BluxClient.podspec), [Gemfile](Gemfile)
- **호스트 통합 reference** → [Example/](Example/)

코드 / git log / `.github/` / `Example/`을 직접 보면 알 수 있는 정보는 docs에 두지 않는다. 위 4곳에 없는 합의된 invariant와 사고 이력만 보존.
