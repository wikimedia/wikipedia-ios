import Foundation
import SwiftUI

// MARK: - View Model

@MainActor
public final class WMFOnThisDayCardViewModel: ObservableObject, Identifiable {

    // MARK: Public properties

    public let id = UUID()
    public let event: WMFOnThisDayEvent

    @Published public var isSelected: Bool
    @Published public var isRevealed: Bool
    @Published public var isCorrect: Bool
    @Published public var isCorrectAnswer: Bool
    @Published public var thumbnailImageData: Data?
    @Published public var isVisible: Bool = false

    // MARK: Private

    private var imageTask: Task<Void, Never>?
    private let traitCollection = UITraitCollection(preferredContentSizeCategory: .large)

    // MARK: Init

    public init(
        event: WMFOnThisDayEvent,
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

    // MARK: Public Actions

    public func toggleSelection() {
        guard !isRevealed else { return }
        isSelected.toggle()
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

    // MARK: - Derived Presentation State

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
        isCorrectAnswer ? Color(uiColor: theme.accent) : Color(uiColor: theme.destructive)
    }

    func resultIconName() -> String {
        isCorrectAnswer ? "checkmark" : "xmark"
    }

    // MARK: - Fonts

    var eventTextFont: Font {
        Font(WMFFont.for(.subheadline, compatibleWith: traitCollection))
    }

    var resultIconFont: Font {
        Font(WMFFont.for(.boldCaption1, compatibleWith: traitCollection))
    }

    var datePillFont: Font {
        Font(WMFFont.for(.mediumFootnote, compatibleWith: traitCollection))
    }

    // MARK: Private

    private func loadImage() {
        imageTask?.cancel()
        imageTask = Task { [weak self] in
            guard let self, let url = self.event.imageURL else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                self.thumbnailImageData = data
            } catch {
                // Non-fatal: view falls back to placeholder thumbnail
            }
        }
    }
}
