import Combine
import SwiftUI

/// Shows the position in the review as one thumb that moves down the trailing edge of the slide,
/// from the first page at the top to the last page at the bottom. It follows the finger during a swipe.
/// The fill is white and the border is black, so that it shows on light and dark slides.
struct WMFYearInReviewProgressView: View {

    let pageCount: Int
    let position: CurrentValueSubject<CGFloat, Never>

    private static let thumbWidth: CGFloat = 3
    private static let thumbHeight: CGFloat = 28
    private static let borderWidth: CGFloat = 0.5

    @State private var currentPosition: CGFloat = 0

    var body: some View {
        if pageCount > 1 {
            GeometryReader { geometry in
                thumb
                    .offset(y: (geometry.size.height - Self.thumbHeight) * progress)
            }
            .frame(width: Self.thumbWidth)
            .onAppear {
                currentPosition = position.value
            }
            .onReceive(position) { newPosition in
                currentPosition = newPosition
            }
            .allowsHitTesting(false)
            // The reader who uses VoiceOver gets the position from the value on the pager
            .accessibilityHidden(true)
        }
    }

    /// The border is inside the shape, so that it does not make the thumb larger.
    private var thumb: some View {
        Capsule()
            .fill(Color(uiColor: WMFColor.white))
            .overlay {
                Capsule()
                    .strokeBorder(Color(uiColor: WMFColor.black), lineWidth: Self.borderWidth)
            }
            .frame(width: Self.thumbWidth, height: Self.thumbHeight)
    }

    /// 0 on the first page and 1 on the last page. The bounce past either end does not move the thumb past the track.
    private var progress: CGFloat {
        let lastPage = CGFloat(pageCount - 1)
        return min(max(currentPosition, 0), lastPage) / lastPage
    }
}
