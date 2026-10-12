//
//  Proxy.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//
//  A 720p copy for analysis. Apple's analysis took 1,081 s on a 2-minute
//  4.5K HEVC clip and 15.4 s on a 720p copy of it, with the same verdict
//  (212 of 240 level segments identical, the rest faint signal). Times map
//  1:1, so moments found on the copy apply to the original. Made with
//  VideoForge's hardware export — ffmpeg's software decode of the same clip
//  took 71 minutes.
//

import Foundation
import VideoForge

enum Proxy {

    /// Larger than this on its longest side gets a proxy.
    static let threshold: Int = 1920

    /// The proxy's longest side.
    static let longestSide: Int = 1280

    /// Whether a video of this size should be analysed through a proxy.
    static func needed(width: Int, height: Int) -> Bool { max(width, height) > threshold }

    /// Writes the copy into `folder` and returns it.
    static func make(from url: URL, in folder: URL) async throws(VideoHighlightsError) -> URL {
        let destination: URL = folder.appendingPathComponent("proxy.mp4")
        let options = VideoProcessOptions(operations: [.resize(.longestSide(longestSide))],
                                          export: ExportSpec(container: .mp4, keepsAudio: false,
                                                             keepsSidecarTracks: false))
        do {
            try await VideoForge.process(url, to: destination, options: options)
        } catch {
            throw .proxyFailed(error.localizedDescription)
        }
        return destination
    }
}
