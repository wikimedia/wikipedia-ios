import Foundation
import WMFData
import WMFNativeLocalizations

/// An article the interests screen shows as a card when it opens.
struct WMFInterestsStoredPage: Hashable {
    let title: String
    /// Nil when the store did not record the wiki. The screen then uses its own project.
    let project: WMFProject?
}

/// Where the interests screen reads and writes the selection. For You and Discover keep
/// separate sets, so the screen talks to a store instead of a data controller.
@MainActor
protocol WMFInterestsStore: AnyObject {
    /// The selected topics when the screen opens.
    func loadTopics() -> [WMFArticleTopic]
    func setTopics(_ topics: [WMFArticleTopic])
    /// The selected articles when the screen opens.
    func loadPages() async -> [WMFInterestsStoredPage]
    func addPage(title: String, project: WMFProject)
    func removePage(title: String, project: WMFProject)
    /// Shown under the header of the screen. Nil when the store has nothing to say.
    var subtitle: String? { get }
    /// Articles the screen offers unselected before any topic is tapped. Nil when the store has no
    /// suggestions: the screen then shows random articles only.
    func suggestedPages() async -> [WMFInterestsStoredPage]?
    /// Called once when the reader leaves the screen for good.
    func didLeave(hasChanges: Bool)
}

/// The For You interests: topics in user defaults, articles in Core Data. Every change is
/// saved at once.
@MainActor
final class WMFForYouInterestsStore: WMFInterestsStore {

    private let homeDataController: WMFHomeDataController
    private let injectedPageInterestDataController: WMFPageInterestDataController?
    private var resolvedPageInterestDataController: WMFPageInterestDataController?

    init(homeDataController: WMFHomeDataController, pageInterestDataController: WMFPageInterestDataController?) {
        self.homeDataController = homeDataController
        self.injectedPageInterestDataController = pageInterestDataController
    }

    /// Resolved lazily: the Core Data store may not be ready when this store is created early
    /// in app launch (e.g. the onboarding coordinator builds it up front). Re-attempting on
    /// each access until it succeeds means selections persist once the store is available,
    /// rather than being silently dropped by a nil controller captured at init time.
    private var pageInterestDataController: WMFPageInterestDataController? {
        if let injectedPageInterestDataController {
            return injectedPageInterestDataController
        }
        if let resolvedPageInterestDataController {
            return resolvedPageInterestDataController
        }
        let controller = try? WMFPageInterestDataController()
        resolvedPageInterestDataController = controller
        return controller
    }

    func loadTopics() -> [WMFArticleTopic] {
        homeDataController.interestTopics()
    }

    func setTopics(_ topics: [WMFArticleTopic]) {
        homeDataController.setInterestTopics(topics)
    }

    func loadPages() async -> [WMFInterestsStoredPage] {
        let interests = (try? await pageInterestDataController?.fetchAllPageInterests()) ?? []
        return interests.map { WMFInterestsStoredPage(title: $0.title, project: $0.project) }
    }

    func addPage(title: String, project: WMFProject) {
        Task { try? await pageInterestDataController?.addPageInterest(title: title, project: project) }
    }

    func removePage(title: String, project: WMFProject) {
        Task { try? await pageInterestDataController?.removePageInterest(title: title, project: project) }
    }

    var subtitle: String? {
        nil
    }

    func suggestedPages() async -> [WMFInterestsStoredPage]? {
        nil
    }

    /// The Home feed rebuilds itself from the new set.
    func didLeave(hasChanges: Bool) {
        guard hasChanges else { return }
        NotificationCenter.default.post(name: WMFNSNotification.forYouInterestsDidChange, object: nil)
    }
}

/// The Discover interests, kept apart from For You. The store holds a copy of the set, so the
/// screen reads it without waiting. Taps change only the copy. `commit()` writes it back when
/// the reader leaves the screen.
@MainActor
public final class WMFDiscoverInterestsStore: WMFInterestsStore {

    private let dataController: WMFDiscoverInterestsDataController
    public private(set) var interests: WMFDiscoverInterests
    /// Called when the screen goes away for good: Done, Back, or Settings closing over it.
    public var didLeaveScreen: (() -> Void)?

    public init(interests: WMFDiscoverInterests = .empty, dataController: WMFDiscoverInterestsDataController = .shared) {
        self.interests = interests
        self.dataController = dataController
    }

    /// Reads the saved set before the screen opens, so the header and the grid are right at once.
    public static func load(dataController: WMFDiscoverInterestsDataController = .shared) async -> WMFDiscoverInterestsStore {
        let interests = (try? await dataController.fetchInterests()) ?? .empty
        return WMFDiscoverInterestsStore(interests: interests, dataController: dataController)
    }

    func loadTopics() -> [WMFArticleTopic] {
        interests.topics
    }

    public func setTopics(_ topics: [WMFArticleTopic]) {
        interests.topics = topics
    }

    func loadPages() async -> [WMFInterestsStoredPage] {
        interests.pages.map { WMFInterestsStoredPage(title: $0.title, project: $0.project) }
    }

    public func addPage(title: String, project: WMFProject) {
        let page = WMFDiscoverInterests.Page(title: title, project: project)
        guard !interests.contains(page) else { return }
        interests.pages.append(page)
    }

    public func removePage(title: String, project: WMFProject) {
        let page = WMFDiscoverInterests.Page(title: title, project: project)
        interests.pages.removeAll { $0.matches(page) }
    }

    let subtitle: String? = WMFLocalizedString("discover-interests-subtitle", value: "Changes here only affect what you see in Discover.", comment: "Text under the header of the interests screen when it is opened from Discover. It tells the reader that these interests do not change the For You feed.")

    /// Recent history and saved articles.
    func suggestedPages() async -> [WMFInterestsStoredPage]? {
        let pages = (try? await dataController.suggestedPages()) ?? []
        return pages.map { WMFInterestsStoredPage(title: $0.title, project: $0.project) }
    }

    /// The coordinator commits the set on Done, so nothing is saved here.
    func didLeave(hasChanges: Bool) {
        didLeaveScreen?()
    }

    /// Saves the set as it is on screen. An empty set is never saved: Discover needs at least one
    /// interest to build the list, and Done is off with none selected. So the saved set is always
    /// usable.
    public func commit() async throws {
        guard !interests.isEmpty else { return }
        try await dataController.save(interests)
    }
}
