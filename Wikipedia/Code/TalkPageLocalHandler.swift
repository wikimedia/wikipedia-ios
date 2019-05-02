
import Foundation

class TalkPageLocalHandler {
    
    var dataStore: MWKDataStore
    
    required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }
    
    func existingTalkPage(for taskURL: URL) throws -> TalkPage? {
        
        guard let databaseKey = taskURL.wmf_talkPageDatabaseKey else {
            throw TalkPageError.talkPageDatabaseKeyCreationFailure
        }
        
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "key == %@", databaseKey)
        
        return try dataStore.viewContext.fetch(fetchRequest).first
    }
    
    func updateExistingTalkPage(existingTalkPage: TalkPage, with networkTalkPage: NetworkTalkPage) -> TalkPage? {
        existingTalkPage.revisionId = networkTalkPage.revisionId
        
        guard let newDiscussions: [TalkPageDiscussion] = createTalkPageDiscussions(with: networkTalkPage) else {
            return nil
        }
        
        //first delete old discussions
        //todo: is there a better way to do this? simply reassigning discussions is not enough
        if let discussions = existingTalkPage.discussions {
            for discussion in discussions {
                if let managedDiscussion = discussion as? NSManagedObject {
                    dataStore.viewContext.delete(managedDiscussion)
                }
            }
        }
        
        existingTalkPage.discussions = NSOrderedSet(array: newDiscussions)
        try? dataStore.viewContext.save() //todo: no try?
        return existingTalkPage
    }
    
    func createTalkPage(with networkTalkPage: NetworkTalkPage) -> TalkPage? {
        
        guard let talkPageEntityDesc = NSEntityDescription.entity(forEntityName: "TalkPage", in: dataStore.viewContext) else {
            return nil
        }
        
        let talkPage = TalkPage(entity: talkPageEntityDesc, insertInto: dataStore.viewContext)
        talkPage.key = networkTalkPage.url.wmf_talkPageDatabaseKey
        talkPage.revisionId = networkTalkPage.revisionId
        talkPage.languageCode = networkTalkPage.languageCode
        talkPage.displayTitle = networkTalkPage.displayTitle
        
        guard let discussions = createTalkPageDiscussions(with: networkTalkPage) else {
            return nil
        }
        
        talkPage.discussions = NSOrderedSet(array: discussions)
        try? dataStore.viewContext.save() //todo: no try?
        return talkPage
    }
    
    private func createTalkPageDiscussions(with networkTalkPage: NetworkTalkPage) -> [TalkPageDiscussion]? {
        
        var discussions: [TalkPageDiscussion] = []
        for networkDiscussion in networkTalkPage.discussions {
            
            guard let entityDesc = NSEntityDescription.entity(forEntityName: "TalkPageDiscussion", in: dataStore.viewContext) else {
                return nil
            }
            
            let discussion = TalkPageDiscussion(entity: entityDesc, insertInto: dataStore.viewContext)
            discussion.title = networkDiscussion.text
            
            for networkItem in networkDiscussion.items {
                
                guard let entityDesc = NSEntityDescription.entity(forEntityName: "TalkPageDiscussionItem", in: dataStore.viewContext) else {
                    return nil
                }
                
                let discussionItem = TalkPageDiscussionItem(entity: entityDesc, insertInto: dataStore.viewContext)
                discussionItem.depth = networkItem.depth
                discussionItem.text = networkItem.text
                discussionItem.discussion = discussion
            }
            
            discussions.append(discussion)
        }
        
        return discussions
    }
}
