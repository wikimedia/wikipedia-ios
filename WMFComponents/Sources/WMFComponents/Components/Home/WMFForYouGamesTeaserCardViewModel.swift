import Foundation
import UIKit
import SwiftUI
import WMFData
import WMFNativeLocalizations

/// Card 1 of the Games Teaser module: the first question of the day's featured game, plus a CTA
/// into the game itself.
///
/// The card resolves its own availability, because whether a game exists for the day is an async
/// question (`WMFGamesDataController.isWhichCameFirstDailySessionAvailable`) that also covers the
/// language check. `loadState == .unavailable` is the module's signal to hide itself.
@MainActor
public final class WMFForYouGamesTeaserCardViewModel: ObservableObject, Identifiable {

    // MARK: - Nested Types

    public enum LoadState {
        case loading
        case loaded
        /// No game for this day, or the game is not offered in the feed's language. Hide the module.
        case unavailable
    }

    public enum PlayState {
        case notStarted
        case inProgress
        case completed
    }

    // MARK: - Properties

    public let id = UUID()

    /// Stable across days, so hiding the card hides today's card only — the reader stays eligible
    /// for tomorrow's, as the spec requires. Hidden keys are stored against the day.
    public var cardUniqueKey: String {
        "for_you_games_teaser_\(Self.gameKey)_\(date)"
    }

    public let project: WMFProject
    public let module: WMFForYouModule

    private static let gameKey = "which-came-first"
    private let date: String
    private let gamesDataController: WMFGamesDataController

    @Published public private(set) var loadState: LoadState = .loading
    @Published public private(set) var playState: PlayState = .notStarted
    /// The two event cards, ready for `WMFWhichCameFirstCardView`. Each one loads its own
    /// thumbnail, so nothing here fetches images.
    @Published public private(set) var eventCardViewModels: [WMFWhichCameFirstCardViewModel] = []

    // MARK: - Callbacks

    public var onTapCard: (() -> Void)?
    public var onTapPlay: (() -> Void)?
    public var onHideCard: (() -> Void)?
    public var onHideModule: (() -> Void)?
    public var onCustomizeInterests: (() -> Void)?
    public var onShare: (() -> Void)?

    /// Fired once when there is no game to show, so the feed can drop the module.
    public var onUnavailable: (() -> Void)?

    private var loadTask: Task<Void, Never>?
    private var sessionObserver: NSObjectProtocol?

    // MARK: - Lifecycle

    public init(
        project: WMFProject,
        date: String? = nil,
        module: WMFForYouModule = .games,
        gamesDataController: WMFGamesDataController = WMFGamesDataController()
    ) {
        self.project = project
        self.date = date ?? Self.todayISODateString()
        self.module = module
        self.gamesDataController = gamesDataController
        observeSessionUpdates()
    }

    deinit {
        loadTask?.cancel()
        if let sessionObserver {
            NotificationCenter.default.removeObserver(sessionObserver)
        }
    }

    /// The games data controller posts on every answer and on completion, so the CTA is already
    /// right when the reader swipes back to the feed, without the coordinator having to call
    /// `refresh()`.
    private func observeSessionUpdates() {
        sessionObserver = NotificationCenter.default.addObserver(
            forName: WMFNSNotification.whichCameFirstSessionDidUpdate,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            // Read out of the notification here: `Notification` cannot cross into the task.
            let projectID = notification.userInfo?["projectID"] as? String
            let dailyGameDate = notification.userInfo?["dailyGameDate"] as? String

            Task { @MainActor [weak self] in
                guard let self,
                      projectID == self.project.id,
                      dailyGameDate == self.date else { return }

                await self.updatePlayState()
            }
        }
    }

    // MARK: - Loading

    /// Called from the view's `onAppear`. Runs once; use `refresh()` to pick up a session change.
    public func load() {
        guard loadTask == nil else { return }

        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.loadPreview()
        }
    }

    /// Re-reads the session so the CTA is right after the reader comes back from the game.
    /// The coordinator calls this when the game is dismissed.
    public func refresh() {
        Task { [weak self] in
            guard let self else { return }
            await self.updatePlayState()
        }
    }

    private func loadPreview() async {
        let isAvailable = (try? await gamesDataController.isWhichCameFirstDailySessionAvailable(date: date, project: project)) ?? false

        guard isAvailable else {
            markUnavailable()
            return
        }

        // `try?` collapses the throw and the optional return into one optional.
        guard let preview = try? await gamesDataController.fetchWhichCameFirstDailyPreviewEvents(date: date, project: project) else {
            markUnavailable()
            return
        }

        eventCardViewModels = [cardViewModel(from: preview.optionA), cardViewModel(from: preview.optionB)]
        await updatePlayState()
        loadState = .loaded
    }

    private func markUnavailable() {
        guard loadState != .unavailable else { return }
        loadState = .unavailable
        onUnavailable?()
    }

    /// Built unselected and unrevealed, which is what keeps the date pill and the result icon off
    /// the teaser — the card must not give the answer away.
    private func cardViewModel(from event: WMFWhichCameFirstEvent) -> WMFWhichCameFirstCardViewModel {
        WMFWhichCameFirstCardViewModel(
            event: WMFOnThisDayCardEvent(
                text: event.title,
                date: event.date,
                imageURL: event.thumbnailURL
            )
        )
    }

    private func updatePlayState() async {
        let session = try? await gamesDataController.fetchWhichCameFirstDailySession(date: date, project: project)

        switch session?.status {
        case .completed:
            playState = .completed
        case .inProgress:
            playState = .inProgress
        default:
            playState = .notStarted
        }
    }

    // MARK: - Localized Strings

    /// Title of the game shown at the top of the card.
    public let gameTitle = WMFLocalizedString("for-you-games-teaser-which-came-first-title", value: "Which came first?", comment: "Title of the \"Which came first?\" game, shown on the games card in the For You feed.")

    /// The CTA changes with the state of today's session.
    public var playButtonTitle: String {
        switch playState {
        case .notStarted:
            return WMFLocalizedString("for-you-games-teaser-play", value: "Play today's game", comment: "Button on the games card in the For You feed that starts today's game.")
        case .inProgress:
            return WMFLocalizedString("for-you-games-teaser-continue", value: "Continue today's game", comment: "Button on the games card in the For You feed that resumes today's game, shown when the reader left the game part way through.")
        case .completed:
            return WMFLocalizedString("for-you-games-teaser-review", value: "Review results", comment: "Button on the games card in the For You feed that opens the results of today's game, shown when the reader has finished it.")
        }
    }

    public var hideCardTitle: String {
        WMFHomeLocalizedStrings.hideCard
    }

    public var hideModuleTitle: String {
        WMFHomeLocalizedStrings.hideModule
    }

    public var shareTitle: String {
        CommonStrings.shortShareTitle
    }

    public let customizeInterestsTitle = WMFLocalizedString("for-you-menu-customize-interests", value: "Customize interests", comment: "Menu action to open the interests customization screen from a For You feed card.")

    /// Share is offered only once the game is finished — there is no score to share before that.
    public var isShareAvailable: Bool {
        playState == .completed
    }

    public var accessibilityLabel: String {
        var parts: [String] = [gameTitle]
        parts.append(contentsOf: eventCardViewModels.map(\.event.text))
        parts.append(playButtonTitle)
        return parts.joined(separator: ", ")
    }

    // MARK: - Helpers

    /// Matches the format the games data controller expects for a daily session.
    private static func todayISODateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
}
