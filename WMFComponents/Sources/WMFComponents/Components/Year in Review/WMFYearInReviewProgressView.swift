import SwiftUI

/// Shows the position in the review as one thin bar on the trailing edge of the slide.
///
/// The bar has one segment for each slide. A segment at full opacity is a slide the reader
/// reached. This gives the position and the length of the review at the same time, which a
/// single moving thumb cannot do.
struct WMFYearInReviewProgressView: View {

    let slideCount: Int
    let currentIndex: Int
    let color: Color

    private static let barWidth: CGFloat = 3
    private static let segmentSpacing: CGFloat = 4

    /// The bar keeps the same length for any number of slides, and the segments divide it. A
    /// fixed segment height instead makes the bar grow past the screen when the review is long.
    private static let barHeight: CGFloat = 180

    private static let upcomingSegmentOpacity: Double = 0.3

    var body: some View {
        if slideCount > 1 {
            VStack(spacing: Self.segmentSpacing) {
                // `ForEach` takes an array, not a range. A range initializer accepts only a
                // constant range, and the slides come from a published property.
                ForEach(Array(0..<slideCount), id: \.self) { index in
                    Capsule()
                        .fill(color)
                        .opacity(index <= currentIndex ? 1 : Self.upcomingSegmentOpacity)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: Self.barWidth, height: Self.barHeight)
            .animation(.easeInOut(duration: 0.2), value: currentIndex)
            // The reader who uses VoiceOver gets the position from the value on the pager. The
            // bar repeats it, so it stays out of the accessibility tree.
            .accessibilityHidden(true)
        }
    }
}
