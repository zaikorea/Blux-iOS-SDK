# 반복된 버그 패턴 / Race / Drain 정책

"이미 한 번 터졌던" 함정만 모은다. 같은 실수를 다시 만들지 않기 위해. 자세한 코드는 실제 파일 참고.

## 1. Credential 전환 drain 누락 (57af3ef, b3072e5)

signOut → 다른 user signIn / hybrid 앱 페이지 전환 재초기화 / stage 전환 후 재초기화 시, 이전 세션의 정적 상태가 새 세션에 새면서 attribution 오염 + 잘못된 인앱 표시.

[BluxClient.swift](../../BluxClient/Classes/BluxClient.swift) `initialize`(credential 변경 분기) + `signOut` **양쪽에 똑같이** 5종 drain:

```swift
EventHandlers.unhandledNotification = nil
EventService.clearPendingBatch()
InappService.dismissCurrentInApp()
InappService.clearInappQueue()
EventQueue.shared.clearPending()
```

credential 변경 시 추가: `isActivated = false`, `ColdStartNotificationManager.reset()`, `clientId` 달라졌으면 `deviceId` 폐기.

**금지**: 한쪽에만 추가. 새 정적 슬롯은 **양쪽 + `SdkStateGuard`까지 세 곳**에 등록.

## 2. customDeviceId 정규화 + 새 파라미터 4곳 동기화 (f657254, 60f9ca0)

빈 문자열/whitespace `customDeviceId`가 그대로 전송 → 모든 device가 같은 빈 식별자로 merge. 또한 [BluxWebSdkBridge.swift](../../BluxClient/Classes/BluxWebSdkBridge.swift) `handleInitialize`가 payload 추출 빠뜨려 silent drop.

**해결**: [DeviceService.swift](../../BluxClient/Classes/DeviceService.swift)에서 trim + 빈 문자열 → nil. 브릿지 핸들러는 payload 명시 추출.

**교훈 — 새 public 파라미터 추가 시 4곳 동기화**:
1. `BluxClient.swift` 본체
2. `BluxWebSdkBridge.handleInitialize` 등 브릿지 액션 핸들러
3. `Tests/BluxClientPublicAPITests/PublicAPISurfaceTests.swift` 시그니처 캡처
4. RN wrapper(Blux-RN-SDK), Flutter wrapper(Blux-Flutter-SDK) binding

빠뜨리면 Web SDK 브릿지만 죽고 wrapper 테스트로는 안 잡힌다.

## 3. 폴링 백오프 24h 이상은 그대로 유지 (91df32b)

[EventService.swift](../../BluxClient/Classes/EventService.swift) 실패 백오프:

```swift
let dayCapMs = 1000 * 60 * 60 * 24
let nextPollDelay = cachedPollDelayMs >= dayCapMs
    ? cachedPollDelayMs                              // 24h 이상이면 그대로 유지
    : min(cachedPollDelayMs * 2, dayCapMs)           // 24h까지만 2배
```

**왜 24h 이상은 cap 안 하나** — 서버가 의도적 disable 시 큰 값(`nextPollDelayMs=10일`)을 내려준다. 클라가 24h로 단축하면 서버 의도 깨짐.

**금지**: `min(*2, 24h)`로 단순화. ternary 분기를 그대로 유지.

## 4. push_opened dedup — 3중 가드 (fdeff7f)

WebView 브릿지 환경에서 페이지 전환마다 `initialize`가 재호출되며 같은 `launchOptions`가 재전달 → `push_opened` CRM 이벤트 N번 전송.

[ColdStartNotificationManager.swift](../../BluxClient/Classes/ColdStartNotificationManager.swift)의 세 가드가 함께:

1. **`hasProcessedLaunchOptions`** — launchOptions 재처리 차단. `setColdStartNotification`이 nil 받았을 땐 set 안 함 (initialize(nil, ...) → initialize(launchOptions, ...) 시퀀스 보존).
2. **`lastOpenedNotificationId`** — launchOptions 경로 + `BluxNotificationCenter.didReceive` 경로 모두 `trackOpen`을 거치며 동일 ID는 한 번만. **`reset()`이 이 슬롯은 비우지 않는다** (서버 발급 ObjectId라 credential 경계 넘어도 dedup 키로 유효).
3. **credential switch 시 launchOptions 차단** — `isInProcessCredentialSwitch ? nil : launchOptions`로 이전 credential 페이로드 재처리 방지.

**금지**: 셋 중 하나만 변경. 셋이 함께 굴러가야 안전.

## 5. HTTPClient completion 누락 + initialize 실패 롤백 (596b216, d91a680)

두 케이스 묶음 — 둘 다 "콜백/플래그 안 풀려서 큐 영구 막힘" 패턴.

- `createRequest`/`createRequestWithBody`가 nil 반환 시 `completion(nil, .invalidRequest)` 호출 필수. 안 하면 `EventQueue.addEvent`의 `done` 콜백 안 불려 다음 태스크 영구 대기.
- `DeviceService.initializeDevice` 실패 콜백에서 `isActivated = false` 롤백 필수. 안 하면 재시도 시 short-circuit return으로 영원히 초기화 못 함.

**금지**: 새 HTTP 메서드 / 비동기 진입점 추가 시 모든 실패 분기에서 콜백/플래그 풀어주는 코드 누락.

## 6. 인앱 동시성 가드 3종

[InappService.swift](../../BluxClient/Classes/InappService.swift)의 세 가드가 함께 굴러야 인앱 정상. 셋 중 하나라도 약화하면 동시 두 개 표시 / stale window leak / WebView crash.

1. **`processWebViewQueue`의 `dispatchPrecondition(.onQueue(.main))`** — 메인 스레드 강제. 멀티스레드에서 큐 head를 동시에 꺼내면 인앱 두 개 표시.
2. **`presentInappWebview`의 `didSwitchToBanner` 플래그** — HTML이 `resize` 여러 번 호출해도 모달→배너 swap을 한 번만. 없으면 stale `BannerWindow` leak.
3. **`handleInappResponse` → `DispatchQueue.main.async`** — `URLSession` 콜백은 백그라운드. WebView 생성/표시는 메인 강제.

## 7. notificationUrlOpenOptions 콜드 스타트 리셋 (54262d9)

[SdkConfig.swift](../../BluxClient/Classes/SdkConfig.swift)의 `notificationUrlOpenOptions`는 App Group `UserDefaults`에 raw Int로 영속. 콜드 스타트 후에도 호스트가 설정한 값 유지. 옵션 저장/복원 경로 변경 시 `BluxClientTests.testSetNotificationUrlOpenOptionsPersists`로 락-인.

**금지**: 메모리 변수만으로 단순화 — process kill → 콜드 스타트에서 기본값으로 리셋 회귀.
