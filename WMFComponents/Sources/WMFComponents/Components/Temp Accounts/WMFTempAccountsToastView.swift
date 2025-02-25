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
    
    private var titleStyles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WMFFont.for(.subheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.subheadline), boldItalicsFont: WMFFont.for(.subheadline), color: theme.text, linkColor: theme.link, lineSpacing: 1)
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            if let xCircleFill = WMFSFSymbolIcon.for(symbol: .xCircleFill) {
                Image(uiImage: xCircleFill)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    if let exclamationPointCircle = WMFIcon.exclamationPointCircle {
                        Image(uiImage: exclamationPointCircle)
                            .foregroundStyle(Color(theme.editorMatchForeground))
                    }
                    WMFHtmlText(html: viewModel.title, styles: titleStyles)
                        .lineLimit(2)
                }
                WMFSmallButton(configuration: WMFSmallButton.Configuration(style: .neutral), title: viewModel.readMoreButtonTitle, action: {
                    viewModel.didTapReadMore()
                })
            }
            .padding(.vertical, 12)
            Divider()
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea()
        .background(Color(theme.midBackground))
    }
}
