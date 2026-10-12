# Swift Video Highlights

The best moments of a video, found on this machine: Apple's MediaIntelligence
(macOS / iOS 27) scores engagement through the whole video, and this turns its
answer into ranked, clip-length moments and a thumbnail worth looking at.

```swift
import VideoHighlights

let report = try await VideoHighlights.analyze(talk, options: HighlightOptions(top: 3, minimumLength: 15, maximumLength: 60))
for moment in report.moments {
    print(moment.rank, moment.start, moment.end, moment.score)   // 1 355.61 370.61 5.88
}
report.thumbnail        // 539.41 — a time worth grabbing as the cover
report.levels           // 0–9 interest, about every half second
report.usedProxy        // true when a 720p copy was analysed instead
```

"Nothing engaging" is an answer, not an error: slow, low-motion footage (a
drone aerial, a static shot) scores zero all the way through, and the report
comes back with no moments.

## What it adds to Apple's answer

Apple returns raw highlights, a level series and a key frame. Measured on
public-domain films, synthetic clips and Apple's own aerials, the raw answer
needs work before it is useful:

- **Highlights are not a top-N.** A 9-minute film came back with 50 of them,
  2.5–10 s each, covering 30–58% of the running time. They are joined into
  windows (neighbours ≤ 2 s apart, up to the longest length), short windows
  are widened evenly into the video around them, each window is scored by
  its overlap-weighted mean level, and the best that don't overlap are kept.
  Ties go to the earlier moment, so the same analysis gives the same answer.
- **The key frame is 0 s for any clip of two minutes or less** — including a
  trailer that opens on black. A key frame of 0 s, or one whose frame is
  near-black or flat, is replaced by the middle of the best moment (then the
  most engaging level segment, then the middle of the video). The cut was
  measured: every real frame in the probe set, night scenes included, had
  luma mean ≥ 0.163 and deviation ≥ 0.09; the black opening was (0, 0) and a
  static grey frame (0.37, 0). Thresholds: mean 0.06, deviation 0.03.
- **4K is slow.** The analysis decodes every frame: ~8–11× faster than real
  time at ≤ 720p, but 9–20× *slower* than real time on 4.5K HEVC. Anything
  larger than 1080p is analysed through a 720p copy made with VideoForge's
  hardware export (times map 1:1 back to the original).
- **Audio files** get "no video track", not Apple's misleading timeout.
- **Two analyses at once crashed the process** (SIGSEGV) despite Apple's
  documented serial queue, so calls queue in-process (`AnalysisGate`).
- **Cancellation is not honoured** by Apple's analysis (cancelled after 5 s, it
  ran another 62 s). A command-line tool stops it by exiting.

## Measured (M3 Max, macOS 27)

| Video | Length | Analysis | Result |
|---|---|---|---|
| Synthetic control: static, action at 25–31 s | 60 s · 720p | 5.7 s | best moment covers the action (21–36 s with 15 s minimum) |
| Synthetic portrait: action at 12–17 s | 40 s · 720×1280 | 4.0 s | best moment covers the action |
| *Duck and Cover* (1951) | 9 min 15 s · 368×480 | 69 s | 50 raw highlights → top 3 at 5:56, 8:16, 2:56; key frame 8:59 |
| Apple aerial, through the proxy | 2 min · 4480×3088 HEVC | **96 s** (was 1,081 s on the original) | no highlights — same verdict as the original |

The live tests (`HIGHLIGHTS_VIDEOS=<folder> swift test`) run the synthetic
control and portrait clips, an audio file, a garbage file and two analyses at
once; the pure ranking, fitting and thumbnail rules are tested without video.

## Requirements

- Builds with the macOS 27 / iOS 27 SDK (Xcode 27). The package floor is
  macOS 26 / iOS 26: everything that touches MediaIntelligence is
  `@available(macOS 27, iOS 27, *)` and the framework is weak-linked, so a tool
  using this still launches on 26 and `VideoHighlights.isAvailable` is false
  there. Built with an SDK that lacks MediaIntelligence, it compiles with the
  analysis unavailable.
- Depends on [swift-video-forge](https://github.com/arraypress/swift-video-forge)
  for the proxy and the frame check.
- iOS: compiles for devices; MediaIntelligence is not in the Simulator SDK.

## License

MIT — see [LICENSE](LICENSE).
