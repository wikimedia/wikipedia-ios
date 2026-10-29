import SwiftUI
import WMFData
import WMFNativeLocalizations

/// The Discover setup screen: a question, one row per source and a Continue button pinned to the
/// bottom. The rows scroll under the button at large text sizes, as the designer asked.
public struct WMFDiscoverSetupView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFDiscoverSetupViewModel

    static let title = WMFLocalizedString("discover-setup-title", value: "How should we build your recommended reading list?", comment: "Title of the Discover setup screen, where the reader chooses how the recommended reading list picks its articles.")
    private let interestsTitle = WMFLocalizedString("discover-setup-source-interests", value: "Let me choose based on my interests", comment: "Option on the Discover setup screen. The reader picks interests and the recommended reading list is built from them.")
    private let savedTitle = WMFLocalizedString("discover-setup-source-saved", value: "Choose for me based on my saved articles", comment: "Option on the Discover setup screen. The recommended reading list is built from the reader's saved articles.")
    private let historyTitle = WMFLocalizedString("discover-setup-source-history", value: "Choose for me based on my reading history", comment: "Option on the Discover setup screen. The recommended reading list is built from the reader's reading history.")
    private let continueTitle = CommonStrings.continueButton

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    /// Every row is at least as tall as a two-line title, so one-line rows match the others.
    private var twoLineHeight: CGFloat {
        WMFFont.for(.body).lineHeight * 2
    }

    public init(viewModel: WMFDiscoverSetupViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WMFSpacing.xLarge) {
                Text(Self.title)
                    .font(Font(WMFFont.for(.boldTitle1)))
                    .foregroundColor(Color(uiColor: theme.text))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                sourceList
            }
            .padding(.horizontal, WMFSpacing.large)
            .padding(.top, WMFSpacing.large)
            .readableWidth()
        }
        .safeAreaInset(edge: .bottom) {
            WMFLargeButton(style: .primary, title: continueTitle) {
                viewModel.tapContinue()
            }
            .padding(.horizontal, WMFSpacing.large)
            .padding(.vertical, WMFSpacing.large)
            .readableWidth()
            .accessibilityIdentifier(AccessibilityIdentifiers.Discover.setupContinueButton)
        }
        .background(Color(uiColor: theme.paperBackground))
        .accessibilityIdentifier(AccessibilityIdentifiers.Discover.setupView)
        .onAppear {
            viewModel.viewDidAppear()
        }
    }

    private var sourceList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.availableSources.enumerated()), id: \.element) { index, source in
                if index > 0 {
                    Divider()
                        .overlay(Color(uiColor: theme.border))
                        .padding(.horizontal, WMFSpacing.large)
                }
                sourceRow(source)
            }
        }
        .background(Color(uiColor: theme.midBackground))
        .clipShape(RoundedRectangle(cornerRadius: WMFCornerRadius.xxxLarge))
    }

    private func sourceRow(_ source: WMFDiscoverSource) -> some View {
        let isSelected = viewModel.selectedSource == source
        return Button {
            viewModel.select(source)
        } label: {
            HStack(spacing: WMFSpacing.medium) {
                if let uiImage = WMFSFSymbolIcon.for(symbol: symbol(for: source), font: .body) {
                    Image(uiImage: uiImage)
                        .foregroundColor(Color(uiColor: theme.secondaryText))
                        .accessibilityHidden(true)
                }
                Text(title(for: source))
                    .font(Font(WMFFont.for(.body)))
                    .foregroundColor(Color(uiColor: theme.text))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: WMFSpacing.large)
                WMFCheckmarkView(isSelected: true, configuration: WMFCheckmarkView.Configuration(style: .default, font: .semiboldHeadline))
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: twoLineHeight)
            .padding(.horizontal, WMFSpacing.large)
            .padding(.vertical, WMFSpacing.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier(AccessibilityIdentifiers.Discover.setupSourceRow(source.rawValue))
    }

    private func symbol(for source: WMFDiscoverSource) -> WMFSFSymbolIcon {
        switch source {
        case .interests:
            return .sliderHorizontal3
        case .saved:
            return .bookmark
        case .history:
            return .clockArrowTriangleheadCounterclockwiseRotate90
        }
    }

    private func title(for source: WMFDiscoverSource) -> String {
        switch source {
        case .interests:
            return interestsTitle
        case .saved:
            return savedTitle
        case .history:
            return historyTitle
        }
    }
}
