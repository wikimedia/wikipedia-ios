import SwiftUI

public struct WMFSimpleEmptyStateView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme {
        return appEnvironment.theme
    }

    private let imageName: String
    private var openCustomize: () -> Void
    private let title: String
    
    public init(imageName: String, openCustomize: @escaping () -> Void, title: String) {
        self.imageName = imageName
        self.openCustomize = openCustomize
        self.title = title
    }

    public var body: some View {
        VStack {
            Spacer()
            if let image = UIImage(named: imageName, in: .module, with: nil) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 132, height: 118)
            }
            WMFHtmlText(html: title, styles: summaryStyles)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .multilineTextAlignment(.center)
                .overlay(
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            openCustomize()
                        }
                )
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(Color(uiColor: theme.paperBackground))
    }
    
    private var summaryStyles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.subheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.italicSubheadline), boldItalicsFont: WMFFont.for(.boldItalicSubheadline), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
}
