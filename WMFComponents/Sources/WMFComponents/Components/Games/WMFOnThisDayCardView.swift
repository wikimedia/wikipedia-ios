import SwiftUI
import UIKit

public struct WMFOnThisDayCardView: View {

    @ObservedObject private var viewModel: WMFOnThisDayCardViewModel
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current

    @Environment(\.horizontalSizeClass) private var sizeClass

    let onTap: (() -> Void)?

    public init(viewModel: WMFOnThisDayCardViewModel, onTap: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onTap = onTap
    }

    private var theme: WMFTheme { appEnvironment.theme }

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
        .modifier(CardHeightModifier(isRegular: sizeClass == .regular))
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                eventText
                thumbnailView
            }
            .padding(16)

            if viewModel.isRevealed {
                HStack {
                    Spacer()
                    resultIcon
                        .padding([.bottom, .trailing], 12)
                }
            }
        }
        .background(Color(uiColor: theme.paperBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    Color(viewModel.isSelected ? theme.text : theme.baseBackground),
                    lineWidth: 1
                )
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
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(.isStaticText)
    }

    private var eventText: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text(viewModel.event.text)
                .font(Font(WMFFont.for(.footnote)))
                .foregroundColor(Color(uiColor: theme.text))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 8
                        )
                    )
            } else {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 8
                )
                .fill(Color(uiColor: theme.midBackground))
                .frame(width: 100, height: 100)
                .overlay(ProgressView().scaleEffect(0.7))
            }
        }
    }

    private var resultIcon: some View {
        ZStack {
            Circle()
                .fill(viewModel.pillColor(theme: theme))
                .frame(width: 30, height: 30)

            Image(systemName: viewModel.resultIconName())
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.paperBackground))
        }
    }

    private var datePill: some View {
        Text(viewModel.event.dateString)
            .font(Font(WMFFont.for(.subheadline)))
            .foregroundColor(Color(uiColor: theme.paperBackground))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(viewModel.pillColor(theme: theme)))
    }
}

// MARK: - Height Behavior

private struct CardHeightModifier: ViewModifier {
    let isRegular: Bool

    func body(content: Content) -> some View {
        if isRegular {
            content
                .containerRelativeFrame(.vertical, count: 3, spacing: 16)
        } else {
            content
                .frame(height: 192)
        }
    }
}
