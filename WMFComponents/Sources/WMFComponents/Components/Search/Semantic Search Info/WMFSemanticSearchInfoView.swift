import SwiftUI

public struct WMFSemanticSearchInfoView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSemanticSearchInfoViewModel
    private let fittingHeightDidChange: (CGFloat) -> Void

    @State private var scrollContentHeight: CGFloat = 0
    @State private var learnMoreHeight: CGFloat = 0

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    /// `fittingHeightDidChange` receives the height the content needs, without the navigation
    /// bar and the bottom safe area, so the sheet can fit it.
    public init(viewModel: WMFSemanticSearchInfoViewModel, fittingHeightDidChange: @escaping (CGFloat) -> Void = { _ in }) {
        self.viewModel = viewModel
        self.fittingHeightDidChange = fittingHeightDidChange
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WMFSpacing.xLarge) {
                description
                example
            }
            .padding(WMFSpacing.large)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { scrollContentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            learnMoreButton
                .padding(WMFSpacing.large)
                .background(Color(theme.paperBackground))
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { learnMoreHeight = $0 }
        }
        .onChange(of: scrollContentHeight + learnMoreHeight) { _, height in
            fittingHeightDidChange(height)
        }
        .environment(\.layoutDirection, viewModel.isRightToLeft ? .rightToLeft : .leftToRight)
        .background(Color(theme.paperBackground))
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchInfoView)
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: WMFSpacing.xLarge) {
            Text(viewModel.summary)
            Text(viewModel.sourcesDescription)
        }
        .font(Font(WMFFont.for(.callout)))
        .foregroundStyle(Color(theme.text))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var example: some View {
        VStack(alignment: .leading, spacing: WMFSpacing.large) {
            HStack(alignment: .firstTextBaseline, spacing: WMFSpacing.small) {
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .magnifyingGlass, font: .semiboldTitle3) ?? UIImage())
                    .foregroundStyle(Color(theme.text))
                    .accessibilityHidden(true)
                Text(viewModel.exampleQuery)
                    .font(Font(WMFFont.for(.semiboldTitle3)))
                    .foregroundStyle(Color(theme.text))
            }
            // The example shows a result only. It does not open the article.
            WMFSemanticSearchResultCardView(viewModel: viewModel.exampleResult)
                .allowsHitTesting(false)
                .accessibilityRemoveTraits(.isButton)
        }
    }

    private var learnMoreButton: some View {
        Button(action: viewModel.learnMore) {
            HStack(spacing: WMFSpacing.xSmall) {
                Text(viewModel.learnMoreTitle)
                    .font(Font(WMFFont.for(.body)))
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .arrowUpForward, font: .body) ?? UIImage())
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(CapsuleButtonStyle(kind: .neutral, theme: theme, height: 50))
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchInfoLearnMoreButton)
    }
}
