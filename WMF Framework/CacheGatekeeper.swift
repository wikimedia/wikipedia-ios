
import Foundation

final class CacheGatekeeper {

    private let threadSafeItemQueue = DispatchQueue(label: "org.wikimedia.cache.itemGatekeeperQueue", attributes: .concurrent)
    private let threadSafeGroupQueue = DispatchQueue(label: "org.wikimedia.cache.groupGatekeeperQueue", attributes: .concurrent)
    
    private var _itemCompletions: [CacheController.ItemKey: [CacheController.ItemCompletionBlock]] = [:]
    private var itemCompletions: [CacheController.ItemKey: [CacheController.ItemCompletionBlock]] {
        get {
            return threadSafeItemQueue.sync {
                return _itemCompletions
            }
        }
        set {
            threadSafeItemQueue.async(flags: .barrier) { [weak self] in
                self?._itemCompletions = newValue
            }
        }
    }
    
    private var _groupCompletions: [CacheController.GroupKey: [CacheController.GroupCompletionBlock]] = [:]
    private var groupCompletions: [CacheController.ItemKey: [CacheController.GroupCompletionBlock]] {
        get {
            return threadSafeGroupQueue.sync {
                return _groupCompletions
            }
        }
        set {
            threadSafeGroupQueue.async(flags: .barrier) { [weak self] in
                self?._groupCompletions = newValue
            }
        }
    }
    
    func numberOfQueuedGroupCompletions(for groupKey: CacheController.GroupKey) -> Int {
        return groupCompletions[groupKey]?.count ?? 0
    }
    
    func numberOfQueuedItemCompletions(for itemKey: CacheController.ItemKey) -> Int {
        return itemCompletions[itemKey]?.count ?? 0
    }
    
    func queueGroupCompletion(groupKey: CacheController.GroupKey, groupCompletion: @escaping CacheController.GroupCompletionBlock) {
        
        var currentCompletions = self.groupCompletions[groupKey] ?? []
        currentCompletions.append(groupCompletion)
        threadSafeGroupQueue.async(flags: .barrier) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self._groupCompletions[groupKey] = currentCompletions
        }
    }
    
    func queueItemCompletion(itemKey: CacheController.ItemKey, itemCompletion: @escaping CacheController.ItemCompletionBlock) {
        
        var currentCompletions = self.itemCompletions[itemKey] ?? []
        currentCompletions.append(itemCompletion)
        
        threadSafeItemQueue.async(flags: .barrier) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            self._itemCompletions[itemKey] = currentCompletions
        }
    }
    
    func runAndRemoveGroupCompletions(groupKey: CacheController.GroupKey, groupResult: CacheController.FinalGroupResult) {
        
        if let completions = groupCompletions[groupKey] {
            for completion in completions {
                completion(groupResult)
            }
        }
        
        threadSafeGroupQueue.async(flags: .barrier) { [weak self] in
        
            guard let self = self else {
                return
            }
            
            self._groupCompletions[groupKey]?.removeAll()
        }
    }
    
    func runAndRemoveItemCompletions(itemKey: CacheController.ItemKey, itemResult: CacheController.FinalItemResult) {
        
        if let completions = itemCompletions[itemKey] {
            for completion in completions {
                completion(itemResult)
            }
        }
        
        threadSafeItemQueue.async(flags: .barrier) { [weak self] in
        
            guard let self = self else {
                return
            }
            
            self._itemCompletions[itemKey]?.removeAll()
        }
    }
}
