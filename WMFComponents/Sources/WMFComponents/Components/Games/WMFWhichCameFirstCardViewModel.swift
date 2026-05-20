import Foundation
import SwiftUI
import WMFData

@MainActor
public final class WMFWhichCameFirstCardViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let event: WMFOnThisDayCardEvent

    @Published public var isSelected: Bool
    @Published public var isRevealed: Bool
    @Published public var isCorrect: Bool
    @Published public var isCorrectAnswer: Bool
    @Published public var thumbnailImageData: Data?

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

    func resultIconName() -> String {
        isCorrectAnswer ? "checkmark" : "xmark"
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
