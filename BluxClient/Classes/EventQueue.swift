//
//  EventQueue.swift
//  BluxClient
//
//  Created by jihoon on 11/12/24.
//
import Foundation

class EventQueue {
    static let shared = EventQueue()

    /// 각 task는 완료 시 done()을 호출해야 함
    private var eventsQueue: [(@escaping () -> Void) -> Void] = []
    private var isProcessing = false
    private var isInitialized = false
    private let queue = DispatchQueue(label: "eventQueue")

    private init() {}

    /// SDK 초기화 완료 시 호출. 대기 중인 이벤트들을 처리 시작.
    func setInitialized() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.isInitialized = true
            self.processNext()
        }
    }

    /// 동기 작업용 (기존 호환)
    func addEvent(_ eventTask: @escaping () -> Void) {
        addEvent { done in
            eventTask()
            done()
        }
    }

    /// 비동기 작업용 (완료 시 done 호출 필요)
    func addEvent(_ eventTask: @escaping (@escaping () -> Void) -> Void) {
        queue.async { [weak self] in
            self?.eventsQueue.append(eventTask)
            self?.processNext()
        }
    }

    private func processNext() {
        queue.async { [weak self] in
            guard let self = self,
                  self.isInitialized,
                  !self.isProcessing,
                  let nextTask = self.eventsQueue.first
            else { return }

            self.isProcessing = true

            nextTask { [weak self] in
                guard let self = self else { return }
                self.queue.async {
                    if !self.eventsQueue.isEmpty {
                        self.eventsQueue.removeFirst()
                    }
                    self.isProcessing = false
                    self.processNext()
                }
            }
        }
    }
}
