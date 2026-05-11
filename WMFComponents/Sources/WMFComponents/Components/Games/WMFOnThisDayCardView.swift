import SwiftUI
import UIKit

// MARK: - Data Model

public struct WMFOnThisDayEvent: Identifiable {
    public let id = UUID()
    public let text: String
    public let date: String        // e.g. "January 6, 1994"
    public let imageURL: URL?

    public init(text: String, date: String, imageURL: URL? = nil) {
        self.text = text
        self.date = date
        self.imageURL = imageURL
    }
}
// MARK: - Card View

public struct WMFOnThisDayCardView: View {

    @ObservedObject private var viewModel: WMFOnThisDayCardViewModel
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current

    let onTap: (() -> Void)?

    public init(viewModel: WMFOnThisDayCardViewModel, onTap: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onTap = onTap
    }

    private var theme: WMFTheme { appEnvironment.theme }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .bottom) {
            cardContent
            if viewModel.isRevealed {
                datePill
                    .offset(y: 14)
            }
        }
        .padding(.bottom, viewModel.isRevealed ? 14 : 0)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isRevealed)
        .animation(.easeInOut(duration: 0.18), value: viewModel.isSelected)
    }

    // MARK: - Card

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
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
        .frame(height: 192)
        .background(Color(uiColor: theme.paperBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    viewModel.borderColor(theme: theme),
                    lineWidth: viewModel.borderLineWidth()
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard !viewModel.isRevealed else { return }
            onTap?()
        }
    }

    // MARK: - Text

    private var eventText: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text(viewModel.event.text)
                .font(viewModel.eventTextFont)
                .foregroundColor(Color(uiColor: theme.text))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnailView: some View {
        if viewModel.event.imageURL != nil {
            if let data = viewModel.thumbnailImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(uiColor: theme.midBackground))
                    .frame(width: 80, height: 80)
                    .overlay(ProgressView().scaleEffect(0.7))
            }
        }
    }

    // MARK: - Result Icon

    private var resultIcon: some View {
        ZStack {
            Circle()
                .fill(viewModel.pillColor(theme: theme))
                .frame(width: 30, height: 30)
            Image(systemName: viewModel.resultIconName())
                .font(viewModel.resultIconFont)
                .foregroundColor(Color(uiColor: theme.paperBackground))
        }
    }

    // MARK: - Date Pill

    private var datePill: some View {
        Text(viewModel.event.date)
            .font(viewModel.datePillFont)
            .foregroundColor(Color(uiColor: theme.paperBackground))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(viewModel.pillColor(theme: theme)))
    }
}
