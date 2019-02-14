import Foundation

extension NSManagedObject {
    public func hasChangedValuesForCurrentEventForKeys(_ keys: Set<String>) -> Bool {
        let changedKeys = Set<String>(changedValuesForCurrentEvent().keys)
        return !changedKeys.intersection(keys).isEmpty
    }
}
