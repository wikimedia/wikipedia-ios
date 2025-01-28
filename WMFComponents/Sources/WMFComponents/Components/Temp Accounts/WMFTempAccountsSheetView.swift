import SwiftUI
import WMFData

public struct WMFTempAccountsSheetView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFTempAccountsSheetViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public init(viewModel: WMFTempAccountsSheetViewModel) {
        self.viewModel = viewModel
    }
    
    private var subtitleStyles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WMFFont.for(.subheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.subheadline), boldItalicsFont: WMFFont.for(.subheadline), color: theme.text, linkColor: theme.link, lineSpacing: 1)
    }
    
    public var body: some View {
        VStack(spacing: 17) {
            VStack(spacing: 22) {
                Image(viewModel.image, bundle: .module)
                textInfo
            }
            WMFLargeButton(configuration: .primary, title: viewModel.ctaTopString, action: {
                print("First CTA pressed")
            })
            .frame(maxWidth: .infinity)
            WMFLargeButton(configuration: .secondary, title: viewModel.ctaBottomString, action: {
                print("Second CTA pressed")
            })
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 51)
        .background(Color(uiColor: theme.midBackground))
        .environment(\.colorScheme, theme.preferredColorScheme)
    }
    
    private var textInfo: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(viewModel.title)
                .font(Font(WMFFont.for(.boldTitle1)))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            WMFHtmlText(html: viewModel.subtitle, styles: subtitleStyles)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}
