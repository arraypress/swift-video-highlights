//
//  VideoHighlights.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//
//  The best moments of a video, on this machine: Apple's MediaIntelligence
//  (macOS / iOS 27) scores engagement through the whole video; this turns
//  its answer into ranked, clip-length moments and a thumbnail time that is
//  worth looking at. The models live in Models/, the ranking and the frame
//  checks in Support/ — this file is the public surface and the order of
//  the steps.
//

import Foundation
import VideoForge

/// Finds the best moments of a video.
///
/// ```swift
/// import VideoHighlights
///
/// let report = try await VideoHighlights.analyze(url, options: HighlightOptions(top: 3))
/// for moment in report.moments {
///     print(moment.rank, moment.start, moment.end, moment.score)
/// }
/// print("thumbnail at", report.thumbnail)
/// ```
///
/// Slow, low-motion footage legitimately scores zero all the way through:
/// that is a report with no moments, not an error.
public enum VideoHighlights {

    /// Whether this system can analyse video: macOS / iOS 27, and a build
    /// made with an SDK that has Apple's MediaIntelligence.
    public static var isAvailable: Bool { AppleAnalysis.isAvailable }

    /// Analyses one video.
    ///
    /// Apple's analysis cannot be cancelled once it starts (measured: it ran
    /// on for a minute after a cancel), so a long video runs to the end; a
    /// command-line tool stops it by exiting.
    ///
    /// - Parameters:
    ///   - url: A movie file.
    ///   - options: How many moments, and how long each may be.
    /// - Returns: The moments, the level series, the key frame and a thumbnail time.
    /// - Throws: ``VideoHighlightsError``.
    public static func analyze(_ url: URL, options: HighlightOptions = HighlightOptions())
        async throws(VideoHighlightsError) -> HighlightReport {
        try Validation.check(options)
        guard FileManager.default.fileExists(atPath: url.path) else { throw .fileNotFound(url.path) }

        let info: VideoInfo
        do { info = try await VideoForge.describe(url) } catch {
            throw .unreadable(error.localizedDescription)
        }
        // Checked here: Apple answers an audio file with a "timed out".
        guard info.hasVideo else { throw .noVideoTrack(url.path) }
        guard AppleAnalysis.isAvailable else { throw .unavailable }

        let started = ContinuousClock.now
        let usesProxy: Bool = options.usesProxy && Proxy.needed(width: info.width, height: info.height)
        let answer: AppleAnswer
        if usesProxy {
            let folder: URL = FileManager.default.temporaryDirectory
                .appendingPathComponent("video-highlights-\(UUID().uuidString)", isDirectory: true)
            do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) } catch {
                throw .proxyFailed(error.localizedDescription)
            }
            defer { try? FileManager.default.removeItem(at: folder) }
            answer = try await AppleAnalysis.analyze(try await Proxy.make(from: url, in: folder))
        } else {
            answer = try await AppleAnalysis.analyze(url)
        }

        let moments: [HighlightMoment] = MomentRanking.moments(highlights: answer.highlights, levels: answer.levels,
                                                               duration: info.duration, options: options)
        let keyFrame: Double? = answer.keyFrame.flatMap { $0 > 0 ? MomentRanking.rounded($0) : nil }
        let usable: Bool = await keyFrameIsUsable(url, at: keyFrame)
        let thumbnail = ThumbnailChoice.time(keyFrame: keyFrame, keyFrameUsable: usable, moments: moments,
                                             levels: answer.levels, duration: info.duration)
        return HighlightReport(duration: info.duration, moments: moments,
                               highlights: answer.highlights.sorted { $0.lowerBound < $1.lowerBound },
                               levels: answer.levels, keyFrame: keyFrame, thumbnail: thumbnail.seconds,
                               thumbnailSource: thumbnail.source, usedProxy: usesProxy,
                               seconds: MomentRanking.rounded((ContinuousClock.now - started) / .seconds(1)))
    }

    /// Whether the frame at Apple's key frame is worth showing.
    private static func keyFrameIsUsable(_ url: URL, at seconds: Double?) async -> Bool {
        guard let seconds,
              let frame = try? await Frames.at(url, times: [seconds], maxPixelSize: 256).first,
              let look = FrameLook.luma(of: frame.image) else { return false }
        return FrameLook.usable(mean: look.mean, deviation: look.deviation)
    }
}
