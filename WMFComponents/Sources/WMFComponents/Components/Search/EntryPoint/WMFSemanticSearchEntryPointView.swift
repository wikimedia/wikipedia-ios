import SwiftUI

public struct WMFSemanticSearchEntryPointView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSemanticSearchEntryPointViewModel
    @Environment(\.displayScale) private var displayScale

    let horizontalPadding: CGFloat

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFSemanticSearchEntryPointViewModel, horizontalPadding: CGFloat = 16) {
        self.viewModel = viewModel
        self.horizontalPadding = horizontalPadding
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                headerRow
                Button {
                    viewModel.tap()
                } label: {
                    content
                }
                .buttonStyle(.plain)
            }
            .padding(EdgeInsets(top: 12, leading: horizontalPadding, bottom: 12, trailing: horizontalPadding))
            Divider()
                .background(Color(theme.border))
                .frame(height: max(1.0 / displayScale, 0.5))
        }
        .background(Color(theme.paperBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.tap()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(viewModel.accessibilityHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            viewModel.tap()
        }
        .accessibilityAction(named: Text(viewModel.infoAccessibilityLabel)) {
            viewModel.showInfo()
        }
        .accessibilityAction(named: Text(viewModel.hideAccessibilityLabel)) {
            viewModel.hide()
        }
    }

    private var accessibilityLabel: Text {
        var parts = [viewModel.betaLabel, viewModel.query, viewModel.description]
        if viewModel.showsTryItNow {
            parts.append(viewModel.tryItNowTitle)
        }
        return Text(parts.joined(separator: ", "))
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            WMFBetaBadge(label: viewModel.betaLabel)
            Button {
                viewModel.showInfo()
            } label: {
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .infoCircle) ?? UIImage())
                    .foregroundStyle(Color(theme.secondaryText))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.infoAccessibilityLabel)
            .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchEntryPointInfoButton)
            Spacer(minLength: 0)
            Button {
                viewModel.hide()
            } label: {
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .close) ?? UIImage())
                    .foregroundStyle(Color(theme.link))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.hideAccessibilityLabel)
            .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchEntryPointHideButton)
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.query)
                    .font(Font(WMFFont.for(.boldCallout)))
                    .foregroundStyle(Color(theme.text))
                    .lineLimit(2)
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.description)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(Color(theme.secondaryText))
                    if viewModel.showsTryItNow {
                        Text(viewModel.tryItNowTitle)
                            .font(Font(WMFFont.for(.mediumSubheadline)))
                            .foregroundStyle(Color(theme.link))
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            if let illustration = UIImage(named: "semantic-search-entry-point", in: Bundle.module, compatibleWith: nil) {
                Image(uiImage: illustration)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 75)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
    }
}
