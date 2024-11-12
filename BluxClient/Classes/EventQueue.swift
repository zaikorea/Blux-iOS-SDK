//
//  EventQueue.swift
//  BluxClient
//
//  Created by jihoon on 11/12/24.
//
import Foundation

class EventQueue {
    static let shared = EventQueue()

    private var eventsQueue: [() -> Void] = []
    private var isProcessing = false
    private let queue = DispatchQueue(label: "eventQueue")

    private init() {}

    func addEvent(_ eventTask: @escaping () -> Void) {
        queue.async { [weak self] in
            self?.eventsQueue.append(eventTask)
            self?.processNext()
        }
    }

    private func processNext() {
        queue.async { [weak self] in
            guard let self = self, !self.isProcessing,
                let nextTask = self.eventsQueue.first
            else { return }

            self.isProcessing = true

            nextTask()

            self.queue.async {
                self.eventsQueue.removeFirst()
                self.isProcessing = false
                self.processNext()
            }
        }
    }
}
