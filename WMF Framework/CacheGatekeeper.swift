
import Foundation

final class CacheGatekeeper {


    //Used when adding or removing the same itemKey rapidly. Individual item completion block is queued here until item is determined complete in CacheController. Note this complete can come from another groupKey. Queued completions are then called and cleaned out.
    private let threadSafeItemQueue = DispatchQueue(label: "org.wikimedia.cache.itemGatekeeperQueue", attributes: .concurrent)
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
    
    //Used when adding or removing the same groupKey rapidly. Completion block is queued here until group is determined complete in CacheController. Queued completions are then called and cleaned out.
    private let threadSafeGroupQueue = DispatchQueue(label: "org.wikimedia.cache.groupGatekeeperQueue", attributes: .concurrent)
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
    
    //Used when adding THEN removing (or vice versa) the same group key rapidly. Completion blocks are queued here until an add or remove completes. Queued completions are then called and cleaned out.
    private let threadSafeCombinedQueue = DispatchQueue(label: "org.wikimedia.cache.combinedGatekeeperQueue", attributes: .concurrent)
    private var _queuedAddsWhileWaitingOnRemoves: [CacheController.GroupKey: [() -> Void]] = [:]
    private var queuedAddsWhileWaitingOnRemoves: [CacheController.GroupKey: [() -> Void]] {
        get {
            return threadSafeCombinedQueue.sync {
                return _queuedAddsWhileWaitingOnRemoves
            }
        }
        set {
            threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
                self?._queuedAddsWhileWaitingOnRemoves = newValue
            }
        }
    }
    
    private var _queuedRemovesWhileWaitingOnAdds: [CacheController.GroupKey: [() -> Void]] = [:]
    private var queuedRemovesWhileWaitingOnAdds: [CacheController.GroupKey: [() -> Void]] {
       get {
           return threadSafeCombinedQueue.sync {
               return _queuedRemovesWhileWaitingOnAdds
           }
       }
       set {
           threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
               self?._queuedRemovesWhileWaitingOnAdds = newValue
           }
       }
   }
    
    private var _currentlyAdding: [CacheController.GroupKey] = []
    private var currentlyAdding: [CacheController.GroupKey] {
        get {
            return threadSafeCombinedQueue.sync {
                return _currentlyAdding
            }
        }
        set {
            threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
                self?._currentlyAdding = newValue
            }
        }
    }
    
    private var _currentlyRemoving: [CacheController.GroupKey] = []
    private var currentlyRemoving: [CacheController.GroupKey] {
         get {
             return threadSafeCombinedQueue.sync {
                 return _currentlyRemoving
             }
         }
         set {
             threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
                 self?._currentlyRemoving = newValue
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
    
    func addCurrentlyAddingGroupKey(_ groupKey: CacheController.GroupKey) {
        threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }
            
            self._currentlyAdding.append(groupKey)
        }
    }
    
    func addCurrentlyRemovingGroupKey(_ groupKey: CacheController.GroupKey) {
        threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }
            
            self._currentlyRemoving.append(groupKey)
        }
    }
    
    func removeCurrentlyAddingGroupKey(_ groupKey: CacheController.GroupKey) {
        
        let filteredCurrentlyAdding = self.currentlyAdding.filter { $0 != groupKey }
        
        threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }
            
            
            self._currentlyAdding = filteredCurrentlyAdding
        }
    }
    
    func removeCurrentlyRemovingGroupKey(_ groupKey: CacheController.GroupKey) {
        
        let filteredCurrentlyRemoving = self.currentlyRemoving.filter { $0 != groupKey }
        
        threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }
            
            
            self._currentlyRemoving = filteredCurrentlyRemoving
        }
    }
    
    func shouldQueueAddCompletion(groupKey: CacheController.GroupKey) -> Bool {
        return currentlyAdding.contains(groupKey)
    }
    
    func shouldQueueRemoveCompletion(groupKey: CacheController.GroupKey) -> Bool {
        return currentlyRemoving.contains(groupKey)
    }
    
    func queueAddCompletion(groupKey: CacheController.GroupKey, completion: @escaping () -> Void) {
        
        var currentCompletions = self.queuedAddsWhileWaitingOnRemoves[groupKey] ?? []
        currentCompletions.append(completion)
        
        threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
            
            self?._queuedAddsWhileWaitingOnRemoves[groupKey] = currentCompletions
        }
    }
    
    func queueRemoveCompletion(groupKey: CacheController.GroupKey, completion: @escaping () -> Void) {
        
        var currentCompletions = self.queuedRemovesWhileWaitingOnAdds[groupKey] ?? []
        currentCompletions.append(completion)
        
        threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
            
            self?._queuedRemovesWhileWaitingOnAdds[groupKey] = currentCompletions
        }
    }
    
    func runAndRemoveQueuedRemoves(groupKey: CacheController.GroupKey) {
        
        if let completions = self.queuedRemovesWhileWaitingOnAdds[groupKey] {
            for completion in completions {
                completion()
            }
        }
        
        threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
        
            guard let self = self else {
                return
            }
            
            self._queuedRemovesWhileWaitingOnAdds[groupKey]?.removeAll()
        }
    }
    
    func runAndRemoveQueuedAdds(groupKey: CacheController.GroupKey) {
        
        if let completions = self.queuedAddsWhileWaitingOnRemoves[groupKey] {
            for completion in completions {
                completion()
            }
        }
        
        threadSafeCombinedQueue.async(flags: .barrier) { [weak self] in
        
            guard let self = self else {
                return
            }
            
            self._queuedAddsWhileWaitingOnRemoves[groupKey]?.removeAll()
        }
    }
}
