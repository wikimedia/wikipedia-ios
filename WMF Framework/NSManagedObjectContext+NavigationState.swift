import CoreData

public extension NSManagedObjectContext {
    var navigationState: NavigationState? {
        get {
            let keyValue = wmf_keyValue(forKey: NavigationState.libraryKey)
            guard let value = keyValue?.value as? Data else {
                return nil
            }
            let decoder = PropertyListDecoder()
            guard let navigationState = try? decoder.decode(NavigationState.self, from: value) else {
                return nil
            }
            return navigationState
        }
        
        set {
            let encoder = PropertyListEncoder()
            let value = try? encoder.encode(newValue) as NSData
            wmf_setValue(value, forKey: NavigationState.libraryKey)
        }
    }
    
    @objc(wmf_openArticleURL)
    var openArticleURL: URL? {
        guard let key = navigationState?.viewControllers.last(where: { (vc) -> Bool in
            return vc.info?.articleKey != nil
        })?.info?.articleKey else {
            return nil
        }
        return URL(string: key)
    }
}
