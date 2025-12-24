//
//  EventService.swift
//  BluxClient
//
//  Created by Tommy on 5/22/24.
//
import Foundation

class EventWrapper: Codable {
    let events: [Event]
    let device_id: String

    init(events: [Event], deviceId: String) {
        self.events = events
        self.device_id = deviceId
    }
}

@available(iOSApplicationExtension, unavailable)
class EventService {
    // collect-events 응답에 따라 빈 이벤트 폴링을 위한 타이머
    private static var pollTimer: Timer?
    
    // 마지막으로 서버에서 받은 polling 간격 (밀리초)
    private static var cachedPollDelayMs: Int = 10000

    private static func resetPollTimer() {
        DispatchQueue.main.async {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    private static func scheduleNextPoll(delayMs: Int) {
        resetPollTimer()
        
        // 서버가 0(또는 너무 작은 값)을 주면 즉시 요청 루프가 생길 수 있어 최소 3초 지연을 보장한다.
        let normalizedDelayMs = max(delayMs, 3000)

        DispatchQueue.main.async {
            let timer = Timer(
                timeInterval: Double(normalizedDelayMs) / 1000.0,
                repeats: false
            ) { _ in
                // 빈 이벤트를 보내 폴링 (sendEvent 내부에서 resetPollTimer 호출됨)
                sendEvent([])
            }
            RunLoop.main.add(timer, forMode: .common)
            pollTimer = timer
        }
    }

    /// Send request
    /// - Parameters:
    ///   - data: event data
    static func sendEvent(
        _ data: [Event]
    ) {
        // 새로운 요청 시 하트비트 타이머 리셋
        resetPollTimer()

        let eventTask = {
            guard let clientId = SdkConfig.clientIdInUserDefaults,
                  let bluxId = SdkConfig.bluxIdInUserDefaults,
                  let deviceId = SdkConfig.deviceIdInUserDefaults
            else {
                return
            }

            HTTPClient.shared.post(
                path:
                "/v2/applications/\(clientId)/blux-users/\(bluxId)/collect-events",
                body: EventWrapper(events: data, deviceId: deviceId)
            ) { (response: CollectEventsResponse?, error) in
                if let error = error {
                    Logger.error("Failed to send event request: \(error)")
                    // 요청 실패 시 캐싱된 polling 간격이 있으면 재시도
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
        EventQueue.shared.addEvent(eventTask)
    }
    
}
