//
//  AppleAnalysis.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//
//  The one place that talks to Apple's MediaIntelligence (macOS / iOS 27).
//  Measured traps, all handled here:
//  - `analyze` is `nonisolated(nonsending)`: called from the main actor it
//    runs ON it for minutes. It is called from a detached task.
//  - Cancellation is NOT honoured, whatever the documentation says: cancelled
//    after 5 s it ran another 62 s and returned a normal result. A CLI's
//    Ctrl-C still works because it ends the process.
//  - Failures come back per request inside the result, not thrown.
//  - Two analyses at once crash the process (SIGSEGV), despite the
//    documentation's "queued serially" — see AnalysisGate.
//  - It decodes every frame through the hardware decoder: ~8–11× faster than
//    real time at ≤720p, 9–20× SLOWER than real time on 4.5K HEVC — hence
//    the proxy.
//  - It works in 5-minute chunks (7,193 frames at 23.976 fps), each decoded
//    at 576×324 and re-encoded to H.264 before its models run, so up to
//    1080p the cost is frames, not pixels: a 10-minute film took 58 s at
//    1080p, 55 s at 720p, 54.5 s at 360p (2026-10-27, unified log + timing).
//  - Between chunks it restarts decoding mid-stream; AVFoundation cannot do
//    that for AV1 (-12911), so every AV1 file longer than one chunk failed
//    with "Analysis failed to complete" (6 of 6 from ffmpeg's libsvtav1,
//    shorter ones passed). The
//    caller retries those on an H.264 copy (Proxy.retries).
//  - Same file, same top moments every run (≥ 99% of levels); but any re-encode of the same
//    pictures moves about half the level segments (by ±1 mostly), enough to
//    reorder close top moments.
//

import CoreMedia
import Foundation
#if canImport(MediaIntelligence)
import MediaIntelligence
#endif

/// What Apple's analysis returned, in plain seconds.
struct AppleAnswer: Sendable {
    let highlights: [ClosedRange<Double>]
    let levels: [InterestLevel]
    let keyFrame: Double?
}

enum AppleAnalysis {

    /// Whether this process can run the analysis at all.
    static var isAvailable: Bool {
        #if canImport(MediaIntelligence)
        if #available(macOS 27, iOS 27, *) { return true }
        #endif
        return false
    }

    /// Highlights, levels and the key frame of one video, in one decode.
    static func analyze(_ url: URL) async throws(VideoHighlightsError) -> AppleAnswer {
        #if canImport(MediaIntelligence)
        if #available(macOS 27, iOS 27, *) {
            return try await run(url)
        }
        #endif
        throw .unavailable
    }

    #if canImport(MediaIntelligence)
    @available(macOS 27, iOS 27, *)
    private static func run(_ url: URL) async throws(VideoHighlightsError) -> AppleAnswer {
        let asset = MediaIntelligenceVideoAsset(id: MediaIntelligenceVideoAsset.ID(UUID().uuidString), kind: .url(url))
        let outcome: (Result<HighlightAnalysisRequest.Result, any Error>, Result<KeyFrameAnalysisRequest.Result, any Error>)
        do {
            outcome = try await AnalysisGate.shared.run {
                try await Task.detached {
                    try await VideoAnalyzer.shared.analyze(asset, for: HighlightAnalysisRequest(), KeyFrameAnalysisRequest())
                }.value
            }
        } catch {
            throw .analysisFailed(error.localizedDescription)
        }
        let analysis: HighlightAnalysisRequest.Result
        switch outcome.0 {
        case .success(let value): analysis = value
        case .failure(let error): throw .analysisFailed(error.localizedDescription)
        }
        // The key frame is a nicety: its failure does not sink the highlights.
        var keyFrame: Double? = nil
        if case .success(let frame) = outcome.1, frame.timestamp.isNumeric { keyFrame = frame.timestamp.seconds }
        let highlights: [ClosedRange<Double>] = analysis.highlights.compactMap { range -> ClosedRange<Double>? in
            guard range.start.isNumeric, range.end.isNumeric, range.end.seconds > range.start.seconds else { return nil }
            return range.start.seconds...range.end.seconds
        }
        let levels: [InterestLevel] = analysis.levels.compactMap { item -> InterestLevel? in
            guard item.timeRange.start.isNumeric, item.timeRange.end.isNumeric else { return nil }
            return InterestLevel(start: item.timeRange.start.seconds, end: item.timeRange.end.seconds,
                                 level: Double(item.level))
        }
        return AppleAnswer(highlights: highlights, levels: levels, keyFrame: keyFrame)
    }
    #endif
}
