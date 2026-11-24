import SwiftUI

/// A thumbs up or thumbs down button. The Dive feedback card and the feedback row of the interleaved result cards share it.
struct WMFSemanticSearchFeedbackThumbButton: View {

    static let size: CGFloat = 48
    static let iconSize: CGFloat = 20

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let rating: WMFSemanticSearchFeedbackViewModel.Rating
    let isSelected: Bool
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let action: () -> Void

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    private var symbol: WMFSFSymbolIcon {
        switch (rating, isSelected) {
        case (.positive, false): return .handThumbsUp
        case (.positive, true): return .handThumbsUpFill
        case (.negative, false): return .handThumbsDown
        case (.negative, true): return .handThumbsDownFill
        }
    }

    var body: some View {
        Button(action: action) {
            if let image = WMFSFSymbolIcon.for(symbol: symbol, font: .body) {
                Image(uiImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color(theme.text))
                    .frame(width: Self.iconSize, height: Self.iconSize)
                    .frame(width: Self.size, height: Self.size)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(WMFSemanticSearchFeedbackThumbButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

/// Draws the label as it is, with no dimming or press effect. A card takes one vote, and the view model ignores a second tap.
private struct WMFSemanticSearchFeedbackThumbButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
