import Foundation

final class CacheGatekeeper {

    private let queue = DispatchQueue(label: "org.wikimedia.cache.gatekeeper")
    
    // Used when adding or removing the same uniqueKey rapidly. Individual completion block is queued here until uniqueKey is determined complete in CacheController. Note this complete can come from another groupKey. Queued completions are then called and cleaned out.
    private var individualCompletions: [CacheController.UniqueKey: [CacheController.IndividualCompletionBlock]] = [:]
    
    // Used when adding or removing the same groupKey rapidly. Completion block is queued here until group is determined complete in CacheController. Queued completions are then called and cleaned out.
    private var groupCompletions: [CacheController.GroupKey: [CacheController.GroupCompletionBlock]] = [:]
    
    // Used when adding THEN removing (or vice versa) the same group key rapidly. Completion blocks are queued here until an add or remove completes. Queued completions are then called and cleaned out.
    private var queuedAddsWhileWaitingOnRemoves: [CacheController.GroupKey: [() -> Void]] = [:]
    private var queuedRemovesWhileWaitingOnAdds: [CacheController.GroupKey: [() -> Void]] = [:]
    private var currentlyAdding: [CacheController.GroupKey] = []
    private var currentlyRemoving: [CacheController.GroupKey] = []
    
    func numberOfQueuedGroupCompletions(for groupKey: CacheController.GroupKey) -> Int {
        
        queue.sync {
            return groupCompletions[groupKey]?.count ?? 0
        }
    }
    
    func numberOfQueuedIndividualCompletions(for uniqueKey: CacheController.UniqueKey) -> Int {
        
        queue.sync {
            return individualCompletions[uniqueKey]?.count ?? 0
        }
        
    }
    
    func queueGroupCompletion(groupKey: CacheController.GroupKey, groupCompletion: @escaping CacheController.GroupCompletionBlock) {
        
        queue.async { [weak self] in
            
            guard let self = self else {
                return
            }
            
            var currentCompletions = self.groupCompletions[groupKey] ?? []
            currentCompletions.append(groupCompletion)
            
            self.groupCompletions[groupKey] = currentCompletions
        }
    }
    
    func queueIndividualCompletion(uniqueKey: CacheController.UniqueKey, individualCompletion: @escaping CacheController.IndividualCompletionBlock) {
        
        queue.async { [weak self] in
            
            guard let self = self else {
                return
            }
        
            var currentCompletions = self.individualCompletions[uniqueKey] ?? []
            currentCompletions.append(individualCompletion)
            
            self.individualCompletions[uniqueKey] = currentCompletions
        }
    }
    
    func runAndRemoveGroupCompletions(groupKey: CacheController.GroupKey, groupResult: CacheController.FinalGroupResult) {
        
        queue.async { [weak self] in
            
            guard let self = self else {
                return
            }
        
            if let completions = self.groupCompletions[groupKey] {
                for completion in completions {
                    completion(groupResult)
                }
            }
            
            self.groupCompletions[groupKey]?.removeAll()
        }
    }
    
    func runAndRemoveIndividualCompletions(uniqueKey: CacheController.UniqueKey, individualResult: CacheController.FinalIndividualResult) {
        
        queue.async { [weak self] in
            
            guard let self = self else {
                return
            }
            
            if let completions = self.individualCompletions[uniqueKey] {
                for completion in completions {
                    completion(individualResult)
                }
            }
            
            self.individualCompletions[uniqueKey]?.removeAll()
        }
    }
    
    func addCurrentlyAddingGroupKey(_ groupKey: CacheController.GroupKey) {
        
        queue.async { [weak self] in
            self?.currentlyAdding.append(groupKey)
        }
    }
    
    func addCurrentlyRemovingGroupKey(_ groupKey: CacheController.GroupKey) {
        
        queue.async { [weak self] in
            self?.currentlyRemoving.append(groupKey)
        }
    }
    
    func removeCurrentlyAddingGroupKey(_ groupKey: CacheController.GroupKey) {
        
        queue.async { [weak self] in
            
            guard let self = self else {
                return
            }
            
            let filteredCurrentlyAdding = self.currentlyAdding.filter { $0 != groupKey }
            self.currentlyAdding = filteredCurrentlyAdding
        }
    }
    
    func removeCurrentlyRemovingGroupKey(_ groupKey: CacheController.GroupKey) {
        
        queue.async { [weak self] in
            
            guard let self = self else {
                return
            }
            
            let filteredCurrentlyRemoving = self.currentlyRemoving.filter { $0 != groupKey }
            self.currentlyRemoving = filteredCurrentlyRemoving
        }
    }
    
    func shouldQueueAddCompletion(groupKey: CacheController.GroupKey) -> Bool {
        
        queue.sync {
            return currentlyRemoving.contains(groupKey)
        }
    }
    
    func shouldQueueRemoveCompletion(groupKey: CacheController.GroupKey) -> Bool {
        
        queue.sync {
            return currentlyAdding.contains(groupKey)
        }
    }
    
    func queueAddCompletion(groupKey: CacheController.GroupKey, completion: @escaping () -> Void) {
        
        queue.async { [weak self] in
         
            guard let self = self else {
                return
            }
            
            var currentCompletions = self.queuedAddsWhileWaitingOnRemoves[groupKey] ?? []
            currentCompletions.append(completion)
            self.queuedAddsWhileWaitingOnRemoves[groupKey] = currentCompletions
        }
    }
    
    func queueRemoveCompletion(groupKey: CacheController.GroupKey, completion: @escaping () -> Void) {
        
        queue.async { [weak self] in
        
           guard let self = self else {
               return
           }
            
            var currentCompletions = self.queuedRemovesWhileWaitingOnAdds[groupKey] ?? []
            currentCompletions.append(completion)
            self.queuedRemovesWhileWaitingOnAdds[groupKey] = currentCompletions
            
        }
    }
    
    func runAndRemoveQueuedRemoves(groupKey: CacheController.GroupKey) {
        
        queue.async { [weak self] in
            
            guard let self = self else {
                return
            }
            
            if let completion = self.queuedRemovesWhileWaitingOnAdds[groupKey]?.first {
                completion()
            }
            
            self.queuedRemovesWhileWaitingOnAdds[groupKey]?.removeAll()
        }
    }
    
    func runAndRemoveQueuedAdds(groupKey: CacheController.GroupKey) {
        
        queue.async { [weak self] in
         
            guard let self = self else {
                return
            }
            
            if let completion = self.queuedAddsWhileWaitingOnRemoves[groupKey]?.first {
                completion()
            }
            
            self.queuedAddsWhileWaitingOnRemoves[groupKey]?.removeAll()
        }
    }
}
