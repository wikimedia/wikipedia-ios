import Foundation

/// Persists the WikiRun web game's progress snapshot in the shared app-group cache, so the game
/// resumes across launches and the same state stays readable from other app processes.
public actor WMFWikiRunDataController {

    public static let shared = WMFWikiRunDataController()

    public struct WMFWikiRunSnapshot: Codable, Sendable, Equatable {
        public let version: Int
        public let values: [String: String]

        public init(version: Int, values: [String: String]) {
            self.version = version
            self.values = values
        }
    }

    public enum CustomError: Error {
        case unavailableStore
    }

    private static let fileName = "state"

    private let injectedSharedCacheStore: WMFKeyValueStore?

    private var sharedCacheStore: WMFKeyValueStore? {
        injectedSharedCacheStore ?? WMFDataEnvironment.current.sharedCacheStore
    }

    public init(sharedCacheStore: WMFKeyValueStore? = nil) {
        self.injectedSharedCacheStore = sharedCacheStore
    }

    /// Whether the WikiRun prototype entry point should be offered. Read synchronously from the
    /// developer setting so UI can gate itself during layout.
    public static var isWikiRunAvailable: Bool {
        WMFDeveloperSettingsDataController.shared.enableWikiRunPrototype
    }

    public func loadSnapshot() throws -> WMFWikiRunSnapshot? {
        guard let sharedCacheStore else { return nil }
        return try sharedCacheStore.load(key: WMFSharedCacheDirectoryNames.wikiRun.rawValue, Self.fileName)
    }

    public func saveSnapshot(_ snapshot: WMFWikiRunSnapshot) throws {
        guard let sharedCacheStore else { throw CustomError.unavailableStore }
        try sharedCacheStore.save(key: WMFSharedCacheDirectoryNames.wikiRun.rawValue, Self.fileName, value: snapshot)
    }

    public func clearSnapshot() throws {
        guard let sharedCacheStore else { return }
        try sharedCacheStore.remove(key: WMFSharedCacheDirectoryNames.wikiRun.rawValue, Self.fileName)
    }
}
