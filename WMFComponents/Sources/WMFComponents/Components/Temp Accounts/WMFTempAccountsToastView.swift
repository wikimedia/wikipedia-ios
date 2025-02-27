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
        return (try? HtmlUtils.attributedStringFromHtml(viewModel.title, styles: titleStyles)) ?? AttributedString(viewModel.title)
    }
    
    private var titleStyles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WMFFont.for(.callout), boldFont: WMFFont.for(.boldCallout), italicsFont: WMFFont.for(.italicCallout), boldItalicsFont: WMFFont.for(.boldItalicCallout), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if let xCircleFill = WMFIcon.closeCircleInverse {
                Button(action: {
                    viewModel.didTapClose()
                }) {
                    Image(uiImage: xCircleFill)
                        .resizable()
                        .frame(width: 30, height: 30)
//                        .foregroundStyle(Color(theme.icon))
//                        .tint(Color(theme.iconBackground))
                }
                .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
            VStack(spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    if let exclamationPointCircle = WMFIcon.exclamationPointCircle {
                        Image(uiImage: exclamationPointCircle)
                            .resizable()
                            .foregroundStyle(Color(theme.editorMatchForeground))
                            .frame(width: 16, height: 16)
                    }
                    Text(subtitleAttributedString())
                        .lineLimit(2)
                        .lineSpacing(titleStyles.lineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
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
        .background(Color(theme.paperBackground))
    }
}
