import Foundation
import WMFData

// MARK: - View Model

@MainActor
public final class WMFOnThisDayCardViewModel: ObservableObject, Identifiable {

    // MARK: Public properties

    public let id = UUID()

    /// The event this card represents.
    public let event: WMFOnThisDayEvent

    /// Whether the card is currently selected by the user.
    @Published public var isSelected: Bool

    /// Whether the answer has been revealed.
    @Published public var isRevealed: Bool

    /// Whether the selected answer is correct (only meaningful when `isRevealed` is `true`).
    @Published public var isCorrect: Bool

    /// Thumbnail image data, lazily loaded via `WMFImageDataController`.
    @Published public var thumbnailImageData: Data?

    // MARK: Private

    private var imageTask: Task<Void, Never>?

    // MARK: Init

    public init(
        event: WMFOnThisDayEvent,
        isSelected: Bool = false,
        isRevealed: Bool = false,
        isCorrect: Bool = false
    ) {
        self.event = event
        self.isSelected = isSelected
        self.isRevealed = isRevealed
        self.isCorrect = isCorrect

        if event.imageURL != nil {
            loadImage()
        }
    }

    deinit {
        imageTask?.cancel()
    }

    // MARK: Public Actions

    /// Toggle the selected state (no-op if already revealed).
    public func toggleSelection() {
        guard !isRevealed else { return }
        isSelected.toggle()
    }

    /// Reveal the result for this card.
    public func reveal(correct: Bool) {
        isCorrect = correct
        isRevealed = true
    }

    /// Reset the card back to its initial un-selected, un-revealed state.
    public func reset() {
        isSelected = false
        isRevealed = false
        isCorrect = false
    }

    // MARK: Private

    private func loadImage() {
        imageTask?.cancel()
        imageTask = Task { [weak self] in
            guard let self, let url = self.event.imageURL else { return }
            do {
                let data = try await WMFImageDataController.shared.fetchImageData(url: url)
                self.thumbnailImageData = data
            } catch {
                // Non-fatal: the view falls back to a placeholder thumbnail
            }
        }
    }
}
