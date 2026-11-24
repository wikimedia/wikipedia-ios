import Foundation
import SwiftUI
import UIKit
import WMFData
import WMFNativeLocalizations

/// State and behaviour for the WikiRun web game hosted in a WebView.
@MainActor
public final class WMFWikiRunViewModel: ObservableObject {

    public enum SnapshotSaveResult {
        case saved
        case invalidSnapshot
        case failed
    }

    /// Whether the game is loading, loaded or could not load, so the host can offer a way out
    /// of a blank screen.
    public enum LoadState {
        case loading
        case loaded
        case failed
    }

    public struct LocalizedStrings {
        public let errorTitle: String
        public let errorMessage: String
        public let retryButton: String
        public let closeButton: String

        public init(errorTitle: String, errorMessage: String, retryButton: String, closeButton: String) {
            self.errorTitle = errorTitle
            self.errorMessage = errorMessage
            self.retryButton = retryButton
            self.closeButton = closeButton
        }
    }

    /// The game URL, with the embed query parameter applied.
    public let gameURL: URL

    /// Set by the presenter: opens a Wikipedia article over the game, so back returns to it.
    public var onOpenArticle: (@MainActor @Sendable (URL) -> Void)?

    /// Set by the presenter: shares the game's result with the system share sheet.
    public var onShare: (@MainActor @Sendable (_ text: String?, _ url: URL?) -> Void)?

    /// Set by the presenter: dismisses the game.
    public var onClose: (@MainActor @Sendable () -> Void)?

    public let localizedStrings = LocalizedStrings(
        errorTitle: WMFLocalizedString("wikirun-error-title", value: "Something went wrong", comment: "Title shown when the WikiRun game cannot load."),
        errorMessage: WMFLocalizedString("wikirun-error-message", value: "The game could not load. Check your connection and try again.", comment: "Message shown when the WikiRun game cannot load."),
        retryButton: CommonStrings.retryActionTitle,
        closeButton: WMFLocalizedString("wikirun-error-close-button", value: "Close", comment: "Button that closes the WikiRun game from its error state.")
    )

    /// The app theme the game should follow.
    @Published public private(set) var isDarkMode: Bool

    /// Whether the game loaded or failed, so the host can offer a way out of a blank screen.
    @Published public private(set) var loadState: LoadState = .loading

    /// Changes when the game should be loaded again, after a failure.
    @Published public private(set) var reloadToken = 0

    /// The snapshot layout this host understands.
    private static let snapshotVersion = 1

    private let dataController: WMFWikiRunDataController

    public init(baseURL: URL, dataController: WMFWikiRunDataController = WMFWikiRunDataController.shared) {
        self.gameURL = Self.embedURL(from: baseURL)
        self.dataController = dataController
        self.isDarkMode = WMFAppEnvironment.current.theme.userInterfaceStyle == .dark
    }

    /// Re-reads the app theme after `WMFAppEnvironment` changes, so the game can follow it.
    public func updateTheme() {
        isDarkMode = WMFAppEnvironment.current.theme.userInterfaceStyle == .dark
    }

    // MARK: - Loading

    func didFinishLoading() {
        loadState = .loaded
    }

    /// Called when the game could not load or its web content process ended, so the game is gone
    /// from the screen.
    func didFailToLoad() {
        loadState = .failed
    }

    /// Loads the game again from its URL, replacing the error state.
    public func retryLoading() {
        loadState = .loading
        reloadToken += 1
    }

    // MARK: - Bridge

    func loadSnapshot() async -> WMFWikiRunDataController.WMFWikiRunSnapshot? {
        try? await dataController.loadSnapshot()
    }

    func saveSnapshot(version: Int?, values: [String: String]?) async -> SnapshotSaveResult {
        guard let version, version == Self.snapshotVersion, let values else {
            return .invalidSnapshot
        }

        do {
            try await dataController.saveSnapshot(.init(version: version, values: values))
            return .saved
        } catch {
            return .failed
        }
    }

    func openLink(_ url: URL) {
        UIApplication.shared.open(url)
    }

    func openArticle(_ url: URL) {
        if let onOpenArticle {
            onOpenArticle(url)
        } else {
            UIApplication.shared.open(url)
        }
    }

    func share(text: String?, url: URL?) {
        onShare?(text, url)
    }

    func close() {
        onClose?()
    }

    // MARK: - URL

    private static func embedURL(from baseURL: URL) -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return baseURL
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "embed" }
        queryItems.append(URLQueryItem(name: "embed", value: "1"))
        components.queryItems = queryItems
        return components.url ?? baseURL
    }
}
