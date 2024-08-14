import SwiftUI

public struct WMFAltTextExperimentPreviewView: View {

    let viewModel: WMFAltTextExperimentPreviewViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

        var attributedString: AttributedString? {
            if let finePrint = try? AttributedString(markdown: viewModel.localizedStrings.footerText, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                return finePrint
            }
            return AttributedString(viewModel.localizedStrings.footerText)
        }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading) {
                    Image(uiImage: viewModel.image)
                        .frame(width: UIScreen.main.bounds.size.width, height: 300)
                        .aspectRatio(contentMode: .fit)
                    WMFAltTextPreviewCell(title: viewModel.localizedStrings.altTextTitle, subtitle: viewModel.altText, theme: appEnvironment.theme)
                    if let caption = viewModel.caption {
                        WMFAltTextPreviewCell(title: viewModel.localizedStrings.altTextTitle, subtitle: caption, theme: appEnvironment.theme)
                    }
                }
                Spacer()
                    .frame(idealHeight: geometry.size.height/5)
                HStack {
                    Image("license-cc")
                        .renderingMode(.template)
                        .colorMultiply(Color(appEnvironment.theme.secondaryText))
                        .padding([.trailing], 12)
                    if let attributedString {
                        Text(attributedString)
                            .font(Font(WMFFont.for(.footnote)))
                            .foregroundColor(Color(appEnvironment.theme.secondaryText))
                            .multilineTextAlignment(.leading)
                    } else {
                        Text(viewModel.localizedStrings.footerText)
                            .font(Font(WMFFont.for(.footnote)))
                            .foregroundColor(Color(appEnvironment.theme.secondaryText))
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(16)
            }
        }
    }
}

struct WMFAltTextPreviewCell: View {
    let title: String
    let subtitle: String

    var theme: WMFTheme

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(Color(theme.secondaryText))
                .multilineTextAlignment(.leading)
            Text(subtitle)
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(Color(theme.text))
                .multilineTextAlignment(.leading)
        }
        .padding(12)
    }
}
