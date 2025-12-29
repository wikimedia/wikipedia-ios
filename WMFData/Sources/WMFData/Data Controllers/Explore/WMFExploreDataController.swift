import Foundation

public actor WMFExploreDataController {

    private let userDefaultsStore: WMFKeyValueStore?
    
    public init(userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore) {
        self.userDefaultsStore = userDefaultsStore
    }
    
    public var hasSeenExploreSurvey: Bool {
        get async {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.hasSeenExploreSurvey.rawValue)) ?? false
        }
    }
    
    public func setHasSeenExploreSurvey(_ value: Bool) async {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.hasSeenExploreSurvey.rawValue, value: value)
    }
}

// MARK: - Sync Bridge Extension

extension WMFExploreDataController {
    
    nonisolated public var hasSeenExploreSurveySyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.hasSeenExploreSurvey
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    nonisolated public func setHasSeenExploreSurveySyncBridge(_ value: Bool) {
        Task {
            await self.setHasSeenExploreSurvey(value)
        }
    }
}
