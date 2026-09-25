import SwiftUI
import WMFNativeLocalizations

public struct WMFBetaBadge: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let label: String

    public init(label: String = CommonStrings.betaLabel()) {
        self.label = label
    }

    public var body: some View {
        HStack(spacing: WMFSpacing.xSmall) {
            if let betaImage = WMFSFSymbolIcon.for(symbol: .flask, font: WMFFont.caption1) {
                Image(uiImage: betaImage)
                    .foregroundColor(Color(appEnvironment.theme.secondaryText))
            }
            Text(label)
                .font(Font(WMFFont.for(.caption1)))
                .foregroundColor(Color(appEnvironment.theme.text))
        }
        .padding(.horizontal, WMFSpacing.small)
        .padding(.vertical, WMFSpacing.xSmall)
        .overlay(Capsule().strokeBorder(Color(appEnvironment.theme.newBorder), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}
