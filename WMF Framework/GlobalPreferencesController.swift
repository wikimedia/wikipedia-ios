import Foundation

@objc(WMFGlobalPreferencesController)
class GlobalPreferencesController: NSObject {
    @objc public init(dataStore: MWKDataStore, session: Session, configuration: Configuration) {
        fetcher = GlobalPreferencesFetcher(session: session, configuration: configuration)
        self.dataStore = dataStore
        super.init()
    }
    
    var signature: String? {
        assert(Thread.isMainThread)
        return dataStore?.viewContext.wmf_stringValue(forKey: "gp:nickname")
    }
    
    var treatSignatureAsWikitext: Bool {
        assert(Thread.isMainThread)
        return dataStore?.viewContext.wmf_stringValue(forKey: "gp:fancysig") == "1"
    }
    
    func set(signature: String?, completion: @escaping (Result<Bool, Error>) -> Void) {
        assert(Thread.isMainThread)
        guard let moc = dataStore?.viewContext else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        set(optionName: "nickname", to: signature, in: moc, completion: completion)
    }
    
    func set(treatSignatureAsWikitext: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        assert(Thread.isMainThread)
        guard let moc = dataStore?.viewContext else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        set(optionName: "fancysig", to: treatSignatureAsWikitext ? "1" : nil, in: moc, completion: completion)
    }

    // MARK - Private
    
    private var isWorking = false
    private var semaphore = DispatchSemaphore(value: 1)
    private weak var dataStore: MWKDataStore? = nil
    private let fetcher: GlobalPreferencesFetcher

    private func set(optionName: String, to optionValue: String?, in moc: NSManagedObjectContext, completion: @escaping (Result<Bool, Error>) -> Void) {
        let localKey = "gp:" + optionName
        let oldValue = moc.wmf_stringValue(forKey: localKey)
        moc.wmf_setValue(optionValue as NSString?, forKey: localKey)
        fetcher.set(optionName: optionName, to: optionValue) { (result) in
            switch result {
            case .failure:
                moc.perform {
                    moc.wmf_setValue(oldValue as NSString?, forKey: localKey)
                }
            case .success:
                break
            }
            completion(result)
        }
    }
    
    private func update(_ completion: @escaping (Result<Bool, Error>) -> Void) {
        semaphore.wait()
        guard !isWorking else {
            completion(.success(false))
            return
        }
        isWorking = true
        semaphore.signal()
        let combinedCompletion: (Result<Bool, Error>) -> Void = { result in
            self.semaphore.wait()
            self.isWorking = false
            self.semaphore.signal()
            completion(result)
        }
        fetcher.get { (result) in
            switch result {
            case .success(let prefs):
                guard let dataStore = self.dataStore else {
                    combinedCompletion(.failure(RequestError.invalidParameters))
                    return
                }
                DispatchQueue.main.async {
                    dataStore.performBackgroundCoreDataOperation(onATemporaryContext: { (moc) in
                        combinedCompletion(.success(self.importPreferences(prefs: prefs, intoManagedObjectContext: moc)))
                    })
                }
            case .failure(let error):
                DDLogError("Error fetching preferences: \(error)")
                combinedCompletion(.failure(error))
            }
        }
    }
    
    private let preferenceKeysToImport: Set<String> = ["fancysig", "nickname"]
    
    private func importPreferences(prefs: [String: Any], intoManagedObjectContext moc: NSManagedObjectContext) -> Bool {
        do {
            let existingPrefsFetchRequest: NSFetchRequest<WMFKeyValue> = WMFKeyValue.fetchRequest()
            existingPrefsFetchRequest.predicate = NSPredicate(format: "key BEGINSWITH %@", "gp:")
            let existingPrefs = try moc.fetch(existingPrefsFetchRequest)
            var existingPrefsByKey = [String: WMFKeyValue]()
            existingPrefsByKey.reserveCapacity(existingPrefs.count)
            for existingPref in existingPrefs {
                guard
                    let key = existingPref.key,
                    existingPrefsByKey[key] == nil
                else {
                    moc.delete(existingPref)
                    continue
                }
                existingPrefsByKey[key] = existingPref
            }
            for key in preferenceKeysToImport {
                let localKey = "gp:" + key
                let existingPref = existingPrefsByKey[localKey]
                existingPrefsByKey.removeValue(forKey: localKey) // remove so we can delete whatever is left in existingPrefsByKey
                let serverValue = prefs[key] as? String
                let pref = existingPref ?? WMFKeyValue(context: moc)
                if localKey != pref.key {
                    pref.key = localKey
                }
                if serverValue != pref.stringValue {
                    pref.stringValue = serverValue
                }
            }
            for (_, prefToDelete) in existingPrefsByKey {
                moc.delete(prefToDelete)
            }
            guard moc.hasChanges else {
                return false
            }
            try moc.save()
            return true
        } catch let error {
            DDLogError("Error importing preferences: \(error)")
            return false
        }
    }
}

extension GlobalPreferencesController: PeriodicWorker {
    func doPeriodicWork(_ completion: @escaping () -> Void) {
        update { _ in
            completion()
        }
    }
}

extension GlobalPreferencesController: BackgroundFetcher {
    func performBackgroundFetch(_ completion: @escaping (UIBackgroundFetchResult) -> Void) {
        update { result in
            switch result {
            case .success(let newData):
                completion(newData ? .newData : .noData)
            case .failure:
                completion(.failed)
            }
        }
    }
}
