import SwiftUI

public protocol WMFEmptyViewDelegate: AnyObject {
    func emptyViewDidTapMainAction()
    func emptyViewDidTapFilters()
    func emptyViewDidShow(type: WMFEmptyViewStateType)
}

public struct WMFEmptyView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFEmptyViewModel
    weak var delegate: WMFEmptyViewDelegate?
    var type: WMFEmptyViewStateType
    let isScrollable: Bool

    /// The reader's text size setting, read before this view's own cap below, so it reflects what
    /// the reader asked for rather than what the view granted.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Overrides the app theme. The For You feed is always dark whatever theme the app is set to,
    /// so it passes its own palette rather than following `WMFAppEnvironment`.
    var theme: WMFTheme?

    /// An alternative to `delegate.emptyViewDidTapMainAction`, for SwiftUI callers that cannot be a
    /// delegate because they are value types.
    var mainAction: (() -> Void)?

    /// Draws the action button hugging its title instead of filling the width.
    ///
    /// Defaults to false, so the existing empty states keep the full width button they were
    /// designed around.
    var usesCompactButton: Bool = false

    private var resolvedTheme: WMFTheme {
        theme ?? appEnvironment.theme
    }

    var foregroundColor: Color? {
        if let imageColor = viewModel.imageColor {
            return Color(uiColor: imageColor)
        }

        return nil
    }

    public var body: some View {
        if isScrollable {
            scrollableContent
        } else if dynamicTypeSize.isAccessibilitySize {
            // Even with the size cap below, long copy can outgrow a small screen at accessibility
            // sizes. Scrolling keeps every line and the button reachable instead of clipping them
            // behind the tab bar. Unlike `scrollableContent`, this adds no background and no
            // horizontal padding, so non-scrollable callers keep the appearance they designed for.
            GeometryReader { geometry in
                ScrollView {
                    content
                        .frame(minHeight: geometry.size.height)
                }
            }
        } else {
            content
        }
    }

    private var scrollableContent: some View {
        GeometryReader { geometry in
            ZStack {
                Color(resolvedTheme.midBackground)
                    .ignoresSafeArea()
                ScrollView {
                    content
                    .frame(minHeight: geometry.size.height)
                    .padding([.leading, .trailing], 32)
                }
            }
        }
    }

    private var content: some View {
        VStack {
            Spacer()
            if let image = viewModel.image {
                if let imageSize = viewModel.imageSize {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageSize.width, height: imageSize.height)
                        .foregroundColor(foregroundColor)
                } else {
                    Image(uiImage: image)
                        .foregroundColor(foregroundColor)
                }
            }
            Text(viewModel.localizedStrings.title)
                .font(Font(WMFFont.for(.boldCallout)))
                .foregroundColor(Color(resolvedTheme.text))
                .padding([.top], 12)
                .padding([.bottom], 8)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
            if let attributedString = viewModel.filterString(localizedStrings: viewModel.localizedStrings),
               type == .filter {
                WMFEmptyViewFilterView(delegate: delegate, attributedString: attributedString)
            } else {
                WMFHtmlText(html: viewModel.localizedStrings.subtitle, styles: subheadlineStyles)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundColor(Color(resolvedTheme.secondaryText))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
            }
            if let buttonTitle = viewModel.localizedStrings.buttonTitle,
               type == .noItems {
                let buttonAction = mainAction ?? delegate?.emptyViewDidTapMainAction
                if usesCompactButton {
                    WMFSmallButton(configuration: .init(style: .primary), title: buttonTitle, action: buttonAction)
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                        .minimumScaleFactor(0.5)
                } else {
                    WMFLargeButton(style: .primary, title: buttonTitle, action: buttonAction)
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                        .minimumScaleFactor(0.5)
                }
            }
            Spacer()
        }
        // The empty states are a short message and a button, not reading content, so the largest
        // accessibility sizes gain nothing over a bounded large size - while a title at those
        // sizes breaks mid-word and pushes the message off the screen. The cap keeps the text
        // growing into the accessibility range, but stops it while a sentence still fits a screen.
        .dynamicTypeSize(.xSmall ... .accessibility2)
        .onAppear {
            delegate?.emptyViewDidShow(type: type)
        }
    }

    private var subheadlineStyles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.subheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.italicSubheadline), boldItalicsFont: WMFFont.for(.boldItalicSubheadline), color: resolvedTheme.text, linkColor: resolvedTheme.link, lineSpacing: 1)
    }
}

struct WMFEmptyViewFilterView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    weak var delegate: WMFEmptyViewDelegate?
    let attributedString: AttributedString

    var body: some View {

        Text(attributedString)
            .font(Font(WMFFont.for(.subheadline)))
            .padding(2)
            .foregroundColor(Color(appEnvironment.theme.secondaryText))
            .frame(height: 30)
            .environment(\.openURL, OpenURLAction { url in
                    delegate?.emptyViewDidTapFilters()
                    return .handled
                })
    }
}
