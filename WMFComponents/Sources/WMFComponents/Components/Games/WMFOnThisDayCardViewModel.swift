import Foundation
import SwiftUI
import WMFData

@MainActor
public final class WMFOnThisDayCardViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let event: WMFOnThisDayCardEvent

    @Published public var isSelected: Bool
    @Published public var isRevealed: Bool
    @Published public var isCorrect: Bool
    @Published public var isCorrectAnswer: Bool
    @Published public var thumbnailImageData: Data?
    @Published public var isVisible: Bool = false

    private var imageTask: Task<Void, Never>?
    private let traitCollection = UITraitCollection(preferredContentSizeCategory: .large)

    public init(
        event: WMFOnThisDayCardEvent,
        isSelected: Bool = false,
        isRevealed: Bool = false,
        isCorrect: Bool = false,
        isCorrectAnswer: Bool = false
    ) {
        self.event = event
        self.isSelected = isSelected
        self.isRevealed = isRevealed
        self.isCorrect = isCorrect
        self.isCorrectAnswer = isCorrectAnswer

        if event.imageURL != nil {
            loadImage()
        }
    }

    deinit {
        imageTask?.cancel()
    }

    public func toggleSelection() {
        guard !isRevealed else { return }
        isSelected.toggle()
    }

    public func setSelected(_ selected: Bool) {
        guard !isRevealed else { return }
        isSelected = selected
    }

    public func reveal(userSelected: Bool, isCorrectAnswer: Bool) {
        self.isCorrectAnswer = isCorrectAnswer
        self.isSelected = userSelected || isCorrectAnswer
        self.isCorrect = userSelected && isCorrectAnswer
        self.isRevealed = true
    }

    public func reset() {
        isSelected = false
        isRevealed = false
        isCorrect = false
        isCorrectAnswer = false
        isVisible = false
    }

    func borderColor(theme: WMFTheme) -> Color {
        if isRevealed {
            return isCorrectAnswer ? Color(uiColor: theme.accent) : Color(uiColor: theme.destructive)
        } else if isSelected {
            return Color(uiColor: theme.link)
        } else {
            return Color(uiColor: theme.border)
        }
    }

    func borderLineWidth() -> CGFloat {
        isSelected || isRevealed ? 2 : 1
    }

    func pillColor(theme: WMFTheme) -> Color {
        isCorrectAnswer ? Color(uiColor: theme.successGreen) : Color(uiColor: theme.baseBackground)
    }

    func resultIconName() -> String {
        isCorrectAnswer ? "checkmark" : "xmark"
    }

    var eventTextFont: Font {
        Font(WMFFont.for(.subheadline, compatibleWith: traitCollection))
    }

    var resultIconFont: Font {
        Font(WMFFont.for(.boldCaption1, compatibleWith: traitCollection))
    }

    var datePillFont: Font {
        Font(WMFFont.for(.mediumFootnote, compatibleWith: traitCollection))
    }

    private func loadImage() {
        imageTask?.cancel()
        imageTask = Task { [weak self] in
            guard let self, let url = self.event.imageURL else { return }
            do {
                let data = try await WMFImageDataController.shared.fetchImageData(url: url)
                self.thumbnailImageData = data
            } catch {}
        }
    }
}

public struct WMFOnThisDayCardEvent: Identifiable {
    public let id = UUID()
    public let text: String
    public let date: Date
    public let imageURL: URL?
    public var dateString: String {
        DateFormatter.wmfMonthDayYearDateFormatter.string(from: date)
    }

    public init(text: String, date: Date, imageURL: URL? = nil) {
        self.text = text
        self.date = date
        self.imageURL = imageURL
    }
}
