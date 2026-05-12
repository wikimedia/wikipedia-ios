import SwiftUI
import UIKit

public struct WMFOnThisDayCardView: View {

    @ObservedObject private var viewModel: WMFOnThisDayCardViewModel
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current

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
                    .offset(y: 14)
            }
        }
        .padding(.bottom, viewModel.isRevealed ? 14 : 0)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isRevealed)
        .animation(.easeInOut(duration: 0.18), value: viewModel.isSelected)
    }

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
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(viewModel.isSelected ? theme.text : theme.baseBackground), lineWidth: 1)
        )
        .shadow(color: viewModel.isSelected ? .clear : Color(uiColor: theme.text).opacity(0.05), radius: 8, x: 0, y: 0)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !viewModel.isRevealed else { return }
            onTap?()
        }
    }

    private var eventText: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text(viewModel.event.text)
                .font(Font(WMFFont.for(.footnote)))
                .foregroundColor(Color(uiColor: theme.text))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

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
        Text(viewModel.event.date)
            .font(Font(WMFFont.for(.subheadline)))
            .foregroundColor(Color(uiColor: theme.paperBackground))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(viewModel.pillColor(theme: theme)))
    }
}

#Preview("Default") {
    WMFOnThisDayCardView(
        viewModel: WMFOnThisDayCardViewModel(
            event: WMFOnThisDayCardEvent(
                text: "The Apollo 11 mission successfully lands the first humans on the Moon, with Neil Armstrong and Buzz Aldrin walking on the lunar surface.",
                date: "1969",
                imageURL: URL(string: "https://commons.wikimedia.org/wiki/File:Apollo_11_Crew.jpg")
            )
        )
    )
    .padding()
}

#Preview("Selected") {
    WMFOnThisDayCardView(
        viewModel: WMFOnThisDayCardViewModel(
            event: WMFOnThisDayCardEvent(
                text: "The Apollo 11 mission successfully lands the first humans on the Moon, with Neil Armstrong and Buzz Aldrin walking on the lunar surface.",
                date: "1969",
                imageURL: URL(string: "https://commons.wikimedia.org/wiki/File:Apollo_11_Crew.jpg")
            ),
            isSelected: true
        )
    )
    .padding()
}

#Preview("Revealed Correct") {
    WMFOnThisDayCardView(
        viewModel: WMFOnThisDayCardViewModel(
            event: WMFOnThisDayCardEvent(
                text: "The Apollo 11 mission successfully lands the first humans on the Moon, with Neil Armstrong and Buzz Aldrin walking on the lunar surface.",
                date: "1969",
                imageURL: URL(string: "https://commons.wikimedia.org/wiki/File:Apollo_11_Crew.jpg")
            ),
            isSelected: true,
            isRevealed: true,
            isCorrect: true,
            isCorrectAnswer: true
        )
    )
    .padding()
}

#Preview("Revealed Incorrect") {
    WMFOnThisDayCardView(
        viewModel: WMFOnThisDayCardViewModel(
            event: WMFOnThisDayCardEvent(
                text: "The World Wide Web is invented by Tim Berners-Lee while working at CERN in Geneva, Switzerland.",
                date: "1989",
                imageURL: nil
            ),
            isSelected: true,
            isRevealed: true,
            isCorrect: false,
            isCorrectAnswer: false
        )
    )
    .padding()
}

#Preview("No Image") {
    WMFOnThisDayCardView(
        viewModel: WMFOnThisDayCardViewModel(
            event: WMFOnThisDayCardEvent(
                text: "The World Wide Web is invented by Tim Berners-Lee while working at CERN in Geneva, Switzerland.",
                date: "1989"
            )
        )
    )
    .padding()
}
