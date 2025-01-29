import SwiftUI
import WMFData

public struct WMFTempAccountsSheetView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFTempAccountsSheetViewModel
    @Environment(\.dismiss) private var dismiss

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public init(viewModel: WMFTempAccountsSheetViewModel) {
        self.viewModel = viewModel
    }
    
    private var subtitleStyles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WMFFont.for(.subheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.subheadline), boldItalicsFont: WMFFont.for(.subheadline), color: theme.text, linkColor: theme.link, lineSpacing: 1)
    }
    
    var closeImage: Image? {
        if let uiImage = WMFSFSymbolIcon.for(symbol: .closeCircleFill, font: .title1) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    public var body: some View {
        VStack {
            Button(
                action: {
                    dismiss()
                },
                label: {
                    Text(viewModel.done)
                        .font(Font(WMFFont.navigationBarDoneButtonFont))
                        .foregroundColor(Color(theme.navigationBarTintColor))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                })
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            VStack(spacing: 17) {
                VStack(spacing: 22) {
                    Image(viewModel.image, bundle: .module)
                    textInfo
                }
                WMFLargeButton(configuration: .primary, title: viewModel.ctaTopString, action: {
                    // TODO
                })
                .frame(maxWidth: .infinity)
                WMFLargeButton(configuration: .secondary, title: viewModel.ctaBottomString, action: {
                    // TODO
                })
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 51)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: theme.midBackground))
        .environment(\.colorScheme, theme.preferredColorScheme)
        .environment(\.openURL, OpenURLAction { url in
            viewModel.handleURL(url)
            return .handled
        })
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
