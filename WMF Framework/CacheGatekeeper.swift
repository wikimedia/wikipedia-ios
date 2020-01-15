
import Foundation

final class CacheGatekeeper {
    
    struct CompletionQueueItem {
        let groupKey: GroupKey
        let completion: CompletionQueueBlock
    }
    
    typealias ItemKey = String
    typealias GroupKey = String
    
    private let internalThreadSafeCompletionItemQueue = DispatchQueue(label: "org.wikimedia.cache.internalCompletionQueue", attributes: .concurrent)
    private let externalThreadSafeCompletionBlockQueue = DispatchQueue(label: "org.wikimedia.cache.externalCompletionQueue", attributes: .concurrent)
    
    private var _internalQueuedCompletionItems: [ItemKey: [CompletionQueueItem]] = [:]
    private var internalQueuedCompletionItems: [ItemKey: [CompletionQueueItem]] {
        get {
            return internalThreadSafeCompletionItemQueue.sync {
                return _internalQueuedCompletionItems
            }
        }
        set {
            internalThreadSafeCompletionItemQueue.async(flags: .barrier) { [weak self] in
                self?._internalQueuedCompletionItems = newValue
            }
        }
    }
    
    private var _externalQueuedCompletionBlocks: [GroupKey: [CompletionQueueBlock]] = [:]
    private var externalQueuedCompletionBlocks: [GroupKey: [CompletionQueueBlock]] {
           get {
               return externalThreadSafeCompletionBlockQueue.sync {
                   return _externalQueuedCompletionBlocks
               }
           }
           set {
               externalThreadSafeCompletionBlockQueue.async(flags: .barrier) { [weak self] in
                   self?._externalQueuedCompletionBlocks = newValue
               }
           }
       }
    
    //internal
    func removeQueuedCompletionItems(with groupKey: String) {
        for (key, value) in internalQueuedCompletionItems {
            let newItems = value.filter { $0.groupKey == groupKey }
            setQueuedCompletionItems(itemKey: key, completionItems: newItems)
        }
    }
    
    func runAndCleanOutQueuedCompletionItems(result: CacheResult, itemKey: String) {
        if let queuedCompletionItems = internalQueuedCompletionItems[itemKey] {
            for queuedCompletionItem in queuedCompletionItems {
                queuedCompletionItem.completion(result)
            }
        }
        
        cleanOutQueuedCompletionItems(itemKey: itemKey)
    }
    
    func shouldQueue(groupKey: String, itemKey: String) -> Bool {
        let isEmpty = internalQueuedCompletionItems[itemKey]?.isEmpty ?? true
        return !isEmpty
    }
    
    func internalQueue(groupKey: String, itemKey: String, completionBlockToQueue: @escaping CompletionQueueBlock) {
        
        let completionQueueItem = CompletionQueueItem(groupKey: groupKey, completion: completionBlockToQueue)
        appendCompletionItem(itemKey: itemKey, completionItem: completionQueueItem)
    }
    
    //external
    func externalQueue(groupKey: String, completionBlockToQueue: @escaping CompletionQueueBlock) {
        appendCompletionBlock(groupKey: groupKey, completionBlock: completionBlockToQueue)
    }
    
    func externalRunAndCleanOutQueuedCompletionBlock(groupKey: String, cacheResult: CacheResult) {
        if let queuedCompletionBlocks = externalQueuedCompletionBlocks[groupKey] {
            for queuedCompletionBlock in queuedCompletionBlocks {
                queuedCompletionBlock(cacheResult)
            }
        }
        
        removeQueuedCompletionBlock(groupKey: groupKey)
    }
    
    func externalRemoveQueuedCompletionBlock(groupKey: String) {
        removeQueuedCompletionItems(with: groupKey)
    }
    
    //internal
    private func appendCompletionItem(itemKey: String, completionItem: CompletionQueueItem) {
        internalThreadSafeCompletionItemQueue.async(flags: .barrier) { [weak self] in
            self?._internalQueuedCompletionItems[itemKey]?.append(completionItem)
        }
    }
    
    private func setQueuedCompletionItems(itemKey: String, completionItems: [CompletionQueueItem]) {
        internalThreadSafeCompletionItemQueue.async(flags: .barrier) { [weak self] in
            self?._internalQueuedCompletionItems[itemKey] = completionItems
        }
    }
    
    private func cleanOutQueuedCompletionItems(itemKey: String) {
        internalThreadSafeCompletionItemQueue.async(flags: .barrier) { [weak self] in
            self?._internalQueuedCompletionItems[itemKey]?.removeAll()
        }
    }
    
    //external
    private func appendCompletionBlock(groupKey: String, completionBlock: @escaping CompletionQueueBlock) {
        externalThreadSafeCompletionBlockQueue.async(flags: .barrier) { [weak self] in
            self?._externalQueuedCompletionBlocks[groupKey]?.append(completionBlock)
        }
    }
    
    private func removeQueuedCompletionBlock(groupKey: String) {
        externalThreadSafeCompletionBlockQueue.async(flags: .barrier) { [weak self] in
            self?._externalQueuedCompletionBlocks[groupKey]?.removeAll()
        }
    }
}
