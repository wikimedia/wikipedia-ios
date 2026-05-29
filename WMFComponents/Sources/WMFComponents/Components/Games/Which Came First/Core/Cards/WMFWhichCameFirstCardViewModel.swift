import Foundation
import SwiftUI
import WMFData

@MainActor
public final class WMFWhichCameFirstCardViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let event: WMFOnThisDayCardEvent

    @Published public var isSelected: Bool
    @Published public var isRevealed: Bool
    @Published public var isSelectedCardCorrect: Bool // This shows if the explicit card is the correct one
    @Published public var thumbnailImageData: Data?

    private var imageTask: Task<Void, Never>?
    private let traitCollection = UITraitCollection(preferredContentSizeCategory: .large)

    public init(
        event: WMFOnThisDayCardEvent,
        isSelected: Bool = false,
        isRevealed: Bool = false,
        isCorrectAnswer: Bool = false
    ) {
        self.event = event
        self.isSelected = isSelected
        self.isRevealed = isRevealed
        self.isSelectedCardCorrect = isCorrectAnswer

        if event.imageURL != nil {
            loadImage()
        }
    }

    deinit {
        imageTask?.cancel()
    }

    public func setSelected(_ selected: Bool) {
        guard !isRevealed else { return }
        isSelected = selected
    }

    public func reveal(userSelected: Bool, isCorrectAnswer: Bool) {
        self.isSelectedCardCorrect = isCorrectAnswer
        self.isSelected = userSelected || isCorrectAnswer
        self.isRevealed = true
    }

    func resultIconName() -> String {
        isSelectedCardCorrect ? "checkmark" : "xmark"
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
        var result = DateFormatter.wmfMonthDayYearDateFormatter.string(from: date)
        let year = Calendar.current.component(.year, from: date)
        if year > 0 && year < 1000 {
            let paddedYear = String(format: "%04d", year)
            let naturalYear = String(year)
            result = result.replacingOccurrences(of: paddedYear, with: naturalYear)
        }
        return result
    }

    public init(text: String, date: Date, imageURL: URL? = nil) {
        self.text = text
        self.date = date
        self.imageURL = imageURL
    }
}
