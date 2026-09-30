import SwiftUI

public struct WMFSemanticSearchFeedbackView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSemanticSearchFeedbackViewModel
    @FocusState private var isTextFieldFocused: Bool
    /// The card's content height at the width it's laid out at, so its sheet can fit it.
    var onCardHeightChange: ((CGFloat) -> Void)?

    private static let thumbButtonSize: CGFloat = 44
    private static let textFieldMinHeight: CGFloat = 64

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    // Matches the passage cards, which sit on the paper color on sepia for contrast.
    private var bannerBackground: UIColor {
        theme == .sepia ? theme.paperBackground : theme.midBackground
    }

    public init(viewModel: WMFSemanticSearchFeedbackViewModel) {
        self.viewModel = viewModel
    }

    init(viewModel: WMFSemanticSearchFeedbackViewModel, onCardHeightChange: @escaping (CGFloat) -> Void) {
        self.viewModel = viewModel
        self.onCardHeightChange = onCardHeightChange
    }

    public var body: some View {
        switch viewModel.style {
        case .inline:
            inline
        case .card:
            card
        }
    }

    // MARK: - Styles

    private var inline: some View {
        VStack(alignment: .leading, spacing: WMFSpacing.medium) {
            questionRow
            if viewModel.isTextFieldVisible {
                textField
                submitButton
            }
        }
        .padding(.horizontal, WMFSpacing.large)
        .padding(.top, WMFSpacing.small)
        .padding(.bottom, viewModel.isTextFieldVisible ? WMFSpacing.large : WMFSpacing.small)
        .background(Color(bannerBackground))
        .clipShape(RoundedRectangle(cornerRadius: WMFCornerRadius.xLarge))
        .animation(.default, value: viewModel.isTextFieldVisible)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchFeedback)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: WMFSpacing.medium) {
            cardHeader
            questionRow
            textField
            submitButton
                .padding(.top, WMFSpacing.small)
        }
        .padding(.horizontal, WMFSpacing.large)
        .padding(.vertical, WMFSpacing.large)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            onCardHeightChange?(height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(theme.paperBackground))
        // The sheet moves above the keyboard itself. Without this the keyboard inset would grow
        // the preferred content size, and the sheet with it.
        .ignoresSafeArea(.keyboard)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchFeedback)
    }

    // MARK: - Content

    private var cardHeader: some View {
        ZStack {
            Text(viewModel.title)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundStyle(Color(theme.text))
                .accessibilityAddTraits(.isHeader)
            HStack {
                WMFLargeCloseButton(imageType: .plainX) {
                    viewModel.close()
                }
                .accessibilityLabel(viewModel.closeAccessibilityLabel)
                .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchFeedbackCloseButton)
                Spacer()
            }
        }
    }

    private var questionRow: some View {
        HStack(spacing: WMFSpacing.xSmall) {
            Text(viewModel.question)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundStyle(Color(theme.text))
                .frame(maxWidth: .infinity, alignment: .leading)
            thumbButton(for: .positive)
            thumbButton(for: .negative)
        }
    }

    private func thumbButton(for rating: WMFSemanticSearchFeedbackViewModel.Rating) -> some View {
        let isSelected = viewModel.rating == rating
        let symbol: WMFSFSymbolIcon = rating == .positive ? .handThumbsUp : .handThumbsDown

        return Button {
            viewModel.rate(rating)
        } label: {
            if let image = WMFSFSymbolIcon.for(symbol: symbol, font: .body) {
                Image(uiImage: image)
                    .renderingMode(.template)
                    .foregroundStyle(Color(theme.text))
                    .frame(width: Self.thumbButtonSize, height: Self.thumbButtonSize)
                    .background(
                        Circle()
                            .fill(Color(isSelected ? theme.baseBackground : .clear))
                    )
                    .contentShape(Circle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(rating == .positive ? viewModel.thumbsUpAccessibilityLabel : viewModel.thumbsDownAccessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(rating == .positive ? AccessibilityIdentifiers.Search.semanticSearchFeedbackThumbsUpButton : AccessibilityIdentifiers.Search.semanticSearchFeedbackThumbsDownButton)
    }

    private var textField: some View {
        TextField(
            "",
            text: $viewModel.text,
            prompt: Text(viewModel.placeholder).foregroundColor(Color(theme.secondaryText)),
            axis: .vertical
        )
        .font(Font(WMFFont.for(.callout)))
        .foregroundStyle(Color(theme.text))
        .tint(Color(theme.link))
        .lineLimit(1...4)
        .focused($isTextFieldFocused)
        .onChange(of: isTextFieldFocused) { _, isFocused in
            viewModel.isTextFieldFocused = isFocused
        }
        .onChange(of: viewModel.isTextFieldFocused) { _, isFocused in
            isTextFieldFocused = isFocused
        }
        .padding(.horizontal, WMFSpacing.large)
        .padding(.vertical, WMFSpacing.medium)
        .frame(minHeight: Self.textFieldMinHeight, alignment: .leading)
        .background(Color(theme.baseBackground))
        .clipShape(RoundedRectangle(cornerRadius: WMFCornerRadius.xLarge))
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = true
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchFeedbackTextField)
    }

    private var submitButton: some View {
        WMFLargeButton(style: .primary, title: viewModel.submitTitle) {
            isTextFieldFocused = false
            viewModel.submit()
        }
        .disabled(!viewModel.canSubmit)
        .opacity(viewModel.canSubmit ? 1 : 0.5)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchFeedbackSubmitButton)
    }
}
