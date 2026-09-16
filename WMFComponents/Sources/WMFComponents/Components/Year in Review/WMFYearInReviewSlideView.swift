import SwiftUI

struct WMFYearInReviewSlideView: View {

    let slide: WMFYearInReviewSlideViewModel

    var body: some View {
        ZStack {
            Color(uiColor: slide.backgroundColor)
                .ignoresSafeArea()

            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if let animation = slide.animation {
            WMFRiveView(
                animation,
                text: slide.text,
                numbers: slide.numbers,
                accessibilityLabel: slide.localizedStrings.accessibilityLabel
            )
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Text(slide.id)
                .font(Font(WMFFont.for(.boldTitle1)))
            Text("no .riv yet")
                .font(Font(WMFFont.for(.caption1)))
                .opacity(0.6)
        }
        .foregroundStyle(Color(uiColor: slide.contentColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }
}
