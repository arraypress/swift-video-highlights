//
//  AnalysisGate.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//
//  One Apple analysis at a time, in this process. Apple's documentation says
//  concurrent `analyze` calls are queued and run serially; measured on macOS
//  27, two at once (Swift Testing's parallel tests) ended the process with
//  SIGSEGV, while each alone passed. So callers queue here instead.
//

/// A first-come lock for async code.
actor AnalysisGate {

    static let shared = AnalysisGate()

    private var busy: Bool = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    /// Waits until no analysis is running, then holds the gate.
    func acquire() async {
        if busy {
            await withCheckedContinuation { waiting.append($0) }
        } else {
            busy = true
        }
    }

    /// Runs `body` holding the gate, and releases it however `body` ends.
    nonisolated func run<T: Sendable>(_ body: @Sendable () async throws -> T) async throws -> T {
        await acquire()
        do {
            let value: T = try await body()
            await release()
            return value
        } catch {
            await release()
            throw error
        }
    }

    /// Hands the gate to the next waiter, or opens it.
    func release() {
        if waiting.isEmpty {
            busy = false
        } else {
            waiting.removeFirst().resume()
        }
    }
}
