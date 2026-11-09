import Foundation
import WMFData

@MainActor
public protocol WMFDiscoverSetupLoggingDelegate: AnyObject {
    func discoverSetupDidAppear()
    func discoverSetupDidTapContinue(source: WMFDiscoverSource)
}

/// The first Discover setup screen: how the reading list picks its articles.
@MainActor
public final class WMFDiscoverSetupViewModel: ObservableObject {

    /// Where the screen opens from. The question and the Continue button show only on onboarding.
    public enum Presentation: Sendable {
        /// Get started on the Saved tab. Continue turns Discover on, or opens the interests screen.
        case onboarding
        /// How Discover is built, from the Discover settings. A new source asks for confirmation.
        /// Adjust saves the source and ends the flow.
        case settings
    }

    /// The sources offered to the reader, in display order. Sources without data are left out.
    public let availableSources: [WMFDiscoverSource]
    public let presentation: Presentation
    @Published public private(set) var selectedSource: WMFDiscoverSource
    @Published public var isShowingAdjustAlert = false

    public var didChooseInterests: (() -> Void)?
    public var didTurnOnDiscover: (() -> Void)?
    /// Settings only. Called after Adjust to saved articles or reading history saved the source.
    /// The first value is the previous source, the second the new one. The caller closes the screen.
    public var didChangeSource: ((WMFDiscoverSource, WMFDiscoverSource) -> Void)?
    public weak var loggingDelegate: WMFDiscoverSetupLoggingDelegate?

    private let readingListDataController: WMFDiscoverReadingListDataController
    private let discoverDataController: WMFDiscoverDataController
    private let persistedSource: WMFDiscoverSource
    private var didLogImpression = false
    private(set) var pendingSource: WMFDiscoverSource?
    var continueTask: Task<Void, Never>?
    private(set) var commitTask: Task<Void, Never>?

    /// `currentSource` is pre-selected when it is offered. Otherwise interests is pre-selected,
    /// as on the first run. From Settings the current source is always offered, even when it has
    /// no articles any more, so opening and closing the screen cannot change the source.
    public init(
        availableSources: [WMFDiscoverSource],
        currentSource: WMFDiscoverSource,
        presentation: Presentation = .onboarding,
        readingListDataController: WMFDiscoverReadingListDataController = .shared,
        discoverDataController: WMFDiscoverDataController = .shared
    ) {
        var sources = availableSources.isEmpty ? [.interests] : availableSources
        if presentation == .settings, !sources.contains(currentSource) {
            sources = WMFDiscoverSource.allCases.filter { sources.contains($0) || $0 == currentSource }
        }
        self.availableSources = sources
        self.presentation = presentation
        self.persistedSource = currentSource
        self.selectedSource = sources.contains(currentSource) ? currentSource : .interests
        self.readingListDataController = readingListDataController
        self.discoverDataController = discoverDataController
    }

    /// Reads the available sources and the current settings before the screen shows, so the
    /// screen never needs a loading state. Without a data store only interests is offered.
    public static func load(
        presentation: Presentation = .onboarding,
        readingListDataController: WMFDiscoverReadingListDataController = .shared,
        discoverDataController: WMFDiscoverDataController = .shared
    ) async -> WMFDiscoverSetupViewModel {
        let availableSources = (try? await readingListDataController.availableSources()) ?? [.interests]
        let currentSource = await readingListDataController.settings.source
        return WMFDiscoverSetupViewModel(
            availableSources: availableSources,
            currentSource: currentSource,
            presentation: presentation,
            readingListDataController: readingListDataController,
            discoverDataController: discoverDataController
        )
    }

    public func viewDidAppear() {
        guard !didLogImpression else { return }
        didLogImpression = true
        loggingDelegate?.discoverSetupDidAppear()
    }

    /// From Settings, a source that differs from the saved one asks for confirmation first,
    /// because the current recommendations go away. Like on Android.
    public func select(_ source: WMFDiscoverSource) {
        guard availableSources.contains(source) else { return }

        switch presentation {
        case .onboarding:
            selectedSource = source
        case .settings:
            if source == persistedSource || source == selectedSource {
                selectedSource = source
            } else {
                pendingSource = source
                isShowingAdjustAlert = true
            }
        }
    }

    // MARK: - Settings

    /// Adjust on the alert. Interests opens the interests screen and saves nothing yet: the
    /// interests screen saves the source on its way out, after the reader selected at least one
    /// interest, so the stored source never points at an empty set. The other sources are saved
    /// here and end the flow, like Next on Android.
    public func confirmAdjust() {
        isShowingAdjustAlert = false
        guard let pendingSource else { return }
        self.pendingSource = nil
        selectedSource = pendingSource

        switch pendingSource {
        case .interests:
            didChooseInterests?()
        case .saved, .history:
            commitSource(pendingSource)
        }
    }

    public func cancelAdjust() {
        isShowingAdjustAlert = false
        pendingSource = nil
    }

    /// Back on the interests screen that Adjust to interests opened. Nothing was saved, so the
    /// row shows the saved source again.
    public func undoChooseInterests() {
        selectedSource = persistedSource
    }

    /// Saves the settings with the new source and reports the change against the source the
    /// screen opened with. The task keeps only the data controller and the closure.
    private func commitSource(_ source: WMFDiscoverSource) {
        guard commitTask == nil else { return }
        let dataController = readingListDataController
        let previousSource = persistedSource
        let didChangeSource = didChangeSource

        commitTask = Task {
            var settings = await dataController.settings
            settings.source = source
            try? await dataController.saveSettings(settings)
            guard previousSource != source else { return }
            didChangeSource?(previousSource, source)
        }
    }

    public func tapContinue() {
        guard presentation == .onboarding, continueTask == nil else { return }
        let source = selectedSource
        loggingDelegate?.discoverSetupDidTapContinue(source: source)

        continueTask = Task { [weak self] in
            guard let self else { return }
            await self.commit(source)
            self.continueTask = nil
        }
    }

    /// Interests saves nothing: the interests screen turns Discover on with that source once the
    /// reader selected at least one interest. The other sources turn Discover on at once.
    private func commit(_ source: WMFDiscoverSource) async {
        switch source {
        case .interests:
            didChooseInterests?()
        case .saved, .history:
            var settings = await readingListDataController.settings
            settings.source = source
            settings.isEnabled = true
            try? await readingListDataController.saveSettings(settings)
            try? discoverDataController.markAnnouncementDismissed()
            didTurnOnDiscover?()
        }
    }
}
