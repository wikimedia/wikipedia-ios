
import Foundation

final class CacheGatekeeper {
    
    struct CompletionQueueItem {
        let groupKey: GroupKey
        let completion: CompletionQueueBlock
    }
    
    typealias CompletionQueueBlock = (_ result: CacheResult) -> Void
    typealias ItemKey = String
    typealias GroupKey = String
    
    private let threadSafeCompletionItemQueue = DispatchQueue(label: "org.wikimedia.cache.gatekeeper", attributes: .concurrent)
    
    private var _queuedCompletionItems: [ItemKey: [CompletionQueueItem]] = [:]
    
    private var queuedCompletionItems: [ItemKey: [CompletionQueueItem]] {
        get {
            return threadSafeCompletionItemQueue.sync {
                return _queuedCompletionItems
            }
        }
        set {
            threadSafeCompletionItemQueue.async(flags: .barrier) { [weak self] in
                self?._queuedCompletionItems = newValue
            }
        }
    }
    
    func removeQueuedCompletionItems(with groupKey: String) {
        for (key, value) in queuedCompletionItems {
            let newItems = value.filter { $0.groupKey == groupKey }
            setQueuedCompletionItems(itemKey: key, completionItems: newItems)
        }
    }
    
    func runAndCleanOutQueuedCompletionItems(result: CacheResult, itemKey: String) {
        if let queuedCompletionItems = queuedCompletionItems[itemKey] {
            for queuedCompletionItem in queuedCompletionItems {
                queuedCompletionItem.completion(result)
            }
        }
        
        cleanOutQueuedCompletionItems(itemKey: itemKey)
    }
    
    func shouldQueue(groupKey: String, itemKey: String) -> Bool {
        let isEmpty = queuedCompletionItems[itemKey]?.isEmpty ?? true
        return !isEmpty
    }
    
    func queue(groupKey: String, itemKey: String, completionBlockToQueue: @escaping CompletionQueueBlock) {
        
        let completionQueueItem = CompletionQueueItem(groupKey: groupKey, completion: completionBlockToQueue)
        queuedCompletionItems[itemKey]?.append(completionQueueItem)
    }
    
    private func appendCompletionItem(itemKey: String, completionItem: CompletionQueueItem) {
        threadSafeCompletionItemQueue.async(flags: .barrier) { [weak self] in
            self?._queuedCompletionItems[itemKey]?.append(completionItem)
        }
    }
    
    private func setQueuedCompletionItems(itemKey: String, completionItems: [CompletionQueueItem]) {
        threadSafeCompletionItemQueue.async(flags: .barrier) { [weak self] in
            
            self?._queuedCompletionItems[itemKey] = completionItems
        }
    }
    
    private func cleanOutQueuedCompletionItems(itemKey: String) {
        threadSafeCompletionItemQueue.async(flags: .barrier) { [weak self] in
            self?._queuedCompletionItems[itemKey]?.removeAll()
        }
    }
}
