
import Foundation

enum TalkPageCreateError: Error {
    case TalkPageEntityCreationFailure
    case TalkPageDiscussionEntityCreationFailure
    case TalkPageDiscussionItemEntityCreationFailure
    case TalkPageDatabaseKeyCreationFailure
}

extension NSManagedObjectContext {
    public func wmf_createOrUpdateTalkPage(talkPage: NetworkTalkPage) throws -> TalkPage {
        
        guard let databaseKey = talkPage.url.wmf_talkPageDatabaseKey else {
            throw TalkPageCreateError.TalkPageDatabaseKeyCreationFailure
        }
        
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        fetchRequest.predicate = NSPredicate(format: "key == %@", databaseKey)
        
        guard let existingTalkPage = try fetch(fetchRequest).first else {
            
            //insert new talk page
            let newTalkPage = try createTalkPage(talkPage: talkPage)
            try self.save()
            return newTalkPage
        }
        
        guard existingTalkPage.revisionId < talkPage.revisionId else {
            return existingTalkPage
        }
        
        //update old talk page
        existingTalkPage.name = talkPage.name
        existingTalkPage.revisionId = talkPage.revisionId
        let newDiscussions = try createTalkPageDiscussions(talkPage: talkPage)
        
        //first delete old discussions
        //todo: is there a better way to do this? simply reassigning discussions is not enough
        if let discussions = existingTalkPage.discussions {
            for discussion in discussions {
                if let managedDiscussion = discussion as? NSManagedObject {
                    delete(managedDiscussion)
                }
            }
        }
        
        existingTalkPage.discussions = NSOrderedSet(array: newDiscussions)
        
        try self.save()
        return existingTalkPage
    }
    
    private func createTalkPage(talkPage networkTalkPage: NetworkTalkPage) throws -> TalkPage {
        
        guard let talkPageEntityDesc = NSEntityDescription.entity(forEntityName: "TalkPage", in: self) else {
            throw TalkPageCreateError.TalkPageEntityCreationFailure
        }
        
        let talkPage = TalkPage(entity: talkPageEntityDesc, insertInto: self)
        talkPage.key = networkTalkPage.url.wmf_talkPageDatabaseKey
        talkPage.name = networkTalkPage.name
        talkPage.revisionId = networkTalkPage.revisionId
        
        let discussions = try createTalkPageDiscussions(talkPage: networkTalkPage)
        talkPage.discussions = NSOrderedSet(array: discussions)
        
        return talkPage
    }
    
    private func createTalkPageDiscussions(talkPage networkTalkPage: NetworkTalkPage) throws -> [TalkPageDiscussion] {
        
        var discussions: [TalkPageDiscussion] = []
        for networkDiscussion in networkTalkPage.discussions {
            
            guard let entityDesc = NSEntityDescription.entity(forEntityName: "TalkPageDiscussion", in: self) else {
                throw TalkPageCreateError.TalkPageDiscussionEntityCreationFailure
            }
            
            let discussion = TalkPageDiscussion(entity: entityDesc, insertInto: self)
            discussion.title = networkDiscussion.title
            
            for networkItem in networkDiscussion.items {
                
                guard let entityDesc = NSEntityDescription.entity(forEntityName: "TalkPageDiscussionItem", in: self) else {
                    throw TalkPageCreateError.TalkPageDiscussionItemEntityCreationFailure
                }
                
                let discussionItem = TalkPageDiscussionItem(entity: entityDesc, insertInto: self)
                discussionItem.depth = networkItem.depth
                discussionItem.text = networkItem.text
                discussionItem.unalteredText = networkItem.unalteredText
                discussionItem.discussion = discussion
            }
            
            discussions.append(discussion)
        }
        
        return discussions
    }
}

