import Foundation

@objc(WMFGlobalPreferencesController)
class GlobalPreferencesController: NSObject {
    @objc public init(dataStore: MWKDataStore, session: Session, configuration: Configuration) {
        self.dataStore = dataStore
        self.session = session
        self.configuration = configuration
        super.init()
        self.updateFetchers()
        NotificationCenter.default.addObserver(self, selector: #selector(preferredLanguagesDidChange(_:)), name: NSNotification.Name.WMFPreferredLanguagesDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func get(preference: String, for wikiLanguage: String) -> String? {
        assert(Thread.isMainThread)
        guard let moc = dataStore?.viewContext else {
            return nil
        }
        if let override = moc.wmf_stringValue(forKey: "gp:\(wikiLanguage):\(preference)") {
            return override
        }
        if let global = moc.wmf_stringValue(forKey: "gp:global:\(preference)") {
            return global
        }
        return nil
    }
    
    func signature(for wikiLanguage: String) -> String? {
        return get(preference: "nickname", for: wikiLanguage)
    }
    
    func treatSignatureAsWikitext(for wikiLanguage: String) -> Bool {
        return get(preference: "fancysig", for: wikiLanguage) == "1"
    }
    
    func set(signature: String?, for wikiLanguage: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        assert(Thread.isMainThread)
        guard let moc = dataStore?.viewContext else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        set(optionName: "nickname", to: signature, for: wikiLanguage, in: moc, completion: completion)
    }
    
    func set(treatSignatureAsWikitext: Bool, for wikiLanguage: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        assert(Thread.isMainThread)
        guard let moc = dataStore?.viewContext else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        set(optionName: "fancysig", to: treatSignatureAsWikitext ? "1" : nil, for: wikiLanguage, in: moc, completion: completion)
    }

    @objc public func preferredLanguagesDidChange(_ note: Notification) {
        updateFetchers()
    }
    
    // MARK - Private
    
    private var isWorking = false
    private var semaphore = DispatchSemaphore(value: 1)
    private weak var dataStore: MWKDataStore? = nil
    private var fetchers: [String: GlobalPreferencesFetcher] = [:]
    private let session: Session
    private let configuration: Configuration
    
    private func updateFetchers() {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        fetchers.removeAll()
        let languages = MWKLanguageLinkController.sharedInstance().preferredLanguages.map { $0.languageCode }
        for language in languages {
            fetchers[language] = GlobalPreferencesFetcher(session: session, configuration: configuration, wikiLanguage: language)
        }
    }
    
    private func set(optionName: String, to optionValue: String?, for wikiLanguage: String, in moc: NSManagedObjectContext, completion: @escaping (Result<Bool, Error>) -> Void) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        guard let fetcher = fetchers[wikiLanguage] else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        let localKey = "gp:" + wikiLanguage + ":" + optionName
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
        defer{
            semaphore.signal()
        }
        guard !isWorking else {
            completion(.success(false))
            return
        }
        isWorking = true
        let combinedCompletion: (Result<Bool, Error>) -> Void = { result in
            self.semaphore.wait()
            self.isWorking = false
            self.semaphore.signal()
            completion(result)
        }
        fetchers.asyncMap({ (kv, individualCompletion: @escaping (Result<Bool, Error>) -> Void) in
            kv.value.get { (result) in
                switch result {
                case .success(let prefs):
                    guard let dataStore = self.dataStore else {
                        individualCompletion(.failure(RequestError.invalidParameters))
                        return
                    }
                    DispatchQueue.main.async {
                        dataStore.performBackgroundCoreDataOperation(onATemporaryContext: { (moc) in
                            individualCompletion(.success(self.importPreferences(prefs: prefs, for:kv.key, intoManagedObjectContext: moc)))
                        })
                    }
                case .failure(let error):
                    DDLogError("Error fetching preferences: \(error)")
                    individualCompletion(.failure(error))
                }
            }
        }, completion: { (results) in
            var newData = false
            for result in results {
                switch result {
                case .failure:
                    combinedCompletion(result)
                    return
                case .success(let individualNewData):
                    if (individualNewData) {
                        newData = true
                    }
                }
            }
            combinedCompletion(.success(newData))
        })
        
    }
    
    private let preferenceKeysToImport: Set<String> = ["fancysig", "nickname"]
    
    private func importPreferences(prefs: [String: Any], with prefix: String, intoManagedObjectContext moc: NSManagedObjectContext) -> Bool {
        do {
            let existingPrefsFetchRequest: NSFetchRequest<WMFKeyValue> = WMFKeyValue.fetchRequest()
            existingPrefsFetchRequest.predicate = NSPredicate(format: "key BEGINSWITH %@", prefix)
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
                let localKey = prefix + key
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
    
    private func importPreferences(prefs: [String: Any], for wikiLanguage: String, intoManagedObjectContext moc: NSManagedObjectContext) -> Bool {
        var newData = false
        if let globalPrefs = prefs["preferences"] as? [String: Any] {
            let newGlobal = importPreferences(prefs: globalPrefs, with: "gp:global:", intoManagedObjectContext: moc)
            if newGlobal {
                newData = true
            }
        }
        if let localoverrides = prefs["localoverrides"] as? [String: Any] {
            let prefix = "gp:" + wikiLanguage + ":"
            let newLocal = importPreferences(prefs: localoverrides, with: prefix, intoManagedObjectContext: moc)
            if newLocal {
                newData = true
            }
        }
        return newData
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
