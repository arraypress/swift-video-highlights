//
//  FrameLook.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//
//  Whether a frame is worth showing as a thumbnail: not near-black, not one
//  flat colour. Apple's key frame was 0 s for every clip of two minutes or
//  less, including a trailer that opens on black, so the frame is looked at
//  before it is trusted. Thresholds are measured — see `usable`.
//

import CoreGraphics

/// Brightness statistics of a frame.
enum FrameLook {

    /// Mean and standard deviation of luma, 0–1, over the frame drawn at
    /// 64×64 in grey.
    static func luma(of image: CGImage) -> (mean: Double, deviation: Double)? {
        let side: Int = 64
        var pixels: [UInt8] = [UInt8](repeating: 0, count: side * side)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8,
                                          bytesPerRow: side, space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else { return nil }
        return luma(of: pixels)
    }

    /// Mean and standard deviation of 8-bit grey samples, 0–1.
    static func luma(of samples: [UInt8]) -> (mean: Double, deviation: Double) {
        guard !samples.isEmpty else { return (0, 0) }
        let values: [Double] = samples.map { Double($0) / 255 }
        let mean: Double = values.reduce(0, +) / Double(values.count)
        let variance: Double = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        return (mean, variance.squareRoot())
    }

    /// Not near-black and not flat.
    static func usable(mean: Double, deviation: Double) -> Bool {
        mean >= minimumMean && deviation >= minimumDeviation
    }

    // Measured on 24 frames of the probe set (public-domain films, Apple
    // aerial, synthetic clips): every real picture — night scenes from a
    // horror trailer included — had mean ≥ 0.163 and deviation ≥ 0.09; the
    // trailer's black opening was (0.0, 0.0) and a static grey frame
    // (0.37, 0.0). The cut sits well inside that gap.
    static let minimumMean: Double = 0.06
    static let minimumDeviation: Double = 0.03
}
