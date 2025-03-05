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
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    if let exclamationPointCircle = WMFIcon.exclamationPointCircle {
                        Image(uiImage: exclamationPointCircle)
                            .resizable()
                            .foregroundStyle(Color(theme.text))
                            .frame(width: 16, height: 16)
                    }
                    Text(subtitleAttributedString())
                        .lineLimit(2)
                        .lineSpacing(titleStyles.lineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(Color(theme.text))
                }
                Group {
                    WMFSmallButton(configuration: WMFSmallButton.Configuration(style: .quiet), title: viewModel.readMoreButtonTitle, action: {
                        viewModel.didTapReadMore()
                    })
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            Divider()
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .background(Color(theme.midBackground))
    }
}
