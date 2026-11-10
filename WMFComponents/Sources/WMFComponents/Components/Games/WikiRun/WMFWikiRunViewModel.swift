import Foundation
import SwiftUI
import UIKit
import WMFData

/// State and behaviour for the WikiRun web game hosted in a WebView.
@MainActor
public final class WMFWikiRunViewModel: ObservableObject {

    public enum SnapshotSaveResult {
        case saved
        case invalidSnapshot
        case failed
    }

    /// The game URL, with the embed query parameter applied.
    public let gameURL: URL

    /// Set by the presenter: opens a Wikipedia article over the game, so back returns to it.
    public var onOpenArticle: ((URL) -> Void)?

    /// Set by the presenter: shares the game's result with the system share sheet.
    public var onShare: ((_ text: String?, _ url: URL?) -> Void)?

    /// Set by the presenter: dismisses the game.
    public var onClose: (() -> Void)?

    /// The app theme the game should follow.
    @Published public private(set) var isDarkMode: Bool

    /// The snapshot layout this host understands.
    private static let snapshotVersion = 1

    private let dataController: WMFWikiRunDataController

    public init(baseURL: URL, dataController: WMFWikiRunDataController = WMFWikiRunDataController()) {
        self.gameURL = Self.embedURL(from: baseURL)
        self.dataController = dataController
        self.isDarkMode = WMFAppEnvironment.current.theme.userInterfaceStyle == .dark
    }

    /// Re-reads the app theme after `WMFAppEnvironment` changes, so the game can follow it.
    public func updateTheme() {
        isDarkMode = WMFAppEnvironment.current.theme.userInterfaceStyle == .dark
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
