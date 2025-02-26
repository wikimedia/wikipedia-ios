import SwiftUI
import WMFData

public struct WMFTempAccountsToastView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFTempAccountsToastViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public init(viewModel: WMFTempAccountsToastViewModel) {
        self.viewModel = viewModel
    }

    private func subtitleAttributedString() -> AttributedString {
        return (try? AttributedString(markdown: viewModel.title)) ?? AttributedString(viewModel.title)
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            if let xCircleFill = WMFSFSymbolIcon.for(symbol: .xCircleFill) {
                Button(action: {
                    viewModel.didTapClose()
                }) {
                    Image(uiImage: xCircleFill)
                        .foregroundStyle(Color(theme.newBorder))
                        .frame(width: 15)
                }
                .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    if let exclamationPointCircle = WMFIcon.exclamationPointCircle {
                        Image(uiImage: exclamationPointCircle)
                            .foregroundStyle(Color(theme.editorMatchForeground))
                            .frame(width: 15)
                    }
                    Text(subtitleAttributedString())
                        .lineLimit(2)
                }
                WMFSmallButton(configuration: WMFSmallButton.Configuration(style: .quiet), title: viewModel.readMoreButtonTitle, action: {
                    viewModel.didTapReadMore()
                })
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Divider()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .ignoresSafeArea()
        .background(Color(theme.midBackground))
    }
}
