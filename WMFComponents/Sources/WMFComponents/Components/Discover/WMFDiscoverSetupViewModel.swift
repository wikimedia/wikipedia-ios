import Foundation
import WMFData

public protocol WMFDiscoverSetupLoggingDelegate: AnyObject {
    @MainActor func discoverSetupDidAppear()
    @MainActor func discoverSetupDidTapContinue(source: WMFDiscoverSource)
}

/// The first Discover setup screen: how the reading list picks its articles.
@MainActor
public final class WMFDiscoverSetupViewModel: ObservableObject {

    /// The sources offered to the reader, in display order. Sources without data are left out.
    public let availableSources: [WMFDiscoverSource]
    @Published public private(set) var selectedSource: WMFDiscoverSource

    public var didChooseInterests: (() -> Void)?
    public var didTurnOnDiscover: (() -> Void)?
    public weak var loggingDelegate: WMFDiscoverSetupLoggingDelegate?

    private let readingListDataController: WMFDiscoverReadingListDataController
    private let discoverDataController: WMFDiscoverDataController
    private var didLogImpression = false
    var continueTask: Task<Void, Never>?

    /// `currentSource` is pre-selected when it is offered, so the screen can be reused from
    /// Settings. Otherwise interests is pre-selected, as on the first run.
    public init(
        availableSources: [WMFDiscoverSource],
        currentSource: WMFDiscoverSource,
        readingListDataController: WMFDiscoverReadingListDataController = .shared,
        discoverDataController: WMFDiscoverDataController = .shared
    ) {
        let sources = availableSources.isEmpty ? [.interests] : availableSources
        self.availableSources = sources
        self.selectedSource = sources.contains(currentSource) ? currentSource : .interests
        self.readingListDataController = readingListDataController
        self.discoverDataController = discoverDataController
    }

    /// Reads the available sources and the current settings before the screen shows, so the
    /// screen never needs a loading state. Without a data store only interests is offered.
    public static func load(
        readingListDataController: WMFDiscoverReadingListDataController = .shared,
        discoverDataController: WMFDiscoverDataController = .shared
    ) async -> WMFDiscoverSetupViewModel {
        let availableSources = (try? await readingListDataController.availableSources()) ?? [.interests]
        let currentSource = await readingListDataController.settings.source
        return WMFDiscoverSetupViewModel(
            availableSources: availableSources,
            currentSource: currentSource,
            readingListDataController: readingListDataController,
            discoverDataController: discoverDataController
        )
    }

    public func viewDidAppear() {
        guard !didLogImpression else { return }
        didLogImpression = true
        loggingDelegate?.discoverSetupDidAppear()
    }

    public func select(_ source: WMFDiscoverSource) {
        guard availableSources.contains(source) else { return }
        selectedSource = source
    }

    public func tapContinue() {
        guard continueTask == nil else { return }
        let source = selectedSource
        loggingDelegate?.discoverSetupDidTapContinue(source: source)

        continueTask = Task { [weak self] in
            guard let self else { return }
            await self.commit(source)
            self.continueTask = nil
        }
    }

    private func commit(_ source: WMFDiscoverSource) async {
        var settings = await readingListDataController.settings
        settings.source = source

        switch source {
        case .interests:
            try? await readingListDataController.saveSettings(settings)
            didChooseInterests?()
        case .saved, .history:
            settings.isEnabled = true
            try? await readingListDataController.saveSettings(settings)
            try? discoverDataController.markAnnouncementDismissed()
            didTurnOnDiscover?()
        }
    }
}
