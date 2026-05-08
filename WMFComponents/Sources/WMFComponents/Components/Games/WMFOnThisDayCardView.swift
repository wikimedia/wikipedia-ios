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

    public init(viewModel: WMFOnThisDayCardViewModel) {
        self.viewModel = viewModel
    }

    private var event: WMFOnThisDayEvent { viewModel.event }
    private var isSelected: Bool { viewModel.isSelected }
    private var isRevealed: Bool { viewModel.isRevealed }
    private var isCorrect: Bool { viewModel.isCorrect }

    // MARK: Styling

    private var borderColor: Color {
        if isRevealed {
            return isCorrect ? Color(red: 0.2, green: 0.72, blue: 0.4) : Color(red: 0.85, green: 0.25, blue: 0.25)
        } else if isSelected {
            return Color(red: 0.24, green: 0.44, blue: 0.84)
        } else {
            return Color(.systemGray5)
        }
    }

    private var borderWidth: CGFloat {
        isSelected || isRevealed ? 2 : 1
    }

    private var backgroundColor: Color {
        Color(.systemBackground)
    }

    // MARK: Body

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // --- Text block (scrollable if needed) ---
            ScrollView(.vertical, showsIndicators: true) {
                Text(event.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(.label))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 4)
            }
            .frame(maxHeight: 120)

            // --- Thumbnail ---
            if event.imageURL != nil {
                if let data = viewModel.thumbnailImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    placeholderThumbnail
                        .overlay(ProgressView().scaleEffect(0.6))
                }
            }
        }
        .padding(16)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        )
        // Date badge + check/x badge (revealed state)
        .overlay(alignment: .bottomTrailing) {
            if isRevealed {
                revealedBadges
            }
        }
        .shadow(color: Color.black.opacity(isSelected ? 0.12 : 0.06), radius: isSelected ? 8 : 4, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.25), value: isRevealed)
    }

    // MARK: Sub-views

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 72, height: 72)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(Color(.systemGray3))
                    .font(.system(size: 20))
            )
    }

    private var revealedBadges: some View {
        HStack(spacing: 6) {
            // Date pill
            Text(event.date)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isCorrect
                              ? Color(red: 0.2, green: 0.72, blue: 0.4)
                              : Color(red: 0.85, green: 0.25, blue: 0.25))
                )

            // Check / X icon badge
            ZStack {
                Circle()
                    .fill(isCorrect
                          ? Color(red: 0.2, green: 0.72, blue: 0.4)
                          : Color(red: 0.85, green: 0.25, blue: 0.25))
                    .frame(width: 28, height: 28)
                Image(systemName: isCorrect ? "checkmark" : "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding([.bottom, .trailing], 12)
    }
}

// MARK: - Preview

#Preview("Card States") {
    ScrollView {
        VStack(spacing: 24) {

            Text("Default (unselected)")
                .font(.caption).foregroundStyle(.secondary)
            WMFOnThisDayCardView(viewModel: WMFOnThisDayCardViewModel(
                event: WMFOnThisDayEvent(
                    text: "U.S. figure skater Nancy Kerrigan is attacked and injured by an assailant hired by her rival Tonya Harding's ex-husband during the U.S. Figure Skating Championships.",
                    date: "January 6, 1994",
                    imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Nancy_Kerrigan_1992.jpg/220px-Nancy_Kerrigan_1992.jpg")
                ),
                isSelected: false
            ))

            Text("Selected")
                .font(.caption).foregroundStyle(.secondary)
            WMFOnThisDayCardView(viewModel: WMFOnThisDayCardViewModel(
                event: WMFOnThisDayEvent(
                    text: "Americans storm the United States Capitol Building to disrupt certification of the 2020 presidential election, resulting in five deaths and evacuation of the U.S. Congress.",
                    date: "January 6, 2021",
                    imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/2021_storming_of_the_United_States_Capitol_01.jpg/320px-2021_storming_of_the_United_States_Capitol_01.jpg")
                ),
                isSelected: true
            ))

            Text("Revealed — Correct")
                .font(.caption).foregroundStyle(.secondary)
            WMFOnThisDayCardView(viewModel: WMFOnThisDayCardViewModel(
                event: WMFOnThisDayEvent(
                    text: "U.S. figure skater Nancy Kerrigan is attacked and injured by an assailant hired by her rival Tonya Harding's ex-husband during the U.S. Figure Skating Championships.",
                    date: "January 6, 1994",
                    imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Nancy_Kerrigan_1992.jpg/220px-Nancy_Kerrigan_1992.jpg")
                ),
                isSelected: true,
                isRevealed: true,
                isCorrect: true
            ))

            Text("Revealed — Incorrect")
                .font(.caption).foregroundStyle(.secondary)
            WMFOnThisDayCardView(viewModel: WMFOnThisDayCardViewModel(
                event: WMFOnThisDayEvent(
                    text: "Americans storm the United States Capitol Building to disrupt certification of the 2020 presidential election, resulting in five deaths and evacuation of the U.S. Congress.",
                    date: "January 6, 2021",
                    imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/2021_storming_of_the_United_States_Capitol_01.jpg/320px-2021_storming_of_the_United_States_Capitol_01.jpg")
                ),
                isSelected: true,
                isRevealed: true,
                isCorrect: false
            ))

            Text("No image")
                .font(.caption).foregroundStyle(.secondary)
            WMFOnThisDayCardView(viewModel: WMFOnThisDayCardViewModel(
                event: WMFOnThisDayEvent(
                    text: "A very long event description that definitely overflows the single visible line so the scroll indicator appears and the user can scroll to read everything that is written here — this text is intentionally long to demonstrate the scrollable behaviour.",
                    date: "January 6, 2000"
                ),
                isSelected: false
            ))
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
