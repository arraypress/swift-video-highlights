//
//  LiveTests.swift
//  VideoHighlightsTests
//
//  Created by David Sherlock on 2026.
//
//  Apple's real analysis on synthetic clips with known action. Set
//  HIGHLIGHTS_VIDEOS to a folder holding `control.mp4` (60 s, 1280×720,
//  static except for action at 25–31 s), `portrait.mp4` (40 s, 720×1280,
//  action at 12–17 s), `av1-long.mp4` (any AV1 video longer than 5 minutes,
//  e.g. 400 s at 640×360 from ffmpeg's libsvtav1), `audio.m4a` and
//  `garbage.mp4` (random bytes). macOS 27 only.
//

import Foundation
import Testing
@testable import VideoHighlights

private let folder: String? = ProcessInfo.processInfo.environment["HIGHLIGHTS_VIDEOS"]

/// How much of `action` the moment covers, 0–1.
private func cover(_ moment: HighlightMoment, _ action: ClosedRange<Double>) -> Double {
    max(0, min(moment.end, action.upperBound) - max(moment.start, action.lowerBound))
        / (action.upperBound - action.lowerBound)
}

@Suite("Live analysis", .enabled(if: folder != nil && VideoHighlights.isAvailable))
struct LiveTests {

    @Test("The synthetic control's action (25–31 s) is inside the best moment")
    func control() async throws {
        let report = try await VideoHighlights.analyze(URL(fileURLWithPath: folder! + "/control.mp4"))
        let best = try #require(report.moments.first)
        #expect(cover(best, 25...31) >= 0.8, "best moment \(best.start)–\(best.end)")
        #expect(!report.usedProxy)
        #expect(report.thumbnailSource != .keyFrame, "Apple's key frame for a 60 s clip is 0 s, a flat grey frame")
    }

    @Test("Portrait works the same: the action at 12–17 s is the best moment")
    func portrait() async throws {
        let report = try await VideoHighlights.analyze(URL(fileURLWithPath: folder! + "/portrait.mp4"),
                                                       options: HighlightOptions(top: 1, minimumLength: 8, maximumLength: 20))
        let best = try #require(report.moments.first)
        #expect(cover(best, 12...17) >= 0.8, "best moment \(best.start)–\(best.end)")
    }

    @Test("An AV1 video past Apple's 5-minute chunk, which its analysis gives up on, is analysed through a copy")
    func longAV1() async throws {
        let report = try await VideoHighlights.analyze(URL(fileURLWithPath: folder! + "/av1-long.mp4"))
        #expect(report.usedProxy)
        #expect(report.duration > 300 && !report.levels.isEmpty)
        // AVFoundation cannot read the AV1 original's frame either; the copy's
        // frame at the same time stands in (a film frame, never dark or flat).
        #expect(report.keyFrame == nil || report.thumbnailSource == .keyFrame)
    }

    @Test("With copies off, the same AV1 video fails as Apple's analysis does")
    func longAV1WithoutCopy() async throws {
        await #expect(throws: VideoHighlightsError.self) {
            _ = try await VideoHighlights.analyze(URL(fileURLWithPath: folder! + "/av1-long.mp4"),
                                                  options: HighlightOptions(usesProxy: false))
        }
    }

    @Test("An audio file is refused as having no video, not as Apple's misleading timeout")
    func audioOnly() async throws {
        await #expect(throws: VideoHighlightsError.noVideoTrack(folder! + "/audio.m4a")) {
            _ = try await VideoHighlights.analyze(URL(fileURLWithPath: folder! + "/audio.m4a"))
        }
    }

    @Test("A garbage file is unreadable")
    func garbage() async throws {
        await #expect(throws: VideoHighlightsError.self) {
            _ = try await VideoHighlights.analyze(URL(fileURLWithPath: folder! + "/garbage.mp4"))
        }
    }
}

@Suite("Live concurrency", .enabled(if: folder != nil && VideoHighlights.isAvailable))
struct LiveConcurrencyTests {

    @Test("Two analyses at once queue rather than crash (Apple's own queueing segfaulted)")
    func twoAtOnce() async throws {
        async let a = VideoHighlights.analyze(URL(fileURLWithPath: folder! + "/portrait.mp4"))
        async let b = VideoHighlights.analyze(URL(fileURLWithPath: folder! + "/control.mp4"))
        let (first, second) = try await (a, b)
        #expect(!first.moments.isEmpty && !second.moments.isEmpty)
    }
}
