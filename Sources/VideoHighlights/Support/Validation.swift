//
//  Validation.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//

/// Options that cannot be met, refused before any work.
enum Validation {

    static func check(_ options: HighlightOptions) throws(VideoHighlightsError) {
        guard options.top >= 1 else { throw .invalidOptions("Ask for at least one moment") }
        guard options.minimumLength > 0, options.maximumLength > 0 else {
            throw .invalidOptions("Moment lengths must be more than 0 seconds")
        }
        guard options.minimumLength <= options.maximumLength else {
            throw .invalidOptions("The shortest moment (\(options.minimumLength) s) is longer than the longest (\(options.maximumLength) s)")
        }
        guard options.joinGap >= 0 else { throw .invalidOptions("The join gap cannot be negative") }
    }
}
