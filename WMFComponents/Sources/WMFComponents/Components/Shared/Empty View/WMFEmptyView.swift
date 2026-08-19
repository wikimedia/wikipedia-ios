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
            if let attributedString = viewModel.filterString(localizedStrings: viewModel.localizedStrings),
               type == .filter {
                WMFEmptyViewFilterView(delegate: delegate, attributedString: attributedString)
            } else {
                Text(viewModel.localizedStrings.subtitle)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundColor(Color(resolvedTheme.secondaryText))
                    .multilineTextAlignment(.center)
            }
            if let buttonTitle = viewModel.localizedStrings.buttonTitle,
               type == .noItems {
                let buttonAction = mainAction ?? delegate?.emptyViewDidTapMainAction
                if usesCompactButton {
                    WMFSmallButton(configuration: .init(style: .primary), title: buttonTitle, action: buttonAction)
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                } else {
                    WMFLargeButton(style: .primary, title: buttonTitle, action: buttonAction)
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                }
            }
            Spacer()
        }
        .onAppear {
            delegate?.emptyViewDidShow(type: type)
        }
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
