//
//  ThumbnailTests.swift
//  VideoHighlightsTests
//
//  Created by David Sherlock on 2026.
//

import Testing
@testable import VideoHighlights

@Suite("Thumbnail choice")
struct ThumbnailTests {

    private let best = HighlightMoment(rank: 1, start: 20, end: 40, score: 7, peak: 9, highlights: 2)

    @Test("Apple's key frame wins when it gave one and the frame is worth showing")
    func keyFrame() {
        let choice = ThumbnailChoice.time(keyFrame: 539, keyFrameUsable: true, moments: [best], levels: [], duration: 555)
        #expect(choice.seconds == 539 && choice.source == .keyFrame)
    }

    @Test("A 0 s key frame — Apple's answer for any clip up to two minutes — falls back to the best moment")
    func zeroKeyFrame() {
        let choice = ThumbnailChoice.time(keyFrame: nil, keyFrameUsable: false, moments: [best], levels: [], duration: 95)
        #expect(choice.seconds == 30 && choice.source == .topMoment)
    }

    @Test("A dark or flat key frame falls back too")
    func darkKeyFrame() {
        let choice = ThumbnailChoice.time(keyFrame: 12, keyFrameUsable: false, moments: [best], levels: [], duration: 95)
        #expect(choice.source == .topMoment)
    }

    @Test("With no moments: the most engaging level, then the middle of the video")
    func lastResorts() {
        let levels = [InterestLevel(start: 0, end: 1, level: 1), InterestLevel(start: 4, end: 5, level: 3)]
        let peak = ThumbnailChoice.time(keyFrame: nil, keyFrameUsable: false, moments: [], levels: levels, duration: 10)
        #expect(peak.seconds == 4.5 && peak.source == .peakLevel)
        let middle = ThumbnailChoice.time(keyFrame: nil, keyFrameUsable: false, moments: [],
                                          levels: [InterestLevel(start: 0, end: 10, level: 0)], duration: 10)
        #expect(middle.seconds == 5 && middle.source == .middle)
    }

    @Test("Frame statistics: black and flat fail, a real picture passes")
    func frameLook() {
        let black = FrameLook.luma(of: [UInt8](repeating: 0, count: 4096))
        #expect(!FrameLook.usable(mean: black.mean, deviation: black.deviation))
        let grey = FrameLook.luma(of: [UInt8](repeating: 95, count: 4096))
        #expect(!FrameLook.usable(mean: grey.mean, deviation: grey.deviation), "the static grey control frame")
        let picture = FrameLook.luma(of: (0..<4096).map { UInt8(($0 * 37) % 256) })
        #expect(FrameLook.usable(mean: picture.mean, deviation: picture.deviation))
    }

    @Test("Options that cannot be met are refused")
    func validation() {
        #expect(throws: VideoHighlightsError.self) { try Validation.check(HighlightOptions(top: 0)) }
        #expect(throws: VideoHighlightsError.self) { try Validation.check(HighlightOptions(minimumLength: 60, maximumLength: 15)) }
        #expect(throws: Never.self) { try Validation.check(HighlightOptions()) }
    }
}
