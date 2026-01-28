//
//  EventService.swift
//  BluxClient
//
//  Created by Tommy on 5/22/24.
//
import Foundation
#if canImport(UIKit)
    import UIKit
#endif

class EventWrapper: Codable {
    let events: [Event]
    let device_id: String

    init(events: [Event], deviceId: String) {
        self.events = events
        device_id = deviceId
    }
}

@available(iOSApplicationExtension, unavailable)
class EventService {
    // 이벤트 배치 (100ms 동안 모아서 한 번에 전송)
    private static let batchWindowSeconds: TimeInterval = 0.1
    private static let batchQueue = DispatchQueue(label: "eventService.batchQueue")
    private static var pendingEvents: [Event] = []
    private static var batchWorkItem: DispatchWorkItem?
    private static var lifecycleObserverInstalled: Bool = false

    // 폴링
    private static var pollTimer: Timer?
    private static var cachedPollDelayMs: Int = 10000

    static func sendEvent(_ data: [Event]) {
        ensureLifecycleObserver()

        // 폴링(빈 이벤트)은 즉시 전송
        if data.isEmpty {
            performRequest(events: [])
            return
        }

        // 100ms 동안 이벤트를 모았다가 한 번에 전송
        batchQueue.async {
            pendingEvents.append(contentsOf: data)

            if batchWorkItem == nil {
                let workItem = DispatchWorkItem { flushBatch() }
                batchWorkItem = workItem
                batchQueue.asyncAfter(deadline: .now() + batchWindowSeconds, execute: workItem)
            }
        }
    }

    /// 배치 버퍼를 즉시 전송 (외부 호출용)
    static func flush() {
        batchQueue.async {
            batchWorkItem?.cancel()
            batchWorkItem = nil
            flushBatch()
        }
    }

    /// 배치 전송 실행 (batchQueue 내에서만 호출)
    private static func flushBatch() {
        let eventsToSend = pendingEvents
        pendingEvents = []
        batchWorkItem = nil

        guard !eventsToSend.isEmpty else { return }
        performRequest(events: eventsToSend)
    }

    private static func performRequest(events: [Event]) {
        // 폴링 타이머 리셋
        resetPollTimer()

        EventQueue.shared.addEvent { done in
            guard let clientId = SdkConfig.clientIdInUserDefaults,
                  let bluxId = SdkConfig.bluxIdInUserDefaults,
                  let deviceId = SdkConfig.deviceIdInUserDefaults
            else {
                done()
                return
            }

            HTTPClient.shared.post(
                path: "/v2/applications/\(clientId)/blux-users/\(bluxId)/collect-events",
                body: EventWrapper(events: events, deviceId: deviceId)
            ) { (response: CollectEventsResponse?, error) in
                defer { done() }

                if let error = error {
                    Logger.error("Failed to send event request: \(error)")
                    // 실패 시 지수 백오프
                    let nextPollDelay = cachedPollDelayMs > 1000 * 60 * 60 * 24 ? cachedPollDelayMs : cachedPollDelayMs * 2
                    cachedPollDelayMs = nextPollDelay
                    scheduleNextPoll(delayMs: nextPollDelay)
                    return
                }

                if let response = response {
                    if let inapp = response.inapp {
                        DispatchQueue.main.async {
                            InappService.handleInappResponse(inapp)
                        }
                    }
                    if let nextPollDelay = response.nextPollDelayMs {
                        let normalizedDelayMs = max(nextPollDelay, 3000)
                        cachedPollDelayMs = normalizedDelayMs
                        scheduleNextPoll(delayMs: normalizedDelayMs)
                    }
                }
            }
        }
    }

    private static func resetPollTimer() {
        DispatchQueue.main.async {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    private static func scheduleNextPoll(delayMs: Int) {
        resetPollTimer()

        let normalizedDelayMs = max(delayMs, 3000)

        DispatchQueue.main.async {
            let timer = Timer(
                timeInterval: Double(normalizedDelayMs) / 1000.0,
                repeats: false
            ) { _ in
                // 빈 이벤트로 폴링
                performRequest(events: [])
            }
            RunLoop.main.add(timer, forMode: .common)
            pollTimer = timer
        }
    }

    private static func ensureLifecycleObserver() {
        #if canImport(UIKit)
            DispatchQueue.main.async {
                guard !lifecycleObserverInstalled else { return }
                lifecycleObserverInstalled = true

                let center = NotificationCenter.default
                let flushOnBackground: (Notification) -> Void = { _ in
                    flush()
                }

                center.addObserver(
                    forName: UIApplication.didEnterBackgroundNotification,
                    object: nil,
                    queue: .main,
                    using: flushOnBackground
                )
                center.addObserver(
                    forName: UIApplication.willTerminateNotification,
                    object: nil,
                    queue: .main,
                    using: flushOnBackground
                )
            }
        #endif
    }
}
