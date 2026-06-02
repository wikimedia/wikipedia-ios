import SwiftUI
import UIKit

public struct WMFWhichCameFirstCardView: View {

    @ObservedObject private var viewModel: WMFWhichCameFirstCardViewModel
    @ObservedObject private var parentViewModel: WMFWhichCameFirstViewModel
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current

    @Environment(\.horizontalSizeClass) private var sizeClass

    let cardHeight: CGFloat
    let onTap: (() -> Void)?

    public init(viewModel: WMFWhichCameFirstCardViewModel, parentViewModel: WMFWhichCameFirstViewModel, cardHeight: CGFloat = 192, onTap: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.cardHeight = cardHeight
        self.onTap = onTap
        self.parentViewModel = parentViewModel
    }

    private var theme: WMFTheme { appEnvironment.theme }

    // MARK: - Color helpers

    private var revealColor: Color {
        if viewModel.isSelectedCardCorrect {
            return Color(uiColor: WMFColor.green700)
        } else if viewModel.isSelected {
            return Color(uiColor: WMFColor.red700)
        } else {
            return Color(uiColor: theme.secondaryText)
        }
    }

    /// The ✕ is always red; the ✓ is always green.
    private var iconColor: Color {
        viewModel.isSelectedCardCorrect
            ? Color(uiColor: WMFColor.green700)
        : Color(uiColor: WMFColor.red700)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            cardContent

            if viewModel.isRevealed {
                datePill
                    .offset(y: 10)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isRevealed)
        .animation(.easeInOut(duration: 0.18), value: viewModel.isSelected)
        .modifier(CardHeightModifier(isRegular: sizeClass == .regular, cardHeight: cardHeight))
    }

    private var cardContent: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    eventText
                    thumbnailView
                }
                .padding(16)
            }

            if viewModel.isRevealed && (viewModel.isSelected || !viewModel.isSelectedCardCorrect && viewModel.isSelected) {
                resultIcon
                    .padding([.bottom, .trailing], 12)
            }
        }
        .background(Color(uiColor: theme.paperBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(viewModel.isSelected ? Color(uiColor: theme.text) : Color.clear)
        )
        .shadow(
            color: viewModel.isSelected ? .clear : Color(uiColor: theme.text).opacity(0.05),
            radius: 8,
            x: 0,
            y: 0
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard !viewModel.isRevealed else { return }
            onTap?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(viewModel.isRevealed ? .isButton : [])
    }

    private var accessibilityDescription: String {
        var parts: [String] = [viewModel.event.text]
        if viewModel.isRevealed {
            parts.append(viewModel.event.dateString)
            parts.append(viewModel.isSelectedCardCorrect ? parentViewModel.localizedStrings.correctAnswerA11y : parentViewModel.localizedStrings.incorrectAnswerA11y)
        }
        return parts.joined(separator: ", ")
    }

    private var eventText: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text(viewModel.event.text)
                .font(Font(WMFFont.for(.footnote)))
                .foregroundColor(Color(uiColor: theme.text))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, 2)
        }
        .scrollIndicatorsFlash(onAppear: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.trailing, 8)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if viewModel.event.imageURL != nil {
            if let data = viewModel.thumbnailImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(uiColor: theme.midBackground))
                    .frame(width: 100, height: 100)
                    .overlay(ProgressView().scaleEffect(0.7))
            }
        }
    }

    /// Checkmark (correct) or xmark (wrong/unselected) icon shown after reveal.
    private var resultIcon: some View {
        ZStack {
            Circle()
                .fill(iconColor)
                .frame(width: 30, height: 30)

            Image(systemName: viewModel.resultIconName())
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.paperBackground))
        }
    }

    private var datePill: some View {
        Text(viewModel.event.dateString)
            .accessibilityHidden(true)
            .minimumScaleFactor(0.3)
            .font(Font(WMFFont.for(.subheadline)))
            .foregroundColor(Color(uiColor: theme.paperBackground))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(revealColor))
    }
}

// MARK: - Height Behavior

private struct CardHeightModifier: ViewModifier {
    let isRegular: Bool
    let cardHeight: CGFloat

    func body(content: Content) -> some View {
        if isRegular {
            content
                .containerRelativeFrame(.vertical, count: 3, spacing: 16)
        } else {
            content
                .frame(height: cardHeight)
        }
    }
}
