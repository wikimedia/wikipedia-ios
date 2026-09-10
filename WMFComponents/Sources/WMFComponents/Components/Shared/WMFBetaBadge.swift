import SwiftUI
import WMFNativeLocalizations

public struct WMFBetaBadge: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    public init() {}

    public var body: some View {
        HStack(spacing: 4) {
            if let betaImage = WMFSFSymbolIcon.for(symbol: .flask, font: WMFFont.caption1) {
                Image(uiImage: betaImage)
            }
            Text(CommonStrings.betaLabel)
                .font(Font(WMFFont.for(.caption1)))
        }
        .foregroundColor(Color(appEnvironment.theme.text))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().stroke(Color(appEnvironment.theme.baseBackground), lineWidth: 1))
    }
}
