//
//  Proxy.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//
//  A 720p copy for analysis. Apple's analysis took 1,081 s on a 2-minute
//  4.5K HEVC clip and 15.4 s on a 720p copy of it, with the same verdict
//  (212 of 240 level segments identical, the rest faint signal). Times map
//  1:1, so moments found on the copy apply to the original.
//
//  0.2.0 — MEASURED on a 31-minute 4K AV1 film (M3 Max): the copy used to be
//  VideoForge's resize export, which draws every frame through a video
//  composition: 146–151 s, and a different file every run (two copies of
//  the same source gave different top-3 moments). Apple's own 1280×720
//  export preset on a video-only composition, with no per-frame drawing:
//  74–82 s, and the same pictures every run (6 copies: 5 of 6 analyses
//  identical, the sixth 67% identical levels). Decoding the 4K AV1 alone takes 60 s, so the copy
//  is now within a third of the floor.
//

import AVFoundation
import Foundation

enum Proxy {

    /// Larger than this on its longest side gets a proxy.
    static let threshold: Int = 1920

    /// The proxy's longest side: what Apple's 1280×720 preset fits a
    /// picture inside.
    static let longestSide: Int = 1280

    /// Whether a video of this size should be analysed through a proxy.
    static func needed(width: Int, height: Int) -> Bool { max(width, height) > threshold }

    /// The export preset for a copy of a video this size: Apple's 1280×720
    /// preset when the picture is larger than that, otherwise the same size
    /// re-encoded (a copy made only because the original failed must not be
    /// scaled up).
    static func preset(width: Int, height: Int) -> String {
        max(width, height) > longestSide ? AVAssetExportPreset1280x720 : AVAssetExportPresetHighestQuality
    }

    /// Whether an analysis of the original that failed is tried again on a
    /// copy: only when the original was what failed and proxies are
    /// allowed. Measured: Apple's analysis failed ("Analysis failed to
    /// complete", decoder status -12911) on every AV1 file longer than its
    /// 5-minute chunk (6 of 6) — it restarts decoding mid-stream there, which
    /// AVFoundation cannot do for AV1 — and succeeds on an H.264 copy.
    static func retries(after error: VideoHighlightsError, usedProxy: Bool, allowed: Bool) -> Bool {
        guard allowed, !usedProxy, case .analysisFailed = error else { return false }
        return true
    }

    /// Writes the copy into `folder` and returns it: the video track alone
    /// (the analysis was measured without sound), at its own place in time,
    /// through Apple's export preset.
    static func make(from url: URL, width: Int, height: Int, in folder: URL) async throws(VideoHighlightsError) -> URL {
        let destination: URL = folder.appendingPathComponent("proxy.mp4")
        do {
            let asset = AVURLAsset(url: url)
            guard let track = try await asset.loadTracks(withMediaType: .video).first else {
                throw VideoHighlightsError.proxyFailed("no video track")
            }
            let composition = AVMutableComposition()
            guard let copy = composition.addMutableTrack(withMediaType: .video,
                                                         preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw VideoHighlightsError.proxyFailed("could not build the copy")
            }
            let range: CMTimeRange = try await track.load(.timeRange)
            // Inserted where it sits in the original, so times map 1:1 even
            // when the picture does not start at 0.
            try copy.insertTimeRange(range, of: track, at: range.start)
            copy.preferredTransform = try await track.load(.preferredTransform)
            guard let session = AVAssetExportSession(asset: composition,
                                                     presetName: preset(width: width, height: height)) else {
                throw VideoHighlightsError.proxyFailed("no export session for this video")
            }
            try await session.export(to: destination, as: .mp4)
        } catch let error as VideoHighlightsError {
            throw error
        } catch {
            throw .proxyFailed(error.localizedDescription)
        }
        return destination
    }
}
