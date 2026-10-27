//
//  ProxyTests.swift
//  VideoHighlightsTests
//
//  Created by David Sherlock on 2026.
//

import AVFoundation
import Testing
@testable import VideoHighlights

@Suite("Proxy rules")
struct ProxyTests {

    @Test("Only pictures larger than 1080p on their longest side get a copy up front")
    func needed() {
        #expect(!Proxy.needed(width: 1920, height: 1080))
        #expect(!Proxy.needed(width: 1080, height: 1920))
        #expect(Proxy.needed(width: 1921, height: 1080))
        #expect(Proxy.needed(width: 2160, height: 3840))
    }

    @Test("A picture larger than 1280 is fitted into Apple's 1280×720 preset, in either orientation")
    func scaledDown() {
        #expect(Proxy.preset(width: 3840, height: 2160) == AVAssetExportPreset1280x720)
        #expect(Proxy.preset(width: 2160, height: 3840) == AVAssetExportPreset1280x720)
        #expect(Proxy.preset(width: 1281, height: 720) == AVAssetExportPreset1280x720)
        #expect(Proxy.preset(width: 1080, height: 1920) == AVAssetExportPreset1280x720)
    }

    @Test("A picture 1280 or smaller is copied at its own size, never scaled up")
    func ownSize() {
        #expect(Proxy.preset(width: 1280, height: 720) == AVAssetExportPresetHighestQuality)
        #expect(Proxy.preset(width: 720, height: 1280) == AVAssetExportPresetHighestQuality)
        #expect(Proxy.preset(width: 640, height: 360) == AVAssetExportPresetHighestQuality)
    }

    @Test("A failed analysis of the original is retried on a copy")
    func retriesOriginal() {
        #expect(Proxy.retries(after: .analysisFailed("Analysis failed to complete"), usedProxy: false, allowed: true))
    }

    @Test("No retry when the copy itself failed, when copies are off, or for any other error")
    func noRetry() {
        #expect(!Proxy.retries(after: .analysisFailed("x"), usedProxy: true, allowed: true))
        #expect(!Proxy.retries(after: .analysisFailed("x"), usedProxy: false, allowed: false))
        #expect(!Proxy.retries(after: .unavailable, usedProxy: false, allowed: true))
        #expect(!Proxy.retries(after: .proxyFailed("x"), usedProxy: false, allowed: true))
        #expect(!Proxy.retries(after: .noVideoTrack("x"), usedProxy: false, allowed: true))
    }
}
