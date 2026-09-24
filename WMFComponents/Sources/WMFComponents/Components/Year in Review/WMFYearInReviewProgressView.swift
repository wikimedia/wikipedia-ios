import SwiftUI

/// Shows the position in the review as one thin bar on the trailing edge of the slide.

struct WMFYearInReviewProgressView: View {

    let slideCount: Int
    let currentIndex: Int
    let color: Color

    private static let barWidth: CGFloat = 3
    private static let segmentSpacing = WMFSpacing.xSmall

    /// The bar keeps the same length for any number of slides, and the segments divide it
    private static let barHeight: CGFloat = 180

    private static let upcomingSegmentOpacity: Double = 0.3

    var body: some View {
        if slideCount > 1 {
            VStack(spacing: Self.segmentSpacing) {
                ForEach(0..<slideCount, id: \.self) { index in
                    Capsule()
                        .fill(color)
                        .opacity(index <= currentIndex ? 1 : Self.upcomingSegmentOpacity)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: Self.barWidth, height: Self.barHeight)
            .animation(.easeInOut(duration: 0.2), value: currentIndex)
            // The reader who uses VoiceOver gets the position from the value on the pager
            .accessibilityHidden(true)
        }
    }
}
